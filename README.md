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

Copy and paste the following blocks directly into your Termux terminal.

### 1. Setup GLIBC Repository & Prerequisites
We need to enable the GLIBC repository, update the package indexes, and install the required build tools.

```bash
# Enable GLIBC repository and update indexes
pkg install glibc-repo -y
pkg update -y

# Install all required compiler tools and dependencies
pkg install git curl clang make glibc-repo python glibc-runner-y
pkg install proot -y
```

### 2. Install Bun & Apply Native Wrapper
Since Bun is compiled for standard Linux (`glibc`) and not Android's `bionic libc`, we install Bun and compile a lightweight system-call translation shim.

```bash
# Clone and compile the native Termux compatibility wrapper
git clone https://github.com/Happ1ness-dev/bun-termux.git
cd bun-termux
make && make install

# Reload profile configuration
source ~/.bashrc

# Verify Bun installation
bun --version
```

### 3. Configure Environment Variables
Add Bun and local binaries to your shell profile path so they can be executed globally.

```bash
# Append variables to bash profile
echo 'export BUN_INSTALL="\$HOME/.bun"' >> ~/.bashrc
echo 'export PATH="\$BUN_INSTALL/bin:HOME/.local/bin:PATH"' >> ~/.bashrc
echo 'export TMPDIR="$PREFIX/tmp"' >> ~/.bashrc
echo 'export TEMP="$PREFIX/tmp"' >> ~/.bashrc
echo 'export TMP="$PREFIX/tmp"' >> ~/.bashrc
echo -e '\n# termux-chroot\nif [ -z "$TERMUX_CHROOT_ACTIVE" ]; then\n    export TERMUX_CHROOT_ACTIVE=1\n    exec termux-chroot\nfi' >> ~/.bashrc
source ~/.bashrc

# Reload profile configurations
source ~/.bashrc

# Verify Bun installation
bun --version
```

### 4. Install OpenRouter Spawn CLI
Now that Bun is globally accessible, the OpenRouter installer will execute successfully.

```bash
# Run the official installer
curl -fsSL https://openrouter.ai/labs/spawn/cli/install.sh | bash

# Verify Spawn installation
spawn --help
```

---

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
If some third-party build scripts or global packages inside Termux fail because they specifically look for a `node` binary, you can safely symlink your native Bun installation to act as Node:
```bash
ln -s HOME/.bun/bin/bun HOME/.bun/bin/node
```

## Credits
* Wrapper logic powered by [bun-termux](https://github.com/Happ1ness-dev/bun-termux).
* CLI workspace management powered by [OpenRouter Spawn](https://openrouter.ai/spawn).
