let g:highlightactive=get(g:, 'highlightactive', 1)
hi InnerScope ctermbg=8 ctermfg=none cterm=none
hi OuterScope ctermbg=8 ctermfg=none cterm=none
hi LinkScope  ctermbg=8 ctermfg=none cterm=none

" so we want to search but not change search
map  :call Search()<cr>
nnoremap <Plug>(ScopeSearch) /<c-r>=SearchOnlyThisScope()<cr>
nnoremap <Plug>(SearchReplace) :%s/<c-r><c-w>/
nnoremap <Plug>(ScopeSearchStar) /\<<c-r>=SearchOnlyThisScope()<cr><c-r><c-w>\><cr>
nnoremap <Plug>(ScopeSearchStarAppend) /<c-r><c-/>\\|\<<c-r>=SearchOnlyThisScope()<cr><c-r><c-w>\><cr>
nnoremap <Plug>(ScopeSearchStarReplace) :%s/\<<c-r><c-w>\>/
nmap <leader>* <Plug>(ScopeSearchStar)N
nmap <leader># <Plug>(ScopeSearchStarAppend)N
nmap <leader>/ <Plug>(ScopeSearch)
nmap <F7> <Plug>(ScopeSearchStarReplace)
nmap <F6> <Plug>(SearchReplace)

func! Search() "{{{
    let curpos = getcurpos()
    let fin = ''
    while 1
        echon '/>> ' . l:fin
        try | call matchdelete(272398) | catch *
        endtry
        try | call matchdelete(272397) | catch *
        endtry

        let l:answer = getchar()

        " escape
        if l:answer == 27
            let l:fin = ''
            break
        endif

        " enter
        if l:answer == 13
            call search(l:fin."\\%>".line('w0').'l\%<'.line('w$')."l")
            break
        endif

        " Backspace
        if l:answer == "\<BS>"
            let l:fin = strcharpart(l:fin, 0, strlen(l:fin) - 1)

            call matchadd('IncSearch', IgnoreCase().''.fin.'', -999998, 272398)
            let sp = searchpos(l:fin, "nc")
            let len = strlen(l:fin)

            if l:fin != ''
                call matchaddpos('SearchC', [[sp[0], sp[1], l:len], ] , -999998, 272397)
            endif

            redraw
            continue
        endif

        " <c-w> 23
        if l:answer == 23
            let l:fin = strcharpart(l:fin, 0, strlen(l:fin) - 1)

            call matchadd('IncSearch', IgnoreCase().''.fin.'', -999998, 272398)
            let sp = searchpos(l:fin, "nc")
            let len = strlen(l:fin)

            if l:fin != ''
                call matchaddpos('SearchC', [[sp[0], sp[1], l:len], ] , -999998, 272397)
            endif

            redraw
            continue
        endif


        " <c-p> 16
        if l:answer == 16
            call search(l:fin."\\%>".line('w0').'l\%<'.line('w$')."l", 'b')

            call matchadd('IncSearch', IgnoreCase().''.fin.'', -999998, 272398)
            let sp = searchpos(l:fin, "nc")
            let len = strlen(l:fin)

            if l:fin != ''
                call matchaddpos('SearchC', [[sp[0], sp[1], l:len], ] , -999998, 272397)
            endif

            redraw
            continue
        endif

        " <c-n> 14
        if l:answer == 14
            call search(l:fin."\\%>".line('w0').'l\%<'.line('w$')."l", '')

            call matchadd('IncSearch', IgnoreCase().''.fin.'', -999998, 272398)
            let sp = searchpos(l:fin, "nc")
            let len = strlen(l:fin)

            if l:fin != ''
                call matchaddpos('SearchC', [[sp[0], sp[1], l:len], ] , -999998, 272397)
            endif

            redraw
            continue
        endif

        let l:answer = nr2char(l:answer)
        let fin .= l:answer

        try | call matchdelete(272398) | catch *
        endtry
        try | call matchdelete(272397) | catch *
        endtry

        call matchadd('IncSearch', IgnoreCase().''.fin.'', -999998, 272398)
        let sp = searchpos(l:fin, "c")
        let len = strlen(l:fin)

        if l:fin != ''
            call matchaddpos('SearchC', [[sp[0], sp[1], l:len], ] , -999998, 272397)
        endif

        redraw
    endwhile

    if l:fin == ''
        call setpos('.', l:curpos)
    endif

    try | call matchdelete(272398) | catch *
    endtry
    try | call matchdelete(272397) | catch *
    endtry
endfunc "}}}

if !hlexists('SearchC')
    hi link SearchC CursorLineNr
endif
if !hlexists('UnderLine')
    hi Underline ctermfg=none ctermbg=none guibg=none guifg=none gui=underline cterm=underline
endif

" Mapping to alter custom highlighting.
nnoremap <silent><c-space> :silent let g:highlightactive=!g:highlightactive<bar>
    \silent call AutoHighlightCurrentWord()<bar>
    \silent call ScopeIndentHighlight()<bar>
    \silent call HighlightCurrentSearchWord()<cr>

func! s:skipthis()
    if has_key(g:,'curhighword')
        return len(g:curhighword) < g:smallest ||
        \ (match(g:curhighword, "\\A") != -1 && match(g:curhighword, "_") == -1)
    else
        return 1
    endif
endfunc

func! GetAllClosedFolds()
    let ll = 0
    for l in range(line('w0'), line('w$'))
        if l > ll && foldclosed(l) != -1
            echom l
            let ll=foldclosedend(l)
        endif
    endfor
endfunc

func! BlinkLineAndColumn()
    " right now I just don't care
    let oldc = &cursorcolumn
    let oldl = &cursorline

    if !has_key(s:, 'lastfile')
        let s:lastfile = expand('%')
    endif

    if !has_key(s:, 'lastline')
        let s:lastline = line('.')
    endif

    if !has_key(s:, 'lastcol')
        let s:lastcol = col('.')
    endif

    if foldclosed(s:lastline) != -1
        return
    endif

    let s:distl = &scroll
    let s:distc = winwidth('.') * 9 / 10
    let s:colors = ['235', '234', '233']

    if s:lastfile != expand('%') ||
                \ abs(line('.') - s:lastline) > s:distl ||
                \ abs(col('.') - s:lastcol)   > s:distc
        if foldclosed('.') == -1
            redir => s:com
            silent! hi CursorLine
            silent! hi CursorColumn
            redir END
            let his = split(s:com,"\n")

            for col in s:colors
                exec 'highlight CursorLine ctermbg=' . col
                exec 'highlight CursorColumn ctermbg=' . col
                redraw
                sleep 50m
            endfor

            " restore there shite
            " exec " highlight " . substitute(his[0], "xxx", "", "")
            " exec " highlight " . substitute(his[1], 'xxx', "", "")
            call Colors()

            exec 'set ' . (oldc ? 'cursorcolumn' : 'nocursorcolumn')
            exec 'set ' . (oldl ? 'cursorline'   : 'nocursorline')
        endif

    endif

    " echom s:lastcolor
    let s:lastfile = expand('%')
    let s:lastline = line('.')
    let s:lastcol = col('.')
endfunc

func! HighlightCurrentSearchWord()
    try | call matchdelete(888) | catch *
    endtry
    try | call matchdelete(889) | catch *
    endtry

    if !g:highlightactive
        return
    endif

    " nbc Gets the first index.
    " nec Gets the last index (last - first + 1 == len).
    " n   Gets the next instance.
    try
        let sp = searchpos(@/, "nbc", line('.'))
        let sp2 = searchpos(@/, "nec", line('.'))
        let sp3 = searchpos(@/, "n", line('.'))
        let len = sp2[1] - sp[1] + 1

        if &hlsearch && sp != [0,0] && sp2 != [0,0] && (sp2[1] < sp3[1] || sp3 == [0,0])
            call matchaddpos('SearchC', [[line('.'), sp[1], l:len], ] , 888, 888)
        else
        endif
    catch E871
        echohl ErrorMsg
        echom "Invalid Search Pattern"
        echohl NONE
        return
    endtry
endfunc

func! AutoHighlightCurrentWord()
    if 1
        return
    endif

    try | call matchdelete(999) | catch *
    endtry

    if g:highlightactive
        let g:curhighword = expand("<cword>")
        let g:smallest = 2

        if s:skipthis()
            return
        endif

        if !(g:curhighword == @/ && &hlsearch)
            try
                call matchadd('InnerScope', IgnoreCase().'\<'.g:curhighword.'\>', -999999, 999)
            catch E874
            endtry
        endif
    endif
endfun

func! NextCurrentWord(back)
  norm! m`
  call search('\c' . IgnoreCase().'\<'.g:curhighword.'\>', a:back)
endfunc
nnoremap <silent>m :call NextCurrentWord('')<cr>zv
nnoremap <silent>M :call NextCurrentWord('b')<cr>zv


func! IgnoreCase()
    return &ignorecase ? '\c' : '\C'
endfunc

func! ScopeIndentHighlight()
    try | call matchdelete(101010) | catch *
    endtry
    try | call matchdelete(666) | catc *
    endtry
    try | call matchdelete(667) | catch *
    endtry
    try | call matchdelete(668) | catch *
    endtry
    try | call matchdelete(111) | catch *
    endtry
    try | call matchdelete(112) | catch *
    endtry
    try | call matchdelete(222) | catch *
    endtry
    try | call matchdelete(333) | catch *
    endtry
    try | call matchdelete(223) | catch *
    endtry
    try | call matchdelete(334) | catch *
    endtry
    try | call matchdelete(444) | catch *
    endtry

    if &filetype == 'help' || &filetype == 'qf' || !g:highlightactive || mode() != 'n'
     \ || len(getline('.')) == 0
        return
    endif

    let l:start = line('0')
    let l:end = line('$')
    let indent = indent('.')

    if l:indent < &shiftwidth
        let l:indent = &shiftwidth
    endif

    let o_indent = l:indent
    let passby = 1
    let lastline = ''
    for x in reverse(range(l:start,line('.')))
        if indent(x) < l:indent && !empty(getline(x))
            let l:start = x
            let indent = indent(x) + 1
            break
        else
            let lastline = x
        endif
    endfor

    for x in range(line('.'), l:end)
        if indent(x) < l:indent && !empty(getline(x))
            let l:end = x
            break
        endif
    endfor

    if len(getline(l:end - 1)) == 0
        let l:end -= 1
    endif

    call matchadd('OuterScope',"\\%".1."c\\%>".l:start.'l\%<'.l:end.'l',-50,666)

    if l:indent == l:o_indent
        let l:indent = l:indent - &shiftwidth + 1
    endif

    if !l:passby
        let o_indent += &shiftwidth
        let l:indent += &shiftwidth
    else
    endif

    let g:scope_startline = getline(l:start)
    let l:indentmorestart = 0

    if l:start != l:end
        let g:scope_endline = getline(l:end)
    else
        let g:scope_endline = ''
    endif

    if match(g:scope_endline,'\s\{2,}end\|}') == -1
        let l:end -= 1
    endif

    " use \{2,} not \+ because what if you have else { or else if {
    " If curly on new line get above for scope startline and column
    if match(g:scope_startline,'\s\{2,}{') != -1
        let l:indentmorestart = 1
        let g:scope_startline = getline(l:start - l:indentmorestart)
    endif

    let l:if = -1

    " If else then get if as well
    if match(g:scope_startline, '\s\+else\|elif') != -1
        let l:if = search('^\s\{'.(l:o_indent-&shiftwidth).'}if', 'bn')
    endif

    " If case then get switch as well
    if match(g:scope_startline, '\s\{2,}case') != -1
        let l:if = search('^\s\{'.(l:o_indent-&shiftwidth).'}switch', 'bn')
    endif

    " If catch then go with try
    if match(g:scope_startline, '\s\{2,}catch') != -1
        let l:if = search('^\s\{'.(l:o_indent-&shiftwidth).'}try', 'bn')
    endif

    if l:if != -1
        call matchaddpos('LinkScope' , [[l:if     , 1    , l:indent - l:passby - 1] ,] , -50, 111)
        call matchaddpos('LinkScope' , [[l:if     , l:indent - l:passby, 1 ],] , -50, 112)
    endif

    let l:indentmoreend = 0
    if match(g:scope_endline,'\s\{2,}}') != -1
        let l:indentmoreend = 1
    endif

    if l:indent != 1
        call matchaddpos('InnerScope', [[l:start  , l:indent - 1    , 1] ,] , -50, 222)
        call matchaddpos('InnerScope', [[l:end    , l:indent - 1    , 1] ,] , -50, 333)
        " call matchaddpos('HoldScope1', [[l:start + 1  , l:indent - 1    , 1] ,] , -50, 223)
        " if l:start + 1 != l:end - 1
            " call matchaddpos('HoldScope1', [[l:end - 1    , l:indent - 1    , 1] ,] , -50, 334)
            " call matchaddpos('HoldScope', [[l:end - 1    , 2    , l:indent - 3  + l:indentmoreend  ] ,] , -50, 668)
        " endif
        " call matchaddpos('HoldScope', [[l:start + 1  , 2    , l:indent - 3  + l:indentmorestart] ,] , -50, 667)
    endif

    let s:scope_start = l:start
    let s:scope_end   = l:end
    " try | call matchdelete(010101) | catch *
    " endtry
    " call matchaddpos('HoldScope1', [[line('.'), 80, 50] ,] , -50, 010101)
endfun

func! SearchOnlyThisScope()
    return '\%>'.(s:scope_start).'l\%<'.(s:scope_end + 1).'l'
endfun

augroup scope
    autocmd!
    autocmd CursorMoved * call ScopeIndentHighlight() | call AutoHighlightCurrentWord() | call HighlightCurrentSearchWord() | call BlinkLineAndColumn()
    autocmd CursorHold  * call ScopeIndentHighlight() | call AutoHighlightCurrentWord() | call HighlightCurrentSearchWord()
    autocmd InsertEnter * call ScopeIndentHighlight() | call AutoHighlightCurrentWord() | call HighlightCurrentSearchWord()
augroup END


