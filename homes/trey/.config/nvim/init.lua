-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("colorizer").setup()

vim.lsp.set_log_level("OFF")
vim.cmd([[
   let s:init_dir = stdpath("config")
   let s:colors_vim = s:init_dir . '/lua/config/colors.vim'
   execute 'source' fnameescape(s:colors_vim)
]])
