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
            autocmd FileType zortex nnoremap <buffer> <silent> <CR> :ZortexOpenLinkSplit<CR>
            autocmd FileType zortex vnoremap <buffer> <silent> <CR> :ZortexOpenLinkSplit<CR>
            autocmd FileType zortex setlocal norelativenumber nonumber
            " autocmd FileType zortex if exists(':Gitsigns') | Gitsigns toggle_signs | endif

            " map <silent>Zz :ZortexSearch<CR>
            " map <silent>ZZ :ZortexSearch<CR>
      ]])
    end,
  },
}
