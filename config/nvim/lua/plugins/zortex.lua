return {
  {
    "t-wilkinson/zortex.nvim",
    dir = "~/dev/t-wilkinson/zortex.nvim",
    build = "(cd app && yarn install)",
    enabled = true,
    lazy = false,
    opts = {},
    config = function()
      vim.cmd([[
            let g:zortex_fenced_languages = ['python', 'javascript', 'bindzone', 'rust', 'bash', 'sh', 'json', 'sql']
            let g:zortex_notes_dir = $HOME . '/.zortex/'
            let g:zortex_window_command = 'call FloatingFZF()'
            let g:zortex_extension = '.zortex'
            let g:zortex_theme = 'light'
            let g:zortex_auto_start_preview = 1
            let g:zortex_special_articles = ['structure', 'inbox']
            let g:zortex_auto_start_server = 1
            let g:zortex_preview_options = {
                \ 'mkit': {},
                \ 'katex': {},
                \ 'uml': {},
                \ 'maid': {},
                \ 'disable_sync_scroll': 0,
                \ 'sync_scroll_type': 'middle',
                \ 'hide_yaml_meta': 1,
                \ 'sequence_diagrams': {},
                \ 'flowchart_diagrams': {},
                \ 'content_editable': v:false,
                \ 'disable_filename': 0,
                \ 'toc': {}
                \ }
            let g:zortex_port = '8080'

            nmap Z <Nop>
            nmap ZZ <Nop>
            autocmd FileType zortex nnoremap <buffer> <silent> <CR> :ZortexOpenLink<CR>
            autocmd FileType zortex vnoremap <buffer> <silent> <CR> :ZortexOpenLink<CR>
            autocmd FileType zortex setlocal norelativenumber nonumber
            " autocmd FileType zortex if exists(':Gitsigns') | Gitsigns toggle_signs | endif

            " map <silent>Zz :ZortexSearch<CR>
            " map <silent>ZZ :ZortexSearch<CR>
      ]])
    end,
  },

  --[[
 -- Zortex plugin configuration
  {
    "your-username/zortex.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("zortex").setup({
        -- File paths
        zortex_notes_dir = vim.fn.expand("~/Documents/zortex/"),
        zortex_root_dir = vim.fn.expand("~/Documents/zortex/"),

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

      -- Optional: Set up which-key descriptions if you use which-key.nvim
      local ok, which_key = pcall(require, "which-key")
      if ok then
        which_key.register({
          ["<leader>z"] = {
            name = "Zortex",
            c = { "<cmd>ZortexCalendarToggle<cr>", "Toggle Calendar" },
            C = { "<cmd>ZortexCalendarSearch<cr>", "Search Calendar" },
            d = { "<cmd>ZortexDigest<cr>", "Today's Digest" },
            D = { "<cmd>ZortexDigestBuffer<cr>", "Digest Buffer" },
            p = { "<cmd>ZortexProjects<cr>", "Browse Projects" },
            a = { "<cmd>ZortexAreas<cr>", "Area Progress" },
            s = { "<cmd>ZortexSearch<cr>", "Search Notes" },
            l = { "<cmd>ZortexLink<cr>", "Follow Link" },
            b = { "<cmd>ZortexBack<cr>", "Go Back" },
            x = { "<cmd>ZortexXP<cr>", "XP Stats" },
            t = { "<cmd>ZortexSkillTree<cr>", "Skill Tree" },
            A = { "<cmd>ZortexArchiveProject<cr>", "Archive Project" },
          },
        })
      end
    end,

    -- Lazy loading
    ft = { "zortex" },
    cmd = {
      "Zortex",
      "ZortexCalendar",
      "ZortexCalendarToggle",
      "ZortexCalendarSearch",
      "ZortexProjects",
      "ZortexDigest",
      "ZortexAreas",
      "ZortexSearch",
      "ZortexXP",
      "ZortexSkillTree",
    },
    keys = {
      { "<leader>zc", "<cmd>ZortexCalendarToggle<cr>", desc = "Toggle Calendar" },
      { "<leader>zd", "<cmd>ZortexDigest<cr>", desc = "Today's Digest" },
      { "<leader>zp", "<cmd>ZortexProjects<cr>", desc = "Browse Projects" },
    },
  },
}
]]
}
