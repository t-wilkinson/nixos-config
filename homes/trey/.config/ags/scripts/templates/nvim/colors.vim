" $darkmode: true;
" $primary: #ffb783;
" $onPrimary: #502400;
" $primaryContainer: #723600;
" $onPrimaryContainer: #ffdcc4;
" $secondary: #e4bfa8;
" $onSecondary: #422b1b;
" $secondaryContainer: #5b412f;
" $onSecondaryContainer: #ffdcc4;
" $tertiary: #c8ca94;
" $onTertiary: #31320b;
" $tertiaryContainer: #474920;
" $onTertiaryContainer: #e5e6ae;
" $error: #ffb4a9;
" $onError: #680003;
" $errorContainer: #930006;
" $onErrorContainer: #ffb4a9;
" $colorbarbg: #130F0D;
" $background: #130F0D;
" $onBackground: #ece0da;
" $surface: #201a17;
" $onSurface: #ece0da;
" $surfaceVariant: #52443b;
" $onSurfaceVariant: #d7c3b7;
" $outline: #9f8d83;
" $shadow: #000000;
" $inverseSurface: #ece0da;
" $inverseOnSurface: #362f2b;
" $inversePrimary: #964900;

hi Normal guifg=NONE guibg=NONE gui=NONE cterm=NONE
hi CursorLineNr guifg=NONE guibg=NONE gui=NONE cterm=NONE
hi CursorLine guifg=NONE guibg=#{{ $secondary }} gui=NONE cterm=NONE
hi NonText guifg=#{{ $primary }} guibg=NONE gui=NONE cterm=NONE
hi EndOfBuffer guifg=NONE guibg=NONE gui=NONE cterm=NONE
hi LineNr guifg=NONE guibg=NONE gui=NONE cterm=NONE
hi FoldColumn guifg=#6c6c6c guibg=#1c1c1c gui=NONE cterm=NONE
hi Folded guifg=#6c6c6c guibg=#1c1c1c gui=NONE cterm=NONE
hi MatchParen guifg=#ffffaf guibg=#1c1c1c gui=NONE cterm=NONE
hi SignColumn guifg=#7c7c7c guibg=#2c2c1c gui=NONE cterm=NONE
hi Pmenu guifg=#bcbcbc guibg=#444444 gui=NONE cterm=NONE
hi PmenuSbar guifg=NONE guibg=#585858 gui=NONE cterm=NONE
hi PmenuSel guifg=#262626 guibg=#5f8787 gui=NONE cterm=NONE
hi PmenuThumb guifg=#5f8787 guibg=#5f8787 gui=NONE cterm=NONE
hi ErrorMsg guifg=#af5f5f guibg=#262626 gui=reverse cterm=reverse
hi ModeMsg guifg=#87af87 guibg=#262626 gui=reverse cterm=reverse
hi MoreMsg guifg=#5f8787 guibg=NONE gui=NONE cterm=NONE
hi Question guifg=#87af87 guibg=NONE gui=NONE cterm=NONE
hi WarningMsg guifg=#af5f5f guibg=NONE gui=NONE cterm=NONE
hi TabLine guifg=#87875f guibg=#444444 gui=NONE cterm=NONE
hi TabLineFill guifg=#444444 guibg=#444444 gui=NONE cterm=NONE
hi TabLineSel guifg=#262626 guibg=#87875f gui=NONE cterm=NONE
hi ToolbarLine guifg=NONE guibg=#1c1c1c gui=NONE cterm=NONE
hi ToolbarButton guifg=#bcbcbc guibg=#585858 gui=NONE cterm=NONE
hi Cursor guifg=#262626 guibg=#bcbcbc gui=NONE cterm=NONE
hi CursorColumn guifg=NONE guibg=#303030 gui=NONE cterm=NONE
hi StatusLine guifg=#262626 guibg=#87875f gui=NONE cterm=NONE
hi StatusLineNC guifg=#87875f guibg=#444444 gui=NONE cterm=NONE
hi StatusLineTerm guifg=#262626 guibg=#87875f gui=NONE cterm=NONE
hi StatusLineTermNC guifg=#87875f guibg=#444444 gui=NONE cterm=NONE
hi Visual guifg=#87afd7 guibg=#262626 gui=reverse cterm=reverse
hi VisualNOS guifg=NONE guibg=NONE gui=underline ctermfg=NONE ctermbg=NONE cterm=underline
hi VertSplit guifg=#444444 guibg=#444444 gui=NONE cterm=NONE
hi WildMenu guifg=#262626 guibg=#87afd7 gui=NONE cterm=NONE
hi DiffAdd guifg=#87afff guibg=#303030 gui=reverse cterm=reverse
hi DiffChange guifg=#dfdfdf guibg=#303030 gui=reverse cterm=reverse
hi DiffDelete guifg=#ffdf87 guibg=#303030 gui=reverse cterm=reverse
hi DiffText guifg=#afafaf guibg=#303030 gui=reverse cterm=reverse
hi IncSearch guifg=#262626 guibg=#af5f5f gui=NONE cterm=NONE
hi Search guifg=#262626 guibg=#ffffaf gui=NONE cterm=NONE
hi Directory guifg=#5fafaf guibg=NONE gui=NONE cterm=NONE
hi debugPC guifg=NONE guibg=#5f87af gui=NONE cterm=NONE
hi debugBreakpoint guifg=NONE guibg=#af5f5f gui=NONE cterm=NONE
hi SpellBad guifg=#af5f5f guibg=NONE guisp=#af5f5f gui=undercurl cterm=undercurl
hi SpellCap guifg=#5fafaf guibg=NONE guisp=#5fafaf gui=undercurl cterm=undercurl
hi SpellLocal guifg=#5f875f guibg=NONE guisp=#5f875f gui=undercurl cterm=undercurl
hi SpellRare guifg=#ff8700 guibg=NONE guisp=#ff8700 gui=undercurl cterm=undercurl
hi ColorColumn guifg=NONE guibg=#1c1c1c gui=NONE cterm=NONE
hi! link Terminal Normal
hi! link CursorIM Cursor
hi! link QuickFixLine Search
hi Comment guifg={{ $surface }} guibg=NONE gui=NONE cterm=NONE
hi Conceal guifg=#bcbcbc guibg=NONE gui=NONE cterm=NONE
hi Constant guifg=#ff8700 guibg=NONE gui=NONE cterm=NONE
hi Error guifg=#af5f5f guibg=NONE gui=reverse cterm=reverse
hi Identifier guifg=#5f87af guibg=NONE gui=NONE cterm=NONE
hi Ignore guifg=NONE guibg=NONE gui=NONE ctermfg=NONE ctermbg=NONE cterm=NONE
hi PreProc guifg=#5f8787 guibg=NONE gui=NONE cterm=NONE
hi Special guifg=#5f875f guibg=NONE gui=NONE cterm=NONE
hi Statement guifg=#87afd7 guibg=NONE gui=NONE cterm=NONE
hi String guifg=#87af87 guibg=NONE gui=NONE cterm=NONE
hi Todo guifg=NONE guibg=NONE gui=reverse ctermfg=NONE ctermbg=NONE cterm=reverse
hi Type guifg=#8787af guibg=NONE gui=NONE cterm=NONE
hi Underlined guifg=#5f8787 guibg=NONE gui=underline cterm=underline
hi Function guifg=#ffffaf guibg=NONE gui=NONE cterm=NONE
hi SpecialKey guifg=#585858 guibg=NONE gui=NONE cterm=NONE
hi Title guifg=NONE guibg=NONE gui=NONE ctermfg=NONE ctermbg=NONE cterm=NONE
hi helpLeadBlank guifg=NONE guibg=NONE gui=NONE ctermfg=NONE ctermbg=NONE cterm=NONE
hi helpNormal guifg=NONE guibg=NONE gui=NONE ctermfg=NONE ctermbg=NONE cterm=NONE
hi! link Number Constant
hi! link Boolean Constant
hi! link Character Constant
hi! link Conditional Statement
hi! link Debug Special
hi! link Define PreProc
hi! link Delimiter Special
hi! link Exception Statement
hi! link Float Number
hi! link Include PreProc
hi! link Keyword Statement
hi! link Label Statement
hi! link Macro PreProc
hi! link Operator Statement
hi! link PreCondit PreProc
hi! link Repeat Statement
hi! link SpecialChar Special
hi! link SpecialComment Special
hi! link StorageClass Type
hi! link Structure Type
hi! link Tag Special
hi! link Typedef Type
hi! link HelpCommand Statement
hi! link HelpExample Statement
hi! link htmlTagName Statement
hi! link htmlEndTag htmlTagName
hi! link htmlLink Function
hi! link htmlSpecialTagName htmlTagName
hi! link htmlTag htmlTagName
hi! link htmlBold Normal
hi! link htmlItalic Normal
hi! link htmlArg htmlTagName
hi! link xmlTag Statement
hi! link xmlTagName Statement
hi! link xmlEndTag Statement
hi! link markdownItalic Preproc
hi! link asciidocQuotedEmphasized Preproc

