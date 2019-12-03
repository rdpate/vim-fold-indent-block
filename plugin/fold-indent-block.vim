nnoremap zx zxzz
nnoremap <silent> <expr> <leader><space> foldclosed(getcurpos()[1]) == -1 ? 'zazO' : 'zO'
nnoremap <silent> <space> za
nnoremap <silent> <leader>j m':call <sid>GoDownSame()<cr>
nnoremap <silent> <leader>k m':call <sid>GoUpSame()<cr>
nnoremap <silent> <leader><leader> m':call <sid>GoUpLess()<cr>
" is above same as [z when folding by indent? (almost)
" except folding isn't always by indent!
"nnoremap <leader><leader> [z^
function! s:GoUpLess()
    let current = getcurpos()[1]
    let indent = s:IndentLevel(current)
    "TODO: if current line is blank, get indent of next non-blank line, or 0 if reach EOF
    if indent == 0
        let indent = 1
        endif
    while current != 0
        normal! k
        "let current -= 1
        " 'k' is not always -1 line with folds
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
function! s:GoDownSame()
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
function! s:GoUpSame()
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

set foldmethod=expr foldexpr=GetIndentFold(v:lnum)
set foldtext=FoldText()
set fillchars+=fold:\ ,
set commentstring=#\ %s

function! FoldText()
    let text = getline(v:foldstart)
    "let text .= '  [+' . (v:foldend - v:foldstart) . ']'
    " if currnet line isn't a comment, then maybe show next line
    if getline(v:foldstart) !~ '\v^\s*(#|/[/*])'
        let next = substitute(getline(v:foldstart + 1), '\v^ +', '', '')
        if next =~ '\v^(#|/[/*]) '
            " comment: # or //
            let text .= '  ' . next
        elseif next =~ '\v^r?"'
            " Python-style docstring (or vim-script comment)
            " also multi-line Python dicts with string keys (unintentionally)
            let next = substitute(next, '\v\c^r?"+ *', '# ', '')
            let next = substitute(next, '\v"+$', '', '')
            let text .= '  ' . next
            endif
        endif
    " append spaces to not crowd if fillchars isn't space for folds
    let text .= '  '
    return text
    endfunction

function! s:IndentLevel(lnum)
    let line = getline(a:lnum)
    let tabs = len(substitute(line, '\v^(\t*).*$', '\1', ''))
    let spaces = repeat(' ', &tabstop * tabs)
    let line = spaces . line[tabs:]
    let line = substitute(line, '\v^([ #]*).*', '\1', '')
    return len(line) / shiftwidth()
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
