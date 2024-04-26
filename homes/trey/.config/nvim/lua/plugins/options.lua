return {
  { import = "lazyvim.plugins.extras.linting.eslint" },
  { import = "lazyvim.plugins.extras.formatting.prettier" },
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.rust" },
  { import = "lazyvim.plugins.extras.lang.tailwind" },
  -- { import = "lazyvim.plugins.extras.coding.copilot" },
  -- { import = "lazyvim.plugins.extras.util.mini-hipatterns" },

  -- { "windwp/nvim-ts-autotag", enabled = false },
  { "folke/flash.nvim", enabled = false },
  {
    "echasnovski/mini.surround",
    keys = function(_, keys)
      -- Populate the keys based on the user's options
      local plugin = require("lazy.core.config").spec.plugins["mini.surround"]
      local opts = require("lazy.core.plugin").values(plugin, "opts", false)
      local mappings = {
        { opts.mappings.add, desc = "Add surrounding", mode = { "n", "v" } },
        { opts.mappings.delete, desc = "Delete surrounding" },
        { opts.mappings.find, desc = "Find right surrounding" },
        { opts.mappings.find_left, desc = "Find left surrounding" },
        { opts.mappings.highlight, desc = "Highlight surrounding" },
        { opts.mappings.replace, desc = "Replace surrounding" },
        { opts.mappings.update_n_lines, desc = "Update `MiniSurround.config.n_lines`" },
      }
      mappings = vim.tbl_filter(function(m)
        return m[1] and #m[1] > 0
      end, mappings)
      return vim.list_extend(mappings, keys)
    end,
    opts = {
      mappings = {
        add = "gsa", -- Add surrounding in Normal and Visual modes
        delete = "gsd", -- Delete surrounding
        find = "gsf", -- Find surrounding (to the right)
        find_left = "gsF", -- Find surrounding (to the left)
        highlight = "gsh", -- Highlight surrounding
        replace = "gsr", -- Replace surrounding
        update_n_lines = "gsn", -- Update `n_lines`
      },
    },
  },

  { "ben-grande/vim-qrexec" },

  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "pyright",
        "clangd",
        -- "stylua",
        -- "selene",
        -- "luacheck",
        -- "shellcheck",
        -- "shfmt",
        -- "tailwindcss-language-server",
        -- "typescript-language-server",
        -- "css-lsp",
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "kdl",
        "cmake",
        "c",
        "cpp",
        "css",
        "gitignore",
        "go",
        "http",
        "php",
        "rust",
        "sql",
        "python",
        "ninja",
        "rst",
        "toml",
        "typescript",
        "tsx",
        "javascript",
        "markdown",
      },
    },
  },

  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      opts.mapping["<CR>"] = nil
    end,
  },

  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        markdownlint = {
          args = { "--disable", "MD013", "--" },
        },
      },
    },
  },

  {
    "folke/noice.nvim",
    opts = function(_, opts)
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = { skip = true },
      })
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
      "nvim-lua/plenary.nvim",
    },

    -- stylua: ignore
    keys = {
      {
        "<leader>fP",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
      {
        "<leader>fp",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
			{
				"<leader>fP",
				function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root, }) end,
				desc = "Find Plugin File",
			},
			{
				"<leader>;f",
				function() local builtin = require("telescope.builtin") builtin.find_files({ no_ignore = false, hidden = true, }) end,
				desc = "Lists files in your current working directory, respects .gitignore",
			},
			{
				"<leader>;r",
				function() local builtin = require("telescope.builtin") builtin.live_grep({ additional_args = { "--hidden" }, }) end,
				desc = "Search for a string in your current working directory and get results live as you type, respects .gitignore",
			},
			{
				"<leader>\\\\",
				function() local builtin = require("telescope.builtin") builtin.buffers() end,
				desc = "Lists open buffers",
			},
			{
				"<leader>;t",
				function() local builtin = require("telescope.builtin") builtin.help_tags() end,
				desc = "Lists available help tags and opens a new window with the relevant help info on <cr>",
			},
			{
				"<leader>;;",
				function() local builtin = require("telescope.builtin") builtin.resume() end,
				desc = "Resume the previous telescope picker",
			},
			{
				"<leader>;e",
				function() local builtin = require("telescope.builtin") builtin.diagnostics() end,
				desc = "Lists Diagnostics for all open buffers or a specific buffer",
			},
			{
				"<leader>;s",
				function() local builtin = require("telescope.builtin") builtin.treesitter() end,
				desc = "Lists Function names, variables, from Treesitter",
			},
			{
				"<leader>sf",
				function()
					local telescope = require("telescope")

					local function telescope_buffer_dir()
						return vim.fn.expand("%:p:h")
					end

					telescope.extensions.file_browser.file_browser({
						path = "%:p:h",
						cwd = telescope_buffer_dir(),
						respect_gitignore = false,
						hidden = true,
						grouped = true,
						previewer = false,
						initial_mode = "normal",
						layout_config = { height = 40 },
					})
				end,
				desc = "Open File Browser with the path of the current buffer",
			},
		},

    config = function(_, opts)
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local fb_actions = require("telescope").extensions.file_browser.actions

      opts.defaults = vim.tbl_deep_extend("force", opts.defaults, {
        wrap_results = true,
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
        mappings = {
          n = {},
        },
      })

      opts.extensions = {
        file_browser = {
          theme = "dropdown",
          hijack_netrw = true,
          hide_parent_dir = true,
        },
      }

      telescope.setup(opts)
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("file_browser")
    end,
  },

  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        mode = "tabs",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
  },

  { "dracula/vim" },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "dracula" },
  },

  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    opts = function(_, opts)
      local logo = [[
здравствуйте

  ██████╗ ██╗ ██████╗  █████╗      ██████╗██╗  ██╗ █████╗ ██████╗
 ██╔════╝ ██║██╔════╝ ██╔══██╗    ██╔════╝██║  ██║██╔══██╗██╔══██╗
 ██║  ███╗██║██║  ███╗███████║    ██║     ███████║███████║██║  ██║
 ██║   ██║██║██║   ██║██╔══██║    ██║     ██╔══██║██╔══██║██║  ██║
 ╚██████╔╝██║╚██████╔╝██║  ██║    ╚██████╗██║  ██║██║  ██║██████╔╝
 ╚═════╝ ╚═╝ ╚═════╝ ╚═╝  ╚═╝     ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝
      ]]
      logo = string.rep("\n", 8) .. logo .. "\n\n"
      opts.config.header = vim.split(logo, "\n")
    end,
  },
}
