-- Read a secret file written by sops-nix (NixOS and nix-darwin put them in /run/secrets).
-- Returns nil when the file is missing, so the config still loads on machines without it.
local function read_secret(path)
  local f = path and io.open(path, "r")
  if not f then
    return nil
  end
  local s = (f:read("*a") or ""):gsub("%s+$", "")
  f:close()
  return s ~= "" and s or nil
end

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

        features = {
          calendar_feeds = {
            cozi = true,
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
              -- ntfy access token (sops secret ntfy_auth); override the path with $NTFY_TOKEN_FILE
              auth_token = read_secret(os.getenv("NTFY_TOKEN_FILE") or "/run/secrets/ntfy_auth"),
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
          search = { keys = { cycle_mode = "<M-m>" } },
          highlights = { preset = "rose-pine" },
          preview = { on_hover = false },
        },
      })

      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({
          { "<CR>", "<cmd>ZortexLinkOpen<cr>" },
          --- { "Zr", "<cmd>ZortexFoldsReload<cr>", desc = "Reload Zortex folds" },
          --- { "ZR", "<cmd>Lazy reload zortex.nvim<cr>", desc = "Reload Zortex plugin" },
          { "ZZ", "<cmd>ZortexSearch<cr>" },
          { "Zz", "<cmd>ZortexSearchArticles<cr>" },
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
