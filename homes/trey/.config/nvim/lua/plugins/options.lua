return {
  { import = "lazyvim.plugins.extras.linting.eslint" },
  { import = "lazyvim.plugins.extras.formatting.prettier" },
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.rust" },
  { import = "lazyvim.plugins.extras.lang.tailwind" },
  -- { import = "lazyvim.plugins.extras.coding.copilot" },
  -- { import = "lazyvim.plugins.extras.util.mini-hipatterns" },

  -- { "windwp/nvim-ts-autotag", enabled = false },
  { "folke/flash.nvim", enabled = false },
  { "norcalli/nvim-colorizer.lua" },
  { "echasnovski/mini.pairs", enabled = false },

  { "windwp/nvim-autopairs" },
  {
    "echasnovski/mini.surround",
    keys = function(_, keys)
      -- Populate the keys based on the user's options
      local plugin = require("lazy.core.config").spec.plugins["mini.surround"]
      local opts = require("lazy.core.plugin").values(plugin, "opts", false)
      local mappings = {
        { opts.mappings.add, desc = "Add surrounding", mode = { "n", "v" } },
        { opts.mappings.delete, desc = "Delete surrounding" },
        { opts.mappings.find, desc = "Find right surrounding" },
        { opts.mappings.find_left, desc = "Find left surrounding" },
        { opts.mappings.highlight, desc = "Highlight surrounding" },
        { opts.mappings.replace, desc = "Replace surrounding" },
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
        add = "ys",
        delete = "ds",
        find = "",
        find_left = "",
        highlight = "",
        replace = "cs",
        update_n_lines = "",
      },
      search_method = "cover_or_next",
      -- mappings = {
      --   add = "gsa", -- Add surrounding in Normal and Visual modes
      --   delete = "gsd", -- Delete surrounding
      --   find = "gsf", -- Find surrounding (to the right)
      --   find_left = "gsF", -- Find surrounding (to the left)
      --   highlight = "gsh", -- Highlight surrounding
      --   replace = "gsr", -- Replace surrounding
      --   update_n_lines = "gsn", -- Update `n_lines`
      -- },
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

  {
    "t-wilkinson/calendar-sync.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    dir = "~/dev/t-wilkinson/calendar-sync.nvim",
    install = [[bash -c "python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt"]],
    cmd = "SyncSchedule",
    config = function() end,
  },

  {
    "t-wilkinson/zortex.nvim",
    dir = "~/dev/t-wilkinson/zortex.nvim",
    build = "(cd app && yarn install); (cd rplugin && yarn install)",
    enabled = true,
    lazy = false,
    opts = {},
    config = function()
      vim.cmd([[
            let g:zortex_remote_wiki_port = 8081
            let g:zortex_remote_server = 'klean-studios'
            let g:zortex_remote_server_dir = '/www/zortex'

            let g:zortex_fenced_languages = ['python', 'javascript', 'bindzone', 'rust', 'bash', 'sh', 'json', 'sql']
            let g:zortex_notes_dir = $HOME . '/zortex/'
            let g:zortex_window_command = 'call FloatingFZF()'
            let g:zortex_extension = '.zortex'
            let g:zortex_theme = 'light'
            let g:zortex_auto_start_preview = 1
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

            map <silent>Zz :ZortexSearch<CR>
            map <silent>ZZ :ZortexSearch<CR>
      ]])
    end,
  },

  {
    "imsnif/kdl.vim",
  },

  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "pyright",
        "clangd",
        -- "stylua",
        -- "selene",
        -- "luacheck",
        -- "shellcheck",
        -- "shfmt",
        -- "tailwindcss-language-server",
        -- "typescript-language-server",
        -- "css-lsp",
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    enabled = true,
    opts = {
      ensure_installed = {
        "cmake",
        "c",
        "cpp",
        "css",
        "gitignore",
        "go",
        "http",
        "php",
        "rust",
        "sql",
        "python",
        "make",
        "ninja",
        "rst",
        "toml",
        "typescript",
        "tsx",
        "javascript",
        "markdown",
        "r",
      },
    },
  },

  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      opts.mapping["<CR>"] = nil
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
    "folke/zen-mode.nvim",
    opts = {
      window = {
        width = 0.85,
      },
    },
  },

  {
    "folke/noice.nvim",
    enabled = true,
    event = "VeryLazy",
    dependencies = {
      "rcarriga/nvim-notify",
    },
    opts = function(_, opts)
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = { skip = true },
      })
      opts.lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
        },
      }
      opts.presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false, -- add a border to hover docs and signature help
      }
    end,
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

  --[[{
    "telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      config = function()
        require("telescope").load_extension("fzf")
      end,
    },
  },
  ]]

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
      "nvim-lua/plenary.nvim",
    },

    -- stylua: ignore
    keys = {
      {
        "<leader>fP",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
      {
        "<leader>fp",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
			{
				"<leader>fP",
				function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root, }) end,
				desc = "Find Plugin File",
			},
			{
				"<leader>;f",
				function() local builtin = require("telescope.builtin") builtin.find_files({ no_ignore = false, hidden = true, }) end,
				desc = "Lists files in your current working directory, respects .gitignore",
			},
			{
				"<leader>;r",
				function() local builtin = require("telescope.builtin") builtin.live_grep({ additional_args = { "--hidden" }, }) end,
				desc = "Search for a string in your current working directory and get results live as you type, respects .gitignore",
			},
			{
				"<leader>\\\\",
				function() local builtin = require("telescope.builtin") builtin.buffers() end,
				desc = "Lists open buffers",
			},
			{
				"<leader>;t",
				function() local builtin = require("telescope.builtin") builtin.help_tags() end,
				desc = "Lists available help tags and opens a new window with the relevant help info on <cr>",
			},
			{
				"<leader>;;",
				function() local builtin = require("telescope.builtin") builtin.resume() end,
				desc = "Resume the previous telescope picker",
			},
			{
				"<leader>;e",
				function() local builtin = require("telescope.builtin") builtin.diagnostics() end,
				desc = "Lists Diagnostics for all open buffers or a specific buffer",
			},
			{
				"<leader>;s",
				function() local builtin = require("telescope.builtin") builtin.treesitter() end,
				desc = "Lists Function names, variables, from Treesitter",
			},
			{
				"<leader>sf",
				function()
					local telescope = require("telescope")

					local function telescope_buffer_dir()
						return vim.fn.expand("%:p:h")
					end

					telescope.extensions.file_browser.file_browser({
						path = "%:p:h",
						cwd = telescope_buffer_dir(),
						respect_gitignore = false,
						hidden = true,
						grouped = true,
						previewer = false,
						initial_mode = "normal",
						layout_config = { height = 40 },
					})
				end,
				desc = "Open File Browser with the path of the current buffer",
			},
		},

    config = function(_, opts)
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local fb_actions = require("telescope").extensions.file_browser.actions

      opts.defaults = vim.tbl_deep_extend("force", opts.defaults, {
        wrap_results = true,
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
        mappings = {
          n = {},
        },
      })

      opts.extensions = {
        file_browser = {
          theme = "dropdown",
          hijack_netrw = true,
          hide_parent_dir = true,
        },
      }

      telescope.setup(opts)
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("file_browser")
    end,
  },
}
