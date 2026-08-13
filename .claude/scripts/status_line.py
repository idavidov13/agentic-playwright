#!/usr/bin/env python3
"""Claude Code status line — Gruvbox Dark theme.

Single class, one responsibility per method. Reads JSON from stdin,
renders a rich status bar with git, PR, model, cost, and context info.
"""

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional


def _ansi(r: int, g: int, b: int) -> str:
    return f"\033[38;2;{r};{g};{b}m"


RESET = "\033[0m"

# Gruvbox Dark palette
COLOR_MODEL = _ansi(86, 182, 194)     # #56B6C2  bright teal
COLOR_DIR = _ansi(152, 195, 121)      # #98C379  soft green
COLOR_GIT = _ansi(143, 175, 209)      # #8FAFD1  soft blue
COLOR_DURATION = _ansi(211, 134, 155) # #D3869B  soft purple
COLOR_COST = _ansi(224, 175, 104)     # #E0AF68  warm yellow
COLOR_ADDED = _ansi(142, 192, 124)    # #8EC07C  green
COLOR_REMOVED = _ansi(251, 73, 52)    # #FB4934  red
COLOR_BRACKET = _ansi(102, 92, 84)    # #665C54  gruvbox gray
COLOR_PCT = _ansi(251, 241, 199)      # #FBF1C7  bright foreground
COLOR_SEPARATOR = _ansi(102, 92, 84)  # #665C54  gruvbox gray
COLOR_DIRTY = _ansi(251, 73, 52)      # #FB4934  red dot
COLOR_CAVEMAN = _ansi(215, 135, 0)    # #D78700  orange (matches caveman plugin)

# Context bar gradient
COLOR_BAR_GREEN = _ansi(142, 192, 124)   # #8EC07C
COLOR_BAR_YELLOW = _ansi(224, 175, 104)  # #E0AF68
COLOR_BAR_ORANGE = _ansi(254, 128, 25)   # #FE8019
COLOR_BAR_RED = _ansi(251, 73, 52)       # #FB4934
COLOR_BAR_EMPTY = _ansi(50, 48, 47)      # #32302F

PR_CACHE_DIR = Path("/tmp")
PR_CACHE_TTL = 60


class ClaudeStatusLine:
    """Renders a rich status line for Claude Code terminal."""

    CAVEMAN_FLAG = Path.home() / ".claude" / ".caveman-active"
    CAVEMAN_VALID_MODES = frozenset({
        "lite", "full", "ultra", "wenyan-lite", "wenyan", "wenyan-full", "wenyan-ultra",
    })

    AUTOCOMPACT_REMAINING = 16.5
    AUTOCOMPACT_THRESHOLD = 100.0 - AUTOCOMPACT_REMAINING  # ~83.5%
    BAR_SEGMENTS = 20

    def __init__(self, data: dict) -> None:
        self._data = data
        self._cwd: str = data.get("workspace", {}).get("current_dir", "")

    # ------------------------------------------------------------------
    # Segment methods — each returns a formatted string or ""
    # ------------------------------------------------------------------

    def caveman_mode(self) -> str:
        """Show caveman mode badge if active."""
        try:
            flag = self.CAVEMAN_FLAG
            if flag.is_symlink() or not flag.is_file():
                return ""
            mode = flag.read_text()[:64].strip().lower()
            if mode not in self.CAVEMAN_VALID_MODES:
                return ""
            return f"{COLOR_CAVEMAN}🪨 CAVEMAN-{mode.upper()}{RESET}"
        except Exception:
            return ""

    def git_branch(self) -> str:
        """Read .git/HEAD directly (lock-safe) + dirty dot via git status."""
        if not self._cwd:
            return ""
        try:
            branch = self._read_git_head()
            if not branch:
                return ""
            dirty = self._is_dirty()
            dot = f" {COLOR_DIRTY}●{RESET}" if dirty else ""
            return f"{COLOR_GIT}✦ {branch}{RESET}{dot}"
        except Exception:
            return ""

    def pr_status(self) -> str:
        """Run gh pr view, map review state to emoji, OSC 8 clickable link."""
        if not self._cwd:
            return ""
        try:
            branch = self._read_git_head()
            if not branch:
                return ""
            pr_info = self._get_pr_info(branch)
            if not pr_info:
                return ""
            state = pr_info.get("reviewDecision", "")
            number = pr_info.get("number", "")
            url = pr_info.get("url", "")
            emoji = self._review_emoji(state)
            if not number:
                return ""
            link_text = f"#{number}"
            if url:
                link_text = f"\033]8;;{url}\033\\#{number}\033]8;;\033\\"
            return f"{emoji} {link_text}"
        except Exception:
            return ""

    def directory(self) -> str:
        """Extract workspace directory from JSON input."""
        if not self._cwd:
            return ""
        try:
            name = Path(self._cwd).name
            return f"{COLOR_DIR}📁 {name}{RESET}"
        except Exception:
            return ""

    def model_name(self) -> str:
        """Extract model display name from JSON input."""
        try:
            name = self._data.get("model", {}).get("display_name", "")
            if not name:
                return ""
            return f"{COLOR_MODEL}🤖 {name}{RESET}"
        except Exception:
            return ""

    def duration(self) -> str:
        """Format cost.total_duration_ms as Xm Ys."""
        try:
            ms = self._data.get("cost", {}).get("total_duration_ms", 0)
            if not ms:
                return ""
            total_s = int(ms) // 1000
            minutes = total_s // 60
            seconds = total_s % 60
            if minutes > 0:
                return f"{COLOR_DURATION}⏳ {minutes}m{seconds:02d}s{RESET}"
            return f"{COLOR_DURATION}⏳ {seconds}s{RESET}"
        except Exception:
            return ""

    def cost(self) -> str:
        """Format cost.total_cost_usd as $X.XX."""
        try:
            usd = self._data.get("cost", {}).get("total_cost_usd", 0)
            if not usd and usd != 0:
                return ""
            value = float(usd)
            if value == 0:
                return ""
            return f"{COLOR_COST}💰 ${value:.2f}{RESET}"
        except Exception:
            return ""

    def lines_changed(self) -> str:
        """Format lines added/removed with green/red coloring."""
        try:
            cost_data = self._data.get("cost", {})
            added = int(cost_data.get("total_lines_added", 0))
            removed = int(cost_data.get("total_lines_removed", 0))
            parts: list[str] = []
            if added:
                parts.append(f"{COLOR_ADDED}+ {added}{RESET}")
            if removed:
                parts.append(f"{COLOR_REMOVED}— {removed}{RESET}")
            return f" {COLOR_SEPARATOR}|{RESET} ".join(parts)
        except Exception:
            return ""

    def context_bar(self) -> str:
        """Render context usage bar scaled to autocompact threshold.

        100% bar = autocompact is imminent (~83.5% of context window used).
        Color transitions: green -> yellow -> orange -> red.
        """
        try:
            ctx = self._data.get("context_window", {})
            used_pct = float(ctx.get("used_percentage", 0))
            window_size = int(ctx.get("context_window_size", 0))
            if not window_size:
                return ""

            tokens_used = int(used_pct * window_size / 100)

            adjusted_pct = min(used_pct / self.AUTOCOMPACT_THRESHOLD * 100, 100.0)
            filled = round(adjusted_pct / 100.0 * self.BAR_SEGMENTS)

            bar = f"{COLOR_BRACKET}[{RESET}"
            for i in range(self.BAR_SEGMENTS):
                if i < filled:
                    segment_pct = (i + 1) / self.BAR_SEGMENTS * 100
                    color = self._bar_color(segment_pct)
                    bar += f"{color}█{RESET}"
                else:
                    bar += f"{COLOR_BAR_EMPTY}░{RESET}"
            bar += f"{COLOR_BRACKET}]{RESET}"

            tokens_fmt = self._format_tokens(tokens_used)
            window_fmt = self._format_tokens(window_size)

            return (
                f"{bar} {COLOR_PCT}{used_pct:.1f}%{RESET} "
                f"{COLOR_BRACKET}({RESET}{tokens_fmt}/{window_fmt}{COLOR_BRACKET}){RESET}"
            )
        except Exception:
            return ""

    # ------------------------------------------------------------------
    # Render
    # ------------------------------------------------------------------

    def render(self) -> str:
        """Collect all segments, filter empties, join with | separators."""
        segments = [
            self.caveman_mode(),
            self.git_branch(),
            self.pr_status(),
            self.directory(),
            self.model_name(),
            self.duration(),
            self.cost(),
            self.lines_changed(),
            self.context_bar(),
        ]
        separator = f" {COLOR_SEPARATOR}|{RESET} "
        return separator.join(s for s in segments if s)

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _read_git_head(self) -> str:
        """Read branch name from .git/HEAD directly (avoids lock conflicts)."""
        try:
            git_dir = self._find_git_dir()
            if not git_dir:
                return ""
            head_file = git_dir / "HEAD"
            if not head_file.is_file():
                return ""
            content = head_file.read_text().strip()
            if content.startswith("ref: refs/heads/"):
                return content[len("ref: refs/heads/"):]
            return content[:8]
        except Exception:
            try:
                result = subprocess.run(
                    ["git", "branch", "--show-current"],
                    capture_output=True, text=True, timeout=2,
                    cwd=self._cwd,
                )
                return result.stdout.strip()
            except Exception:
                return ""

    def _find_git_dir(self) -> Optional[Path]:
        """Walk up from cwd to find .git directory."""
        current = Path(self._cwd)
        for parent in [current, *current.parents]:
            git_path = parent / ".git"
            if git_path.is_dir():
                return git_path
            if git_path.is_file():
                text = git_path.read_text().strip()
                if text.startswith("gitdir: "):
                    return Path(text[len("gitdir: "):])
        return None

    def _is_dirty(self) -> bool:
        """Check working tree dirty state via git status --porcelain."""
        try:
            result = subprocess.run(
                ["git", "status", "--porcelain", "--no-optional-locks"],
                capture_output=True, text=True, timeout=3,
                cwd=self._cwd,
            )
            return bool(result.stdout.strip())
        except Exception:
            return False

    def _get_pr_info(self, branch: str) -> Optional[dict]:
        """Get PR info for branch, using a file-based cache with TTL."""
        safe_branch = re.sub(r"[^\w\-.]", "_", branch)
        cache_file = PR_CACHE_DIR / f"claude-pr-cache-{safe_branch}.json"

        try:
            if cache_file.is_file():
                age = time.time() - cache_file.stat().st_mtime
                if age < PR_CACHE_TTL:
                    cached = json.loads(cache_file.read_text())
                    return cached if cached.get("number") else None
        except Exception:
            pass

        try:
            result = subprocess.run(
                [
                    "gh", "pr", "view",
                    "--json", "number,url,reviewDecision,state",
                ],
                capture_output=True, text=True, timeout=5,
                cwd=self._cwd,
            )
            if result.returncode != 0:
                self._write_cache(cache_file, {})
                return None
            pr_data = json.loads(result.stdout)
            self._write_cache(cache_file, pr_data)
            return pr_data if pr_data.get("number") else None
        except Exception:
            return None

    @staticmethod
    def _write_cache(path: Path, data: dict) -> None:
        try:
            path.write_text(json.dumps(data))
        except Exception:
            pass

    @staticmethod
    def _review_emoji(state: str) -> str:
        mapping = {
            "APPROVED": "🟢",
            "CHANGES_REQUESTED": "🔴",
            "REVIEW_REQUIRED": "🟡",
        }
        return mapping.get(state, "🟡")

    @staticmethod
    def _bar_color(segment_pct: float) -> str:
        """Return ANSI color for a bar segment based on its position percentage."""
        if segment_pct <= 50:
            return COLOR_BAR_GREEN
        if segment_pct <= 70:
            return COLOR_BAR_YELLOW
        if segment_pct <= 85:
            return COLOR_BAR_ORANGE
        return COLOR_BAR_RED

    @staticmethod
    def _format_tokens(count: int) -> str:
        """Format token count as compact string: 45383 -> '45,383', 200000 -> '200k'."""
        if count >= 1000 and count % 1000 == 0:
            return f"{count // 1000}k"
        if count >= 1000:
            return f"{count:,}"
        return str(count)


def main() -> None:
    try:
        raw = sys.stdin.read()
        data = json.loads(raw) if raw.strip() else {}
    except Exception:
        data = {}

    status = ClaudeStatusLine(data)
    print(status.render())


if __name__ == "__main__":
    main()
