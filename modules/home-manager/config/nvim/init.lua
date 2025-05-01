-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
-- require("colorizer").setup()
--
-- vim.lsp.set_log_level("OFF")
-- vim.cmd([[
--    let s:init_dir = stdpath("config")
--    let s:colors_vim = s:init_dir . '/lua/config/colors.vim'
--    execute 'source' fnameescape(s:colors_vim)
-- ]])

-- syntax sync fromstart

-- local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
-- --   Info  09:47:33 PM notify.info Could not load parser for zortex: "Failed to load parser for language 'zortex': uv_dlopen: /home/trey/.local/share/nvim/lazy/nvim-treesitter/parser/zortex.so: undefined symbol: tree_sitter_markdown_external_scanner_create"
-- parser_config.zortex = {
--   install_info = {
--     url = "~/dev/t-wilkinson/tree-sitter-zortex", -- local path or git repo
--     files = { "tree-sitter-markdown/src/parser.c" }, -- note that some parsers also require src/scanner.c or src/scanner.cc
--     -- optional entries:
--     branch = "split_parser", -- default branch in case of git repo if different from master
--     generate_requires_npm = false, -- if stand-alone parser without npm dependencies
--     requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
--   },
-- }
