#!/bin/bash
set -euo pipefail

echo "=== PW Scaffold: Post-Create Setup ==="

# Named volumes may be root-owned on first attach — fix before writing caches
for dir in /ms-playwright-cli /home/pwuser/.npm /workspace/node_modules; do
    if [ -d "$dir" ]; then
        sudo chown -R pwuser:pwuser "$dir" 2>/dev/null || true
    fi
done

# 1. Install npm dependencies
echo "[1/5] Installing npm dependencies..."
npm ci --prefer-offline

# 2. Link CLI tools into ~/.local/bin
echo "[2/5] Linking CLI tools..."
bash scripts/link-cli.sh "$(pwd -P)"

echo "[2b/5] playwright-cli browsers (isolated cache, does not touch /ms-playwright)..."
bash scripts/install-playwright-cli-browsers.sh "$(pwd -P)"

# 3. Create env file if it doesn't exist
if [ ! -f env/.env.dev ]; then
    echo "[3/5] Creating env/.env.dev from example..."
    cp env/.env.example env/.env.dev
else
    echo "[3/5] env/.env.dev already exists, skipping."
fi

# 4. Create .auth directory (used by storage state setup)
echo "[4/5] Ensuring .auth directory exists..."
mkdir -p .auth/app

# 5. Verify tools are available
echo "[5/5] Verifying tools..."
echo "  Node.js:     $(node --version)"
echo "  npm:         $(npm --version)"
if command -v playwright &> /dev/null; then
    echo "  Playwright:  $(playwright --version)"
    echo "  playwright:  $(which playwright)"
else
    echo "  Playwright:  NOT FOUND (warning)"
fi
if command -v playwright-cli &> /dev/null; then
    echo "  playwright-cli: $(playwright-cli --version)"
    echo "  playwright-cli: $(which playwright-cli)"
else
    echo "  playwright-cli: NOT FOUND (warning)"
fi
if command -v claude &> /dev/null; then
    echo "  Claude Code: $(which claude)"
else
    echo "  Claude Code: NOT FOUND (warning)"
fi
if command -v gh &> /dev/null; then
    echo "  GitHub CLI:  $(gh --version | head -1)"
else
    echo "  GitHub CLI:  NOT FOUND (warning)"
fi

echo ""
echo "=== Setup complete! ==="
echo "  Run 'npm test' to execute tests"
echo "  Run 'playwright-cli --version' to verify Playwright CLI"
echo ""
