-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("colorizer").setup()
vim.cmd([[
   " let s:init_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
   let s:init_dir = stdpath("config")
   let s:colors_vim = s:init_dir . '/lua/config/colors.vim'
   execute 'source' fnameescape(s:colors_vim)
]])
-- vim.cmd("source " .. nvimrc .. "/lua/config/colors.vim")
