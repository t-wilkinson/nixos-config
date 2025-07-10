return {
  {
    "LazyVim/LazyVim",
    opts = {},
  },

  { "folke/flash.nvim", enabled = false },
  { "norcalli/nvim-colorizer.lua" },

  -- { "nvim-telescope/telescope.nvim", event = "VimEnter" },

  -- { "windwp/nvim-autopairs" },
  { "echasnovski/mini.pairs", enabled = false },
  { "echasnovski/mini.ai", enabled = true },
  {
    "echasnovski/mini.surround",
    keys = function(_, keys)
      -- Populate the keys based on the user's options
      local opts = LazyVim.opts("mini.surround")
      local mappings = {
        { opts.mappings.add, desc = "Add Surrounding", mode = { "n", "v" } },
        { opts.mappings.delete, desc = "Delete Surrounding" },
        { opts.mappings.find, desc = "Find Right Surrounding" },
        { opts.mappings.find_left, desc = "Find Left Surrounding" },
        { opts.mappings.highlight, desc = "Highlight Surrounding" },
        { opts.mappings.replace, desc = "Replace Surrounding" },
        { opts.mappings.update_n_lines, desc = "Update `MiniSurround.config.n_lines`" },
      }
      mappings = vim.tbl_filter(function(m)
        return m[1] and #m[1] > 0
      end, mappings)
      return vim.list_extend(mappings, keys)
    end,
    opts = {
      custom_surroundings = {
        ["("] = { output = { left = "( ", right = " )" } },
        ["["] = { output = { left = "[ ", right = " ]" } },
        ["{"] = { output = { left = "{ ", right = " }" } },
        ["<"] = { output = { left = "< ", right = " >" } },
      },
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",
      },
      search_method = "cover_or_next",
    },
  },

  { "ben-grande/vim-qrexec" },

  { "junegunn/fzf", build = "./install --all" },
  {
    "junegunn/fzf.vim",
    config = function()
      vim.cmd([[
        " CTRL-T(tab) / CTRL-X(split) / CTRL-V(ver-split)
        " let $FZF_DEFAULT_COMMAND =  "find * -path '*/\.*' -prune -o -path 'node_modules/**' -prune -o -path 'target/**' -prune -o -path 'dist/**' -prune -o  -type f -print -o -type l -print 2> /dev/null"
        let $FZF_DEFAULT_COMMAND =  "fd . --type f -E node_modules"
        " let $FZF_DEFAULT_OPTS=' --cycle --exact --color=dark --color=fg:16,bg:-1,hl:1,fg+:#ffffff,bg+:-1,hl+:1 --color=info:12,prompt:0,pointer:12,marker:4,spinner:11,header:-1 --layout=reverse  --margin=1,4 --preview-window=":60%" --bind ctrl-k:preview-up,ctrl-j:preview-down,ctrl-f:preview-page-down,ctrl-b:preview-page-up'
        let $FZF_DEFAULT_OPTS=' --cycle --exact --layout=reverse  --margin=1,4 --preview-window=":60%" --bind ctrl-k:preview-up,ctrl-j:preview-down,ctrl-f:preview-page-down,ctrl-b:preview-page-up'
        let g:fzf_layout = { 'window': 'call FloatingFZF()' }
        let g:fzf_command_prefix = "Fzf"

        " https://github.com/junegunn/fzf.vim#advanced-customization
        command! -bang -nargs=* FzfRg
          \ call fzf#vim#grep(
          \   'rg --column --line-number --no-heading --color=always --smart-case -g !node_modules -- '.shellescape(<q-args>), 1,
          \   fzf#vim#with_preview(), <bang>0)

        " https://www.reddit.com/r/neovim/comments/djmehv/im_probably_really_late_to_the_party_but_fzf_in_a/
        function! FloatingFZF()
          let buf = nvim_create_buf(v:false, v:true)
          call setbufvar(buf, '&signcolumn', 'no')

          let height = float2nr(50)
          let width = float2nr(&columns - 8)
          let horizontal = float2nr((&columns - width) / 2)
          let vertical = 1

          let opts = {
                \ 'relative': 'editor',
                \ 'row': vertical,
                \ 'col': horizontal,
                \ 'width': width,
                \ 'height': height,
                \ 'style': 'minimal'
                \ }

          call nvim_open_win(buf, v:true, opts)
        endfunction
      ]])
    end,
  },

  {
    "pseewald/vim-anyfold",
    config = function()
      vim.cmd([[
        let g:anyfold_fold_comments=1
        let g:anyfold_fold_size_str='%s'
        let g:anyfold_fold_level_str=''
        " activate anyfold by default
            augroup anyfold
                autocmd!
                " autocmd Filetype * AnyFoldActivate
            augroup END

        " disable anyfold for large files
            let g:LargeFile = 1000000 " file is large if size greater than 1MB
            autocmd BufReadPre,BufRead * let f=getfsize(expand("<afile>")) | if f > g:LargeFile || f == -2 | call LargeFile() | endif
            function! LargeFile()
                augroup anyfold
                    autocmd! anyfold
                    autocmd Filetype * setlocal foldmethod=indent " fall back to indent folding
                    autocmd Filetype * syntax off
                augroup END
            endfunction
        ]])
    end,
  },

  -- {
  --   "t-wilkinson/calendar-sync.nvim",
  --   dependencies = { "nvim-lua/plenary.nvim" },
  --   dir = "~/dev/t-wilkinson/calendar-sync.nvim",
  --   install = [[bash -c "python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt"]],
  --   cmd = "SyncSchedule",
  --   config = function() end,
  -- },

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "onsails/lspkind-nvim",
      -- Add other sources like snippet engines if you use them
      -- "L3MON4D3/LuaSnip",
      -- "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind") -- Optional: for icons

      -- =================================================================
      -- IMPORTANT: Require and set up your custom Zortex source
      -- =================================================================
      -- This assumes your zortex source file is at `lua/zortex/cmp.lua`
      -- Adjust the path if you place it elsewhere.
      local zortex_cmp = require("zortex.cmp")
      zortex_cmp.setup()
      -- =================================================================

      cmp.setup({
        snippet = {
          -- expand = function(args)
          -- 	require("luasnip").lsp_expand(args.body)
          -- end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        -- Define the order and sources for completion
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "zortex" }, -- Your custom source!
          { name = "buffer" },
          { name = "path" },
          -- { name = "luasnip" },
        }),
        formatting = {
          -- Optional: Add icons to completion items
          format = lspkind.cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
      })

      -- You can also set up filetype-specific sources if you wish
      -- For example, to prioritize Zortex suggestions in markdown files:
      cmp.setup.filetype({ "markdown", "zortex" }, {
        sources = cmp.config.sources({
          { name = "zortex" },
          { name = "buffer" },
        }),
      })
    end,
  },

  { "nvimtools/none-ls.nvim", enabled = false },

  {
    "mfussenegger/nvim-lint",
    enabled = false,
    opts = {
      linters = {
        markdownlint = {
          args = { "--disable", "MD013", "--" },
        },
      },
    },
  },

  {
    "rcarriga/nvim-notify",
    enabled = true,
    -- render style minimal/simple/compact/wrapped-compact
    opts = {
      render = "minimal",
    },
  },
  {
    "lukas-reineke/headlines.nvim",
    -- TODO: write custom treesitter parser for zortex (https://tree-sitter.github.io/tree-sitter/creating-parsers)
    opts = function()
      local opts = {}
      for _, ft in ipairs({ "markdown", "norg", "rmd", "org", "zortex" }) do
        opts[ft] = {
          headline_highlights = {},
          -- disable bullets for now. See https://github.com/lukas-reineke/headlines.nvim/issues/66
          bullets = {},
        }
        for i = 1, 6 do
          local hl = "Headline" .. i
          vim.api.nvim_set_hl(0, hl, { link = "Headline", default = true })
          table.insert(opts[ft].headline_highlights, hl)
        end
      end
      return opts
    end,
    ft = { "markdown", "norg", "rmd", "org", "zortex" },
    config = function(_, opts)
      -- PERF: schedule to prevent headlines slowing down opening a file
      vim.schedule(function()
        require("headlines").setup(opts)
        require("headlines").refresh()
      end)
    end,
  },

  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      explorer = {
        replace_netrw = true,
      },
      picker = {
        sources = {
          explorer = {},
        },
      },
    },
  },
}
