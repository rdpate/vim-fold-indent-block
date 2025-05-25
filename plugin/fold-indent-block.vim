nnoremap zx zxzz
nnoremap <silent> <expr> <leader><space> foldclosed(getcurpos()[1]) == -1 ? 'zazO' : 'zO'
nnoremap <silent> <space> za

" Navigate by indentation.
    nnoremap <silent> <leader>v :<c-u>call <sid>GoDownZero(v:count1)<cr>
    nnoremap <silent> <leader><leader> :<c-u>call <sid>GoUpZero(v:count1)<cr>

    nnoremap <silent> <leader>h :<c-u>call <sid>GoUpLess(v:count1)<cr>
    nnoremap <silent> <leader>j :<c-u>call <sid>GoDownSame(v:count1)<cr>
    nnoremap <silent> <leader>k :<c-u>call <sid>GoUpSame(v:count1)<cr>
    nnoremap <silent> <leader>l :<c-u>call <sid>GoDownLess(v:count1)<cr>

    " I'm experimenting with sdfg being the left-hand version of hjkl.
    " This is likely motivated by my using comma as leader.
    " Note up/down are mirrored, but left/right are according to keyboard position.
    nnoremap <silent> <leader>s :<c-u>call <sid>GoUpLess(v:count1)<cr>
    nnoremap <silent> <leader>f :<c-u>call <sid>GoDownSame(v:count1)<cr>
    nnoremap <silent> <leader>d :<c-u>call <sid>GoUpSame(v:count1)<cr>
    nnoremap <silent> <leader>g :<c-u>call <sid>GoDownLess(v:count1)<cr>


function! s:GoUpLess(count = 1)
    mark '
    let num = 0
    while num < a:count
        let num += 1
        call s:GoUpLess1()
        endwhile
    endfunction
function! s:GoDownLess(count = 1)
    mark '
    let num = 0
    while num < a:count
        let num += 1
        call s:GoDownLess1()
        endwhile
    endfunction
function! s:GoDownSame(count = 1)
    mark '
    let num = 0
    while num < a:count
        let num += 1
        call s:GoDownSame1()
        endwhile
    endfunction
function! s:GoUpSame(count = 1)
    mark '
    let num = 0
    while num < a:count
        let num += 1
        call s:GoUpSame1()
        endwhile
    endfunction
function! s:GoUpZero(count = 1)
    mark '
    let num = 0
    while num < a:count
        let num += 1
        call s:GoUpZero1()
        endwhile
    endfunction
function! s:GoDownZero(count = 1)
    mark '
    let num = 0
    while num < a:count
        let num += 1
        call s:GoDownZero1()
        endwhile
    endfunction
function! s:GoUpLess1()
    let current = getcurpos()[1]
    let indent = s:IndentLevel(current)
    "TODO: if current line is blank, get indent of next non-blank line, or 0 if reach EOF
    if indent == 0
        let indent = 1
        endif
    while current != 0
        normal! k
        " j/k is not always 1 line with folds
        let current = getcurpos()[1]
        if getline(current) =~ '\v^\s*$'
            continue
            endif
        if s:IndentLevel(current) < indent
            normal! ^
            break
            endif
        endwhile
    normal! ^
    endfunction
function! s:GoDownLess1()
    let current = getcurpos()[1]
    let indent = s:IndentLevel(current)
    "TODO: if current line is blank, get indent of next non-blank line, or 0 if reach EOF
    if indent == 0
        let indent = 1
        endif
    while current != 0
        normal! j
        " j/k is not always 1 line with folds
        let current = getcurpos()[1]
        if getline(current) =~ '\v^\s*$'
            continue
            endif
        if s:IndentLevel(current) < indent
            normal! ^
            break
            endif
        endwhile
    normal! ^
    endfunction
function! s:GoDownSame1()
    let current = getcurpos()[1]
    let indent = s:IndentLevel(current)
    "TODO: if current line is blank, get indent of next non-blank line, or 0 if reach EOF
    let last = line('$')
    while current < last
        normal! j
        "let current += 1
        let current = getcurpos()[1]
        if getline(current) =~ '\v^\s*$'
            continue
            endif
        if s:IndentLevel(current) <= indent
            normal! ^
            break
            endif
    endwhile
    normal! ^
    endfunction
function! s:GoUpSame1()
    let current = getcurpos()[1]
    let indent = s:IndentLevel(current)
    "TODO: if current line is blank, get indent of next non-blank line, or 0 if reach EOF
    while current != 0
        normal! k
        "let current -= 1
        let current = getcurpos()[1]
        if getline(current) =~ '\v^\s*$'
            continue
            endif
        if s:IndentLevel(current) <= indent
            normal! ^
            break
            endif
    endwhile
    normal! ^
    endfunction
function! s:GoUpZero1()
    let current = getcurpos()[1]
    while current != 0
        normal! k
        let current = getcurpos()[1]
        if getline(current) =~ '\v^\s*$'
            continue
            endif
        if getline(current) =~ '\v^\S'
            break
            endif
        endwhile
    normal! ^
    endfunction
function! s:GoDownZero1()
    let current = getcurpos()[1]
    while 1 == 1
        let prior = current
        normal! j
        let current = getcurpos()[1]
        if prior == current
            break
            endif
        if getline(current) =~ '\v^\s*$'
            continue
            endif
        if getline(current) =~ '\v^\S'
            break
            endif
        endwhile
    normal! ^
    endfunction

set foldmethod=expr foldexpr=GetIndentFold(v:lnum)
set foldtext=FoldText()
set fillchars+=fold:\ ,
set commentstring=#\ %s

function! FoldText()
    let text = getline(v:foldstart)
    let tabs = matchstr(text, '\v^\t*')
    if len(tabs) > 0
        let text = substitute(text, '\v^\t*', repeat(' ', &tabstop * len(tabs)), '')
        endif
    let text .= '… [' . (v:foldend + 1 - v:foldstart) . ' lines]'

    " If current line isn't a comment and the next line is a comment, then include the next line.
    if getline(v:foldstart) !~ '\v^\s*(#|/[/*])'
        let next = substitute(getline(v:foldstart + 1), '\v^\s+', '', '')
        if next =~ '\v^(#|/[/*]) '
            " comment: #, //, or /*
            let text .= ' ' . next
        elseif next =~ '\v^r?"'
            " Python-style docstring (or vim-script comment)
            " also multi-line Python dicts with string keys (unintentionally)
            let next = substitute(next, '\v\c^r?"+ *', '# ', '')
            let next = substitute(next, '\v"+$', '', '')
            let text .= ' ' . next
            endif
        endif

    let text .= '  '  " Don't crowd if fillchars isn't a space.
    return text
    endfunction
function! s:IndentLevel(lnum)
    let line = getline(a:lnum)
    " Count leading tabs as having width of &tabstop.
    let tabs = len(matchstr(line, '\v^\t*'))
    let spaces = len(matchstr(line, '\v^ *', tabs))
    return (tabs * &tabstop + spaces) / shiftwidth()
    endfunction
function! s:NextNonBlankLine(lnum)
    let numlines = line('$')
    let current = a:lnum + 1
    while current <= numlines
        if getline(current) =~ '[^ #]'
            return current
            endif
        let current += 1
        endwhile
    return -1
    endfunction
function! GetIndentFold(lnum)
    if getline(a:lnum) =~ '\v^[ #]*$'
        return -1
        endif

    let this_indent = s:IndentLevel(a:lnum)
    let next_indent = s:IndentLevel(s:NextNonBlankLine(a:lnum))

    if next_indent > this_indent
        return '>' . next_indent
    else
        return this_indent
        endif
    endfunction
