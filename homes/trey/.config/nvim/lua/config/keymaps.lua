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

local wk = require("which-key")
-- wk.register({
--   ["<leader>Z"] = {
--     name = "+Zortex",
--     z = { "<cmd>ZortexSearch<cr>" },
--     Z = { "<cmd>ZortexSearch<cr>" },
--   },
--   ["<leader>ZS"] = {
--     name = "Server",
--     s = { "<cmd>ZortexStartServer<cr>" },
--     e = { "<cmd>ZortexStopServer<cr>" },
--   },
--   ["<leader>ZRF"] = { "<cmd>ZortexReloadFolds<cr>", "Reload Zortex folds" },
--   ["<leader>Zp"] = { "<cmd>ZortexPreview<cr>" },
--   ["<leader>ZRs"] = { "<cmd>ZortexStartRemoteServer<cr>" },
--   ["<leader>ZRr"] = { "<cmd>ZortexRestartRemoteServer<cr>" },
--   ["<leader>ZRS"] = { "<cmd>ZortexSyncRemoteServer<cr>" },
--   ["<leader>Zw"] = { "<cmd>ZortexSearchWikipedia<Space>" },
--   ["<leader>Zg"] = { "<cmd>ZortexSearchGoogle<Space>" },
--   ["<leader>Zr"] = { "<cmd>ZortexResourceToZettel<cr>" },
--   ["<leader>Zi"] = { "<cmd>ZortexListitemToZettel<cr>" },
--   ["<leader>Zs"] = { "<cmd>ZortexOpenStructure<cr>" },
-- })

wk.add({
  { "<leader>Z", group = "Zortex" },
  { "<leader>ZRF", "<cmd>ZortexReloadFolds<cr>", desc = "Reload Zortex folds" },
  { "<leader>ZRS", desc = "<cmd>ZortexSyncRemoteServer<cr>" },
  { "<leader>ZRr", desc = "<cmd>ZortexRestartRemoteServer<cr>" },
  { "<leader>ZRs", desc = "<cmd>ZortexStartRemoteServer<cr>" },
  { "<leader>ZS", group = "Server" },
  { "<leader>ZSe", desc = "<cmd>ZortexStopServer<cr>" },
  { "<leader>ZSs", desc = "<cmd>ZortexStartServer<cr>" },
  { "<leader>ZZ", desc = "<cmd>ZortexSearch<cr>" },
  { "<leader>Zg", desc = "<cmd>ZortexSearchGoogle<Space>" },
  { "<leader>Zi", desc = "<cmd>ZortexListitemToZettel<cr>" },
  { "<leader>Zp", desc = "<cmd>ZortexPreview<cr>" },
  { "<leader>Zr", desc = "<cmd>ZortexResourceToZettel<cr>" },
  { "<leader>Zs", desc = "<cmd>ZortexOpenStructure<cr>" },
  { "<leader>Zw", desc = "<cmd>ZortexSearchWikipedia<Space>" },
  { "<leader>Zz", desc = "<cmd>ZortexSearch<cr>" },
})
