:syntax on
:set background=light
:colorscheme morning
:highlight Statement term=bold ctermfg=DarkBlue gui=bold guifg=Magenta
:highlight Comment ctermfg=DarkMagenta 
:highlight Identifier ctermfg=Black cterm=bold
:run! syntax/2html.vim
:wq! /tmp/%:t
:q!
