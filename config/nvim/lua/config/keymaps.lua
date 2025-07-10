-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.api.nvim_set_keymap(
  "n",
  "<leader>fB",
  ":Telescope file_browser<CR>",
  { noremap = true, desc = "Telescope browser root" }
)
vim.api.nvim_set_keymap(
  "n",
  "<leader>fb",
  ":Telescope file_browser path=%:p:h select_buffer=true<CR>",
  { noremap = true, desc = "Telescope browser current path" }
)
vim.api.nvim_set_keymap(
  "n",
  "<leader>un",
  ':execute "source" stdpath("config") . "/lua/config/colors.vim"<CR>',
  { noremap = true, desc = "Reload nix-generated config" }
)

-- mini.surround
-- Remap adding surrounding to Visual mode selection
vim.api.nvim_set_keymap("x", "S", [[:<C-u>lua MiniSurround.add('visual')<CR>]], { noremap = true })

-- Make special mapping for "add surrounding for line"
vim.api.nvim_set_keymap("n", "yss", "ys_", { noremap = false })
