<div align="center">

# ⚡ Neovim Portable Setup ⚡

A fully automated, zero-touch installation script to bootstrap a modern Neovim configuration on any Linux environment. 

[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io/)
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](https://www.lua.org/)
[![Bash](https://img.shields.io/badge/Bash-Script-4EAA25.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)]()

</div>

---

## ✨ Features

- **🚀 Automatic Neovim Setup**: Dynamically installs the latest `nvim` AppImage if your local system has an outdated version (Lazy.nvim requires `0.8.0+`).
- **🛡️ Safe & Non-Destructive**: Automatically detects and backs up your existing `~/.config/nvim` directory (e.g., to `nvim.bak.YYYY-MM-DD_HH:MM:SS`) to prevent data loss.
- **🎨 Beautiful Defaults**: Pre-configured with the stunning **Catppuccin Mocha** colorscheme and a sleek dashboard via **Dashboard-Nvim**.
- **🔌 Powered by Lazy.nvim**: Uses the modern, blazing-fast plugin manager `lazy.nvim` to handle everything.
- **🔭 Telescope Included**: Fuzzy finder ready to go (`<C-p>` for files, `<C-f>` for grep, `<C-b>` for buffers).
- **🛠️ Interactive Linter Setup**: Prompts you during installation to optionally configure and install Language Servers (LSPs), Formatters, and Linters using **Mason** for:
  - `TS/JS` (eslint_d, tsserver)
  - `Python` (flake8, black, pyright)
  - `C/C++` (cpplint, clangd)
  - `Java` (checkstyle, jdtls)
  - `Go` (golangci-lint, gopls)

---

## 🛠️ Installation

Simply download and execute the script. It is completely portable!

### 1. Make it executable

Ensure the script has permission to be run on your system after downloading or cloning it:

```bash
chmod +x setup_nvim.sh
```

### 2. Run the installer

```bash
bash setup_nvim.sh
```

Follow the interactive prompts to select which language environments you want to set up! 

---

## 📂 File Structure overview
The script generates the following clean structure in your `~/.config/nvim/` directory:

```text
~/.config/nvim/
├── init.lua                   # Main entry point, sets core vim options
├── lua/
│   ├── config/
│   │   └── lazy.lua           # Bootstraps the plugin manager
│   └── plugins/
│       ├── core_plugins.lua   # Catppuccin, Telescope, Lualine, Dashboard
│       └── linters.lua        # (Generated) Mason, nvim-lspconfig, null-ls configurations
```

### ⌨️ Default Keybindings mappings included out-of-the-box:

- `<Leader>` key mapped to `Space`
- `<C-p>` - Telescope Find Files
- `<C-f>` - Telescope Live Grep
- `<C-b>` - Telescope Buffers
- `<C-n>` / `<C-p>` - Move up/down inside telescope results

---

## 🤝 Contributing
Feel free to open issues or fork this repository to build your own personal setup scripts based off this robust template!
