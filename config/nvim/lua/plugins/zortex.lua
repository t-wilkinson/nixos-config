return {
  {
    "t-wilkinson/zortex.nvim",
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
        debug = true,
        core = {
          logger = {
            enabled = true,
            log_events = true,
          },
        },
        notifications = {
          providers = {
            aws = {
              enabled = true,
              api_endpoint = "https://qd5wcnxpn8.execute-api.us-east-1.amazonaws.com/prod/manifest",
              user_id = 229817327380,
            },
            ntfy = {
              enabled = true,
              topic = "zortex-notify-tcgcp",
              server_url = "https://ntfy.sh",
            },
            ses = {
              enabled = true,
              region = "us-east-1", -- Your AWS region
              from_email = "noreply@treywilkinson.com",
              default_to_email = "winston.trey.wilkinson@gmail.com",
              domain = "treywilkinson.com",
              use_api = false, -- Use AWS CLI for now
            },
          },

          -- Pomodoro settings
          pomodoro = {
            work_duration = 25, -- minutes
            short_break = 5, -- minutes
            long_break = 15, -- minutes
            long_break_after = 4, -- number of work sessions
            auto_start_break = true,
            auto_start_work = false,
            sound = "default",
          },

          -- Daily digest settings
          digest = {
            enabled = true,
            auto_send = true,
            days_ahead = 7,
            send_hour = 7, -- 7 AM
            check_interval_minutes = 60,
            digest_email = "winston.trey.wilkinson@gmail.com", -- Can be different from default
          },
        },

        -- UI Configuration
        ui = {
          -- Calendar UI settings
          calendar = {
            window = {
              -- width = 0.85,
              -- height = 0.85,
            },
            colors = {},
            keymaps = {
              -- You can override default keymaps here
              close = { "q", "<Esc>", "<C-c>" },
              today = { "t", "T" },
              add_entry = { "a", "i", "A" },
            },
          },
        },

        -- Feature toggles
        features = {
          auto_progress = true,
          xp_notifications = true,
          skill_tree = true,
        },
      })

      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({
          { "<CR>", "<cmd>ZortexOpenLink<cr>" },
          { "Zr", "<cmd>ZortexReloadFolds<cr>", desc = "Reload Zortex folds" },
          { "ZR", "<cmd>Lazy reload zortex.nvim<cr>", desc = "Reload Zortex plugin" },
          { "ZZ", "<cmd>ZortexSearch<cr>" },
          { "Zz", "<cmd>ZortexSearch<cr>" },
          { "Zs", "<cmd>e " .. require("zortex.config").notes_dir .. "/structure.zortex<cr>" },
          { "Zp", "<cmd>ZortexProjects<cr>" },
          { "Zc", "<cmd>ZortexCalendar<cr>" },
          { "Zx", "<cmd>ZortexToggleTask<cr>" },
        }, {
          mode = "n",
        })
      end
    end,
  },
}
