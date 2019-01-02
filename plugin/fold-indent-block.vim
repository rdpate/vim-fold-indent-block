nnoremap zx zxzz
nnoremap <silent> <expr> <space> foldclosed(getcurpos()[1]) == -1 ? 'za' : 'zO'
nnoremap <silent> <leader>h :call <sid>GoUpLess()<cr>
nnoremap <silent> <leader>j :call <sid>GoDownSame()<cr>
nnoremap <silent> <leader>k :call <sid>GoUpSame()<cr>
nnoremap <silent> <leader><leader> :call <sid>GoUpLess()<cr>
function! s:GoUpLess()
    let current = getcurpos()[1]
    let indent = s:IndentLevel(current)
    "TODO: if current line is blank, get indent of next non-blank line, or 0 if reach EOF
    if indent == 0
        return
    endif
    while current != 0
        normal! k
        "let current -= 1
        let current = getcurpos()[1]
        if getline(current) =~ '\v^\s*$'
            continue
        endif
        if s:IndentLevel(current) < indent
            normal! ^
            break
        endif
    endwhile
    endfunction
function! s:GoDownSame()
    let current = getcurpos()[1]
    let indent = s:IndentLevel(current)
    "TODO: if current line is blank, get indent of next non-blank line, or 0 if reach EOF
    let last = line('$')
    while current < last
        normal j
        "let current += 1
        let current = getcurpos()[1]
        if getline(current) =~ '\v^\s*$'
            continue
        endif
        if s:IndentLevel(current) <= indent
            normal ^
            break
        endif
    endwhile
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
    endfunction

set foldmethod=expr
set foldexpr=GetIndentFold(v:lnum)
set foldtext=FoldText()
set fillchars+=fold:\ ,

function! FoldText()
    "let text = getline(v:foldstart) . '  '
    let text = getline(v:foldstart) . '  [+' . (v:foldend - v:foldstart) . ']'
    let next = getline(v:foldstart + 1)
    if next =~ '\v^\s*(#|/[/*]) '
        let text .= ' ' . substitute(next, '\v^\s*', '', '') . '  '
    endif
    return text
endfunction

if exists("*shiftwidth")
    function! s:IndentLevel(lnum)
        return indent(a:lnum) / shiftwidth()
    endfunction
else
    function! s:IndentLevel(lnum)
        return indent(a:lnum) / &shiftwidth
    endfunction
endif

function! s:NextNonBlankLine(lnum)
    let numlines = line('$')
    let current = a:lnum + 1
    while current <= numlines
        if getline(current) =~ '\v\S'
            return current
        endif
        let current += 1
    endwhile
    return -1
endfunction

function! GetIndentFold(lnum)
    if getline(a:lnum) =~ '\v^\s*$'
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
