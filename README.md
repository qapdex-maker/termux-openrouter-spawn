```text
███████╗██████╗  █████╗ ██╗    ██╗███╗   ██╗  Beta
██╔════╝██╔══██╗██╔══██╗██║    ██║████╗  ██║
███████╗██████╔╝███████║██║ █╗ ██║██╔██╗ ██║
╚════██║██╔═══╝ ██╔══██║██║███╗██║██║╚██╗██║
███████║██║     ██║  ██║╚███╔███╔╝██║ ╚████║
╚══════╝╚═╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝
```

# 
This guide helps you install **Bun** natively inside **Termux** using a **GLIBC** compatibility layer, and sets up the **OpenRouter Spawn CLI** for running AI coding agents.

## Quick Installation

The steps below are codified in [`install.sh`](./install.sh) — a copy-paste-safe,
re-runnable installer that fixes the path-expansion and chroot pitfalls of the
earlier manual blocks.

```bash
# Clone and run (Termux only)
gh repo clone qapdex-maker/termux-openrouter-spawn
cd termux-openrouter-spawn
bash install.sh
```

## or just download the script
```
curl -fsSL https://raw.githubusercontent.com/qapdex-maker/termux-openrouter-spawn/main/install.sh | bash
```

What it does:
1. Enables the GLIBC repo and installs the toolchain (`glibc-repo`, `clang`,
   `proot`, ...).
2. Builds **Bun** via the native Termux compatibility wrapper
   ([bun-termux](https://github.com/Happ1ness-dev/bun-termux)) — Bun is built
   for glibc, not Android's bionic libc, so the shim is required.
3. Writes env vars to `~/.bashrc` with **correct `$PATH` expansion**
   (`$HOME/.local/bin:$PATH`)
   and gates `termux-chroot` to **interactive shells only** so non-interactive
   tools (cron, ssh, scripts) keep working.
4. Installs the **OpenRouter Spawn CLI** from the official installer.

Verify any time without changing anything:

```bash
bash install.sh --verify
```

## Usage & AI Agent Setup

To start with agentic workflows using models like `openrouter/owl-alpha`:

1. Export your OpenRouter API Key:
   ```bash
   export OPENROUTER_API_KEY="your_openrouter_api_key_here"
   ```
2. Spawn your agent workspace:
   ```bash
   spawn
   ```

## Troubleshooting

### Node.js Compatibility Fix
If some third-party build scripts or global packages inside Termux fail because
they specifically look for a `node` binary, the installer symlinks Bun to act
as Node automatically. To do it manually:
```bash
ln -s "$HOME/.bun/bin/bun" "$HOME/.bun/bin/node"
```

## Credits
* Wrapper logic powered by [bun-termux](https://github.com/Happ1ness-dev/bun-termux).
* CLI workspace management powered by [OpenRouter Spawn](https://openrouter.ai/spawn).
