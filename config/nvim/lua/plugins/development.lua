return {
  {
    "imsnif/kdl.vim",
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
      servers = { nil_ls = { mason = false, enable = false } },
    },
  },

  { "mason-org/mason-lspconfig.nvim", version = "^1.0.0" },
  {
    "mason-org/mason.nvim",
    version = "^1.0.0",
    opts = {
      -- servers = {
      --   nil_ls = {
      --     mason = false,
      --     enable = false,
      --   },
      -- },
      ensure_installed = {
        "angular-language-server",
        "bash-language-server",
        "clangd",
        "cmakelang",
        "cmakelint",
        "codelldb",
        "docker-compose-language-service",
        "dockerfile-language-server",
        "eslint-lsp",
        "gofumpt",
        "goimports",
        "gopls",
        "hadolint",
        "jdtls",
        "json-lsp",
        "lua-language-server",
        "markdown-toc",
        "markdownlint-cli2",
        "marksman",
        "neocmakelsp",
        "prettier",
        "pyright",
        "ruff",
        "shellcheck",
        "shfmt",
        "stylua",
        "tailwindcss-language-server",
        "terraform-ls",
        "tflint",
        "vtsls",
        "vue-language-server",
        "yaml-language-server",
        -- "pyright",
        -- "clangd",
        -- "stylua",
        -- "selene",
        -- "luacheck",
        -- "shellcheck",
        -- "shfmt",
        -- "tailwindcss-language-server",
        -- "typescript-language-server",
        -- "css-lsp",
      },
    },
  },

  { "nvim-treesitter/nvim-treesitter-textobjects" },

  {
    "saghen/blink.cmp",
    enabled = false,
    opts = {
      sources = {
        -- Make zortex links show up first in .zortex buffers
        default = { "zortex" },
        providers = {
          zortex = {
            name = "Zortex Links",
            module = "zortex.blink_source", -- <- points at the file in the canvas
            opts = {}, -- (none for now)
          },
        },
      },
    },
  },
  { "saghen/blink.compat", enabled = false },

  {
    "nvim-treesitter/nvim-treesitter",
    enabled = true,
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "cmake",
        "cpp",
        "css",
        "diff",
        "gitignore",
        "go",
        "html",
        "http",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "make",
        "markdown",
        "markdown_inline",
        "ninja",
        "php",
        "printf",
        "python",
        "r",
        "regex",
        "rst",
        "rust",
        "sql",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },
      highlight = {
        enable = true,
        -- Disable treesitter for noice buffers to prevent "end_row" crashes
        disable = function(lang, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
          -- Specific fix for your crash:
          local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
          if filetype == "noice" or filetype == "vim" then
            -- Only disable if it's a floating window (like noice cmdline)
            if vim.api.nvim_win_get_config(0).relative ~= "" then
              return true
            end
          end
        end,
      },
    },
  },
}
