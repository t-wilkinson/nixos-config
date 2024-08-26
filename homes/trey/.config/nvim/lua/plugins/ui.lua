Util = require("lazyvim.util")

return {
  { "tribela/vim-transparent" },
  { "catppuccin/nvim", enabled = false },
  { "folke/tokyonight.nvim", enabled = false },
  -- { "dracula/vim", },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "default" },
  },

  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        mode = "tabs",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    enabled = true,
    opts = {
      signcolumn = false, -- Toggle with `:Gitsigns toggle_signs`
      numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
      linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
      word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
    },
  },

  {
    "echasnovski/mini.animate",
    recommended = true,
    enabled = false,
    event = "VeryLazy",
    opts = function()
      local mouse_scrolled = false
      for _, scroll in ipairs({ "Up", "Down" }) do
        local key = "<ScrollWheel" .. scroll .. ">"
        vim.keymap.set({ "", "i" }, key, function()
          mouse_scrolled = true
          return key
        end, { expr = true })
      end

      local animate = require("mini.animate")
      return {
        resize = {
          timing = animate.gen_timing.linear({ duration = 40, unit = "total" }),
        },
        scroll = {
          timing = animate.gen_timing.linear({ duration = 40, unit = "total" }),
          subscroll = animate.gen_subscroll.equal({
            predicate = function(total_scroll)
              if mouse_scrolled then
                mouse_scrolled = false
                return false
              end
              return total_scroll > 1
            end,
          }),
        },
      }
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        -- set an empty statusline till lualine loads
        vim.o.statusline = " "
      else
        -- hide the statusline on the starter page
        vim.o.laststatus = 0
      end
    end,
    opts = function()
      local lualine_require = require("lualine_require")
      lualine_require.require = require
      local icons = require("lazyvim.config").icons

      vim.o.laststatus = vim.g.lualine_laststatus

      return {
        options = {
          theme = "auto",
          globalstatus = true,
          disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
        },
        sections = {
          -- branch buffers diagnostics diff encoding fileformat filename filesize filetype hostname location mode progress searchcount selectioncount tabs windows
          lualine_a = { "mode" },
          lualine_b = { "branch" },

          lualine_c = {
            Util.lualine.root_dir(),
            {
              "diagnostics",
              symbols = {
                error = icons.diagnostics.Error,
                warn = icons.diagnostics.Warn,
                info = icons.diagnostics.Info,
                hint = icons.diagnostics.Hint,
              },
            },
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            {
              function(self)
                if vim.bo.filetype == "zortex" then
                  return vim.fn["zortex#search#LightlineZortex"]()
                else
                  return Util.lualine.pretty_path()(self)
                end
              end,
            },
          },
          lualine_x = {
              -- stylua: ignore
            {
              function() return require("noice").api.status.command.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
              color = Util.ui.fg("Statement"),
            },
              -- stylua: ignore
              {
                function() return require("noice").api.status.mode.get() end,
                cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
                color = Util.ui.fg("Constant"),
              },
              -- stylua: ignore
              {
                function() return "  " .. require("dap").status() end,
                cond = function () return package.loaded["dap"] and require("dap").status() ~= "" end,
                color = Util.ui.fg("Debug"),
              },
            {
              require("lazy.status").updates,
              cond = require("lazy.status").has_updates,
              color = Util.ui.fg("Special"),
            },
            {
              "diff",
              symbols = {
                added = icons.git.added,
                modified = icons.git.modified,
                removed = icons.git.removed,
              },
              source = function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                  return {
                    added = gitsigns.added,
                    modified = gitsigns.changed,
                    removed = gitsigns.removed,
                  }
                end
              end,
            },
          },
          lualine_y = {
            { "location", padding = { left = 0, right = 1 } },
          },
          lualine_z = {},
        },
        extensions = { "neo-tree", "lazy" },
      }
    end,
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
