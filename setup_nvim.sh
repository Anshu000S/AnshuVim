#!/usr/bin/env bash
# ==============================================================================
# setup_nvim.sh - Portable Neovim Setup and Configuration Script
# ==============================================================================

set -e

# Terminal colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Neovim Setup...${NC}"

# ==============================================================================
# 1. OS Detection & Neovim Installation
# ==============================================================================
install_neovim() {
    # Check if a modern neovim version is already installed (>= 0.8.0)
    if command -v nvim &> /dev/null; then
        NVIM_VERSION=$(nvim --version | head -n 1 | grep -oP 'v\K[0-9]+\.[0-9]+')
        # Simple basic float comparison using awk
        if awk "BEGIN {exit !($NVIM_VERSION >= 0.8)}"; then
             echo -e "${GREEN}✓ Modern Neovim (>=0.8.0) is already installed. $(nvim --version | head -n 1)${NC}"
             return
        else
             echo -e "${YELLOW}Neovim is installed, but it is too old for Lazy.nvim. Upgrading...${NC}"
        fi
    fi

    echo -e "${YELLOW}Neovim (>=0.8.0) is not installed. Attempting to install the latest AppImage...${NC}"
    
    # Try AppImage first (works on almost all Linux distributions)
    if command -v curl &> /dev/null; then
        echo -e "${BLUE}Downloading Neovim AppImage...${NC}"
        curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage
        chmod u+x nvim-linux-x86_64.appimage
        # We put it in /usr/bin/nvim directly to overwrite any old apt installation references
        sudo mv nvim-linux-x86_64.appimage /usr/bin/nvim
        # Clear bash hash table so it finds the new executable
        hash -r 2>/dev/null || true
        echo -e "${GREEN}✓ Successfully installed modern Neovim.${NC}"
        return
    fi
    
    echo -e "\033[0;31mCould not install modern Neovim automatically via curl. Please install Neovim >= 0.8.0 manually.\033[0m"
    exit 1
}

install_neovim

# ==============================================================================
# 2. Configuration Backup
# ==============================================================================
NVIM_CONFIG_DIR="$HOME/.config/nvim"
if [ -d "$NVIM_CONFIG_DIR" ]; then
    BACKUP_DIR="${NVIM_CONFIG_DIR}.bak.$(date +%F_%T)"
    echo -e "${YELLOW}Existing Neovim configuration found. Backing up to $BACKUP_DIR...${NC}"
    mv "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
fi

echo -e "${BLUE}Creating Neovim configuration directories...${NC}"
mkdir -p "$NVIM_CONFIG_DIR/lua/config"
mkdir -p "$NVIM_CONFIG_DIR/lua/plugins"

# ==============================================================================
# 3. Create Configuration Files
# ==============================================================================
echo -e "${BLUE}Generating init.lua...${NC}"
cat << 'EOF' > "$NVIM_CONFIG_DIR/init.lua"
-- ==========================================================================
-- init.lua
-- This is your main configuration file for Neovim.
-- It is the first file loaded when Neovim starts, and it is responsible
-- for setting core options and importing other configuration files.
-- ==========================================================================

-- 1. Load the Plugin Manager (Lazy.nvim)
-- We do this early so plugins can be loaded and initialized.
require("config.lazy")

-- ==========================================================================
-- General Neovim Options
-- ==========================================================================

-- Enable line numbers on the left margin
vim.opt.number = true

-- Enable mouse support in all modes (normal, visual, insert, etc.)
vim.opt.mouse = "a"

-- System Clipboard Integration
-- This configuration uses osc52 to copy/paste text between Neovim 
-- and your operating system's clipboard, even over SSH.
vim.g.clipboard = 'osc52'

-- Uncomment the line below if you prefer standard clipboard support
-- vim.opt.clipboard = "unnamedplus"

-- ==========================================================================
-- Indentation & Tab Settings
-- ==========================================================================

-- Number of spaces that a <Tab> character represents
vim.opt.tabstop = 4      

-- Number of spaces to use for auto-indenting (e.g., when pressing '>>' or '<<')
vim.opt.shiftwidth = 4   

-- Convert TAB characters to simple spaces (highly recommended for coding)
vim.opt.expandtab = true 

-- ==========================================================================
-- Final Appearance Settings
-- ==========================================================================

-- Setting colorscheme safely. We wrap it in a pcall in case the colorscheme
-- hasn't been downloaded by Lazy.nvim upon the very first launch.
local status_ok, _ = pcall(vim.cmd, "colorscheme catppuccin")
if not status_ok then
  vim.notify("Colorscheme not found yet. It will be applied after plugins finish installing.", vim.log.levels.WARN)
end
EOF

echo -e "${BLUE}Generating lua/config/lazy.lua...${NC}"
cat << 'EOF' > "$NVIM_CONFIG_DIR/lua/config/lazy.lua"
-- ==========================================================================
-- lazy.lua
-- This file configures 'lazy.nvim', which is the plugin manager for Neovim.
-- It ensures lazy.nvim is downloaded if it's missing, and then it loads
-- all of your plugins from the lua/plugins/ directory.
-- ==========================================================================

-- 1. Automatically install lazy.nvim if it's not present
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

-- Add lazy.nvim to the runtime path so Neovim can use it
vim.opt.rtp:prepend(lazypath)

-- ==========================================================================
-- Key Mappings Setup
-- ==========================================================================

-- 2. Define the <Leader> key
-- The leader key is used as a prefix for custom shortcuts. Space is highly recommended.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- ==========================================================================
-- Plugin Loading
-- ==========================================================================

-- Ensure lazy.nvim is loaded successfully before proceeding
local status_ok, lazy = pcall(require, "lazy")
if not status_ok then
  vim.notify("Failed to load lazy.nvim", vim.log.levels.ERROR)
  return
end

-- 3. Configure and initialize lazy.nvim
lazy.setup({
  spec = {
    -- This imports plugins defined in lua/plugins/core_plugins.lua
    { import = "plugins.core_plugins" },
    -- Dynamically load linters if the file exists
    { import = "plugins.linters", cond = function() return pcall(require, "mason") end },
  },
  install = {
    -- Fallback colorschemes to use while installing plugins
    colorscheme = { "catppuccin", "habamax" },
  },
  checker = {
    -- Automatically check for plugin updates occasionally
    enabled = true,
  },
})
EOF

echo -e "${BLUE}Generating lua/plugins/core_plugins.lua...${NC}"
cat << 'EOF' > "$NVIM_CONFIG_DIR/lua/plugins/core_plugins.lua"
-- ==========================================================================
-- core_plugins.lua
-- This file defines the core plugins you use for Neovim.
-- Lazy.nvim will read this file and automatically download/configure them.
-- ==========================================================================

return {

  -- ========================================================================
  -- 1. Color Scheme: Catppuccin
  -- Provides a beautiful, dark, pastel-colored theme for Neovim.
  -- ========================================================================
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- Load this plugin first so the colorscheme is applied early
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- Options: latte, frappe, macchiato, mocha
        transparent_background = true, -- Set to false if you want a solid background
        integrations = {
          telescope  = true, -- Style Telescope cleanly
          treesitter = true, -- Syntax highlighting colors
        },
      })
      vim.cmd.colorscheme("catppuccin-nvim")
    end,
  },

  -- ========================================================================
  -- 2. Telescope: Fuzzy Finder
  -- Allows you to quickly search for files, live grep text, and find buffers.
  -- ========================================================================
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" }, -- Required dependency for Telescope
    config = function()
      require("telescope").setup {
        defaults = {
          mappings = {
            i = {
              -- Use Ctrl+N / Ctrl+P to navigate the search results list
              ["<C-n>"] = "move_selection_next",
              ["<C-p>"] = "move_selection_previous",
            },
          },
        },
      }

      -- Custom Keybindings for Telescope
      -- <C-p> to find files by name
      vim.api.nvim_set_keymap("n", "<C-p>", ":Telescope find_files<CR>", { noremap = true, silent = true })
      -- <C-f> to search for text inside files (live grep)
      vim.api.nvim_set_keymap("n", "<C-f>", ":Telescope live_grep<CR>", { noremap = true, silent = true })
      -- <C-b> to switch between currently open files (buffers)
      vim.api.nvim_set_keymap("n", "<C-b>", ":Telescope buffers<CR>", { noremap = true, silent = true })
    end,
  },

  -- ========================================================================
  -- 3. Lualine: Status Line
  -- Provides a powerful, customizable status line at the bottom of Neovim.
  -- ========================================================================
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- Icons for statusline
    config = function()
      require("lualine").setup({
        options = {
          theme = "catppuccin" -- Match the status line theme with Catppuccin
        }
      })
    end,
  },

  -- ========================================================================
  -- 4. Dashboard: Start Screen
  -- Displays a beautiful start screen with shortcuts when opening Neovim.
  -- ========================================================================
  {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('dashboard').setup({
        theme = 'doom',  -- 'doom' layout with centered text and big ASCII art
        config = {
          header = {
            "                              ",
            "                              ",
            "                              ",
            "                              ",
            "                              ",
            "                              ",
            "                              ",
            "⣿⣿⣿⣿⣿⣿⣿⠋⣴⡆⣷⡆⡀⠀⠀⠉⠛⣛⠟⢛⠛⡿⣿⣿⣏⡙⣿⣷⣿⣿",
            "⣻⡷⣺⠟⡖⠋⠉⠈⠩⠾⠟⠡⠃⠀⠀⠂⢀⣿⣀⠀⡄⠁⠀⠃⠋⠛⠾⣿⣿⣿",
            "⣫⣞⡏⢀⡇⠀⡀⡀⠀⠀⠀⢀⣠⣤⣔⣻⣷⠘⣿⡿⠿⣷⣶⣄⣀⡀⠀⠸⠻⣍",
            "⢯⠞⡁⢸⠃⢀⣾⣿⣷⣾⣿⡿⣫⢞⣭⣿⣿⣿⣶⣝⠶⢾⣿⣿⣄⣿⡆⠀⠀⢱",
            "⡿⣙⣀⠏⠀⣼⣿⣿⣿⣿⣿⡿⣫⠿⠛⣋⡍⣿⣿⣿⡇⠦⣵⣿⣓⣌⢿⣾⣦⡸",
            "⣿⣿⣏⡤⢸⣿⣿⡻⢿⡿⠋⢈⣴⠾⣚⣵⣿⣿⣿⣿⣷⠓⠶⣱⠋⢮⣺⡿⣿⡇",
            "⣿⣿⣟⡄⡏⣽⠛⠻⣶⢨⣳⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⢸⡅⡏⣶⢠⣿⣧⣿⣷",
            "⣿⣿⣿⡇⡅⠄⣚⣃⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠈⠃⡿⢙⡼⡈⣿⢏⣿",
            "⣿⣿⣿⣿⣷⣷⢻⢹⣿⣿⣿⣿⣿⣿⣿⠿⡻⣠⣿⣿⣿⣦⠀⠊⠉⡙⣦⡞⣸⣿",
            "⣿⣿⣿⣿⣿⣿⣇⣝⣻⣿⣿⠿⠛⢭⣊⣥⣾⣿⣿⣿⣿⣿⠀⠀⢰⣷⣶⣰⣿⣿",
            "⣿⣿⣿⣿⣿⣿⣿⣎⢿⣥⠶⢞⣛⣽⣿⣿⣿⣿⣿⣿⢟⣵⢀⠀⢸⣿⣿⡇⣿⣿",
            "⣿⣿⣿⣿⣿⣿⣿⣿⣯⢻⣿⣿⣿⣿⣿⣿⣿⣿⠟⢡⣾⡟⣬⣴⣾⣿⣿⣷⢿⣿",
            "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣻⣿⣿⣿⣿⠿⠋⢁⣴⣿⢏⢸⣿⣿⣿⣿⣿⣿⣸⣿",
            "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣭⣭⣭⢡⣀⣴⣿⣿⢯⣾⢸⣿⣿⣿⣿⣿⣿⣿⣿",
            "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢘⣻⠿⣟⣵⣿⢃⣿⣿⣿⣿⣿⣿⣿⣿⣿",
            "                              ",
            "                              ",
            "                              ",
            "                              ",
            "                              ",
          },
          center = {
            {
              icon = '  ',
              desc = 'Recent files',
              action = 'Telescope oldfiles',
              key = 'r',
            },
            {
              icon = '  ',
              desc = 'Find file',
              action = 'Telescope find_files',
              key = 'f',
            },
            {
              icon = '  ',
              desc = 'Open file tree',
              action = 'NvimTreeToggle',
              key = 'e',
            },
            {
              icon = '  ',
              desc = 'Edit config',
              action = 'edit ~/.config/nvim/init.lua',
              key = 'c',
            },
            {
              icon = '  ',
              desc = 'Quit',
              action = 'q',
              key = 'q',
            },
          },
          footer = { "🗡️ Zoro says: Nothing happened." }
        }
      })
    end
  },

  -- End of Plugins List
}
EOF

# ==============================================================================
# 4. Linter Setup based on Language
# ==============================================================================
echo -e "\n${YELLOW}=== Language Linter Setup ===${NC}"
LINTERS=()
LSP_SERVERS=()

read -p "Do you want to install linters/LSP for TS/JS? [y/N] " install_tsjs
if [[ "$install_tsjs" =~ ^[Yy]$ ]]; then
    LINTERS+=("eslint_d")
    LSP_SERVERS+=("tsserver") # tsserver is the standard for Neovim LSP
fi

read -p "Do you want to install linters/LSP for Python? [y/N] " install_python
if [[ "$install_python" =~ ^[Yy]$ ]]; then
    LINTERS+=("flake8" "black")
    LSP_SERVERS+=("pyright")
fi

read -p "Do you want to install linters/LSP for C/C++? [y/N] " install_c
if [[ "$install_c" =~ ^[Yy]$ ]]; then
    LINTERS+=("cpplint")
    LSP_SERVERS+=("clangd")
fi

read -p "Do you want to install linters/LSP for Java? [y/N] " install_java
if [[ "$install_java" =~ ^[Yy]$ ]]; then
    LINTERS+=("checkstyle")
    LSP_SERVERS+=("jdtls")
fi

read -p "Do you want to install linters/LSP for Go? [y/N] " install_go
if [[ "$install_go" =~ ^[Yy]$ ]]; then
    LINTERS+=("golangci-lint")
    LSP_SERVERS+=("gopls")
fi

if [ ${#LINTERS[@]} -ne 0 ] || [ ${#LSP_SERVERS[@]} -ne 0 ]; then
    echo -e "${BLUE}Configuring Mason to handle requested linters...${NC}"
    
    # Format arrays for Lua
    LSP_LUA_STR=""
    for lsp in "${LSP_SERVERS[@]}"; do
        LSP_LUA_STR+="\"$lsp\", "
    done

    LINTER_LUA_STR=""
    for linter in "${LINTERS[@]}"; do
        LINTER_LUA_STR+="\"$linter\", "
    done
    
    # Create linters.lua plugin file
    cat << EOF > "$NVIM_CONFIG_DIR/lua/plugins/linters.lua"
-- ==========================================================================
-- linters.lua
-- Configures Mason, LSP, and Linters based on your selections.
-- ==========================================================================
return {
  -- Mason: Portable package manager for Neovim that installs LSP servers, DAP servers, linters, and formatters.
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  
  -- Bridges Mason with nvim-lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { ${LSP_LUA_STR} }
      })
      
      -- Setup each LSP server to attach to buffers
      local lspconfig = require("lspconfig")
      require("mason-lspconfig").setup_handlers({
        function(server_name)
          lspconfig[server_name].setup({})
        end,
      })
    end
  },

  -- Bridges Mason with none-ls (null-ls) for generic linters and formatters
  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "williamboman/mason.nvim",
      "jay-babu/mason-null-ls.nvim",
    },
    config = function()
      require("mason-null-ls").setup({
        ensure_installed = { ${LINTER_LUA_STR} },
        automatic_installation = true,
      })
      require("null-ls").setup()
    end,
  }
}
EOF
fi

echo -e "\n${GREEN}✓ Setup complete! You can now start Neovim by typing 'nvim'.${NC}"
echo -e "${YELLOW}Note: On first launch, Lazy.nvim will automatically clone and install all the configured plugins.${NC}"
