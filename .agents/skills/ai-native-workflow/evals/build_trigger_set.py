#!/usr/bin/env python3
"""Convert evals.json (behavioral eval set) to the trigger-rate format the
vendored skill-creator harness executes.

Two instruments, one source of truth:
  - evals.json is the BEHAVIORAL spec (prompt + assertions) — graded by a
    human or an agent walking the assertions.
  - run_eval.py / run_loop.py (skill-creator) execute TRIGGER evals:
    [{"query": ..., "should_trigger": bool}] — does the skill fire on the
    prompt at all?

This script derives the trigger set from evals.json so the two can't drift:
every behavioral prompt becomes a should_trigger=True query, EXCEPT the
Direct-Mode evals (trivial one-line fixes — the Constitution says those may
skip the router). A few static negative queries guard against the router
triggering on conversation that isn't a scaffold task.

Usage:
  python3 build_trigger_set.py > /tmp/trigger-evals.json
"""

import json
import os
import sys

# Eval ids whose correct behavior is Direct Mode (router NOT loaded).
DIRECT_MODE_IDS = {6, 7}

NEGATIVE_QUERIES = [
    "What's the difference between interface and type in TypeScript?",
    "Explain how HTTP status code 418 came to exist.",
    "What did we change in the previous session?",
]


def main() -> int:
    here = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(here, "evals.json"), encoding="utf-8") as f:
        behavioral = json.load(f)

    items = []
    for e in behavioral["evals"]:
        items.append(
            {
                "query": e["prompt"],
                "should_trigger": e["id"] not in DIRECT_MODE_IDS,
                "source_eval": e["name"],
            }
        )
    for q in NEGATIVE_QUERIES:
        items.append({"query": q, "should_trigger": False, "source_eval": "static-negative"})

    json.dump(items, sys.stdout, indent=2)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
