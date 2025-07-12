return {
  {
    "t-wilkinson/zortex.nvim",
    dir = "~/dev/t-wilkinson/zortex.nvim",
    -- build = "(cd app && yarn install)",
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

        -- XP System Configuration
        xp = {
          -- Task XP calculation
          task = {
            base = 10,
            position_multiplier = 2,
            early_bonus = 5,
            late_penalty = 0.8,
          },

          -- Area XP settings
          area = {
            level_base = 100,
            level_multiplier = 1.5,
            bubble_percentage = 0.2, -- 20% of XP bubbles to parent
          },

          -- Season configuration
          season = {
            base_xp = 1000,
            multiplier = 1.2,
            tiers = {
              { min = 1, max = 10, name = "Bronze" },
              { min = 11, max = 25, name = "Silver" },
              { min = 26, max = 50, name = "Gold" },
              { min = 51, max = 100, name = "Platinum" },
              { min = 101, max = 200, name = "Diamond" },
              { min = 201, max = 999, name = "Master" },
            },
          },
        },

        -- Skills configuration
        skills = {
          categories = {
            technical = { color = "#61afef", icon = "💻" },
            creative = { color = "#c678dd", icon = "🎨" },
            business = { color = "#98c379", icon = "💼" },
            personal = { color = "#e06c75", icon = "🌟" },
          },
        },

        -- UI Configuration
        ui = {
          -- Calendar UI settings
          calendar = {
            window = {
              width = 0.85,
              height = 0.85,
              border = "rounded",
              title = " 📅 Zortex Calendar ",
            },
            colors = {
              today = "DiagnosticOk",
              selected = "CursorLine",
              weekend = "Comment",
              has_entry = "DiagnosticInfo",
              header = "Title",
            },
            keymaps = {
              -- You can override default keymaps here
              close = { "q", "<Esc>", "<C-c>" },
              today = { "t", "T" },
              add_entry = { "a", "i", "A" },
            },
          },

          -- Telescope settings (optional)
          telescope = {
            -- Any telescope-specific overrides
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
          { "ZRF", "<cmd>ZortexReloadFolds<cr>", desc = "Reload Zortex folds" },
          { "ZZ", "<cmd>ZortexSearch<cr>" },
          { "Zz", "<cmd>ZortexSearch<cr>" },
          { "Zs", "<cmd>e " .. vim.g.zortex_notes_dir .. "/structure.zortex<cr>" },
          { "Zp", "<cmd>ZortexProjects<cr>" },
          { "Zc", "<cmd>ZortexCalendar<cr>" },
        }, {
          mode = "n",
        })
      end
    end,
  },
}
