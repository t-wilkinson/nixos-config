-- Colors follow the wallpaper: matugen writes ~/.local/state/theme/nvim.lua (a base16
-- palette, config/matugen/templates/nvim.lua) and mini.base16 applies it. The file is
-- watched, so changing the wallpaper recolors running Neovims too. Without the file
-- (before the first `theme-wallpaper`), rose-pine-moon is used.
local palette_file = vim.fn.expand("~/.local/state/theme/nvim.lua")

local function apply()
  local ok, theme = pcall(dofile, palette_file)
  if not ok or type(theme) ~= "table" or not theme.palette then
    vim.cmd.colorscheme("rose-pine-moon")
    return
  end
  vim.o.background = theme.mode == "light" and "light" or "dark"
  require("mini.base16").setup({ palette = theme.palette, use_cterm = true })
  vim.g.colors_name = "matugen"
end

local watcher
local function watch()
  if watcher then
    return
  end
  local dir = vim.fn.fnamemodify(palette_file, ":h")
  vim.fn.mkdir(dir, "p")
  watcher = vim.uv.new_fs_event()
  -- Watch the directory: matugen replaces the file, which a file watch would lose
  watcher:start(dir, {}, function(_, filename)
    if filename == "nvim.lua" then
      vim.schedule(apply)
    end
  end)
end

return {
  { "nvim-mini/mini.base16", lazy = true },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        apply()
        watch()
      end,
    },
  },
}
