return {
  {
    "t-wilkinson/zortex.nvim",
    branch = "projects-api",
    dir = "~/dev/t-wilkinson/zortex.nvim",
    enabled = true,
    lazy = false,
    opts = {},
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("zortex").setup({
        notes_dir = vim.fn.expand("~/.zortex/"),
        special_articles = { "structure", "inbox" },
        keymaps = {
          prefix = "Z",
        },
        core = {
          logger = {
            enabled = false,
            log_events = false,
            level = 3,
          },
        },

        server = {
          enabled = true,
          api_endpoint = "https://zortex.home.lab",
          user_id = "default",
        },

        notifications = {
          providers = {
            ntfy = {
              enabled = true,
              topic = "zortex-notify",
              server_url = "https://ntfy.home.lab",
            },
          },

          types = {
            pomodoro = {
              work_duration = 25, -- minutes
              short_break = 5, -- minutes
              long_break = 15, -- minutes
              long_break_after = 4, -- number of work sessions
              auto_start_break = true,
              auto_start_work = false,
              sound = "default",
              use_server = true,
              ntfy_only = true,
            },
          },
        },

        -- UI Configuration
        ui = {
          highlights = { preset = "rose-pine" },
          preview = { on_hover = false },
          planner = {
            templates = {
              weekday = { "07:30 Meditate", "07:40 Planner", "08:00 MSCS" },
            },
          },
        },
      })

      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({
          { "<CR>", "<cmd>ZortexLinkOpen<cr>" },
          --- { "Zr", "<cmd>ZortexFoldsReload<cr>", desc = "Reload Zortex folds" },
          --- { "ZR", "<cmd>Lazy reload zortex.nvim<cr>", desc = "Reload Zortex plugin" },
          -- { "ZZ", "<cmd>ZortexSearchSections<cr>" },
          -- { "Zz", "<cmd>ZortexSearchSections<cr>" },
          -- { "Zs", "<cmd>e " .. require("zortex.config").notes_dir .. "/structure.zortex<cr>" },
          -- { "Zp", "<cmd>e " .. require("zortex.config").notes_dir .. "/projects.zortex<cr>" },
          -- { "Zp", "<cmd>ZortexProjects<cr>" },
          -- { "Zc", "<cmd>ZortexCalendar<cr>" },
          -- { "Zx", "<cmd>ZortexTaskToggle<cr>" },
        }, {
          mode = "n",
        })
      end
    end,
  },
}
