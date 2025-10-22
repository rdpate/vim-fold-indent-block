nnoremap zx zxzz
nnoremap <silent> <expr> <leader><space> foldclosed(line('.')) == -1 ? 'zazO' : 'zO'
nnoremap <silent> <space> za

" Navigate by indentation.
    " nnoremap <silent> <leader>h :<c-u>call <sid>go_up_less(v:count1)<cr>
    nnoremap <silent> <leader>k :<c-u>call <sid>go_up_same(v:count1)<cr>
    nnoremap <silent> <leader>j :<c-u>call <sid>go_down_same(v:count1)<cr>
    " nnoremap <silent> <leader>l :<c-u>call <sid>go_down_less(v:count1)<cr>

    nnoremap <silent> <leader>s :<c-u>call <sid>go_up_less(v:count1)<cr>
    nnoremap <silent> <leader>d :<c-u>call <sid>top_go_up(v:count1)<cr>
    nnoremap <silent> <leader>f :<c-u>call <sid>top_go_down(v:count1)<cr>
    nnoremap <silent> <leader>g :<c-u>call <sid>go_down_less(v:count1)<cr>

    nnoremap <silent> <leader><leader> :<c-u>call <sid>top_go_up(v:count1)<cr>

let s:min_scroll_offset = [1, 5]  " [up, down]

function s:go_up_less(count = 1)
    mark '
    if s:is_top()
        return s:top_go_up(a:count)
        endif
    let num = 0
    while num < a:count
        let num += 1
        call s:_go_less_1('k')
        endwhile
    endfunction
function s:go_up_same(count = 1)
    mark '
    let num = 0
    while num < a:count
        let num += 1
        call s:_go_less_1('k', 1)
        endwhile
    endfunction
function s:go_down_less(count = 1)
    mark '
    if s:is_top()
        return s:top_go_down(a:count)
        endif
    let num = 0
    while num < a:count
        let num += 1
        call s:_go_less_1('j')
        endwhile
    endfunction
function s:go_down_same(count = 1)
    mark '
    let num = 0
    while num < a:count
        let num += 1
        call s:_go_less_1('j', 1)
        endwhile
    endfunction

function s:top_go_up(count = 1, mark = 1)
    if a:mark
        mark '
        endif
    let min_scroll_offset = s:min_scroll_offset[0]
    let saved_scrolloff = &l:scrolloff
    if min_scroll_offset > (&l:scrolloff > -1 ? &l:scrolloff : &scrolloff)
        let &l:scrolloff = min_scroll_offset
        endif
    call s:do_top_go_up(a:count)
    let &l:scrolloff = saved_scrolloff
    endfunction
function s:do_top_go_up(count)
    let need = a:count
    while need
        " Move up at least one line, and continue until a top line.
        if s:line() == 1 | return | endif
        normal! k^
        while ! s:is_top()
            if s:line() == 1 | return | endif
            normal! k^
            endwhile
        " Move up until next would be a non-top line.
        if s:line() == 1 | return | endif
        while s:is_top(getline(s:line_prev()))
            normal! k^
            if s:line() == 1 | return | endif
            endwhile

        let need -= 1
        endwhile
    endfunction
function s:top_go_down(count = 1)
    mark '
    let min_scroll_offset = s:min_scroll_offset[1]
    let saved_scrolloff = &l:scrolloff
    if min_scroll_offset > (&l:scrolloff > -1 ? &l:scrolloff : &scrolloff)
        let &l:scrolloff = min_scroll_offset
        endif

    let need = a:count
    const last = s:line('$')
    while need && s:line() < last
        " If at a top line, skip consecutive top lines.
        while s:is_top() && s:line() < last
            normal! j^
            endwhile
        " Now at a non-top line; search down for a top line.
        while ! s:is_top() && s:line() < last
            normal! j^
            endwhile

        let need -= 1
        endwhile

    let &l:scrolloff = saved_scrolloff
    endfunction

function s:_go_less_1(direction, or_same = 0)
    if a:direction ==# 'k'
        let end = 1
        let min_scroll_offset = s:min_scroll_offset[0]
    elseif a:direction ==# 'j'
        let end = s:line('$')
        let min_scroll_offset = s:min_scroll_offset[1]
    else
        throw "Invalid direction: must be 'j' or 'k'"
        endif
    let move_1 = "normal! " . a:direction . "^"
    let lineno = s:line()
    if lineno == end
        return
        endif

    let saved_scrolloff = &l:scrolloff
    if min_scroll_offset > (&l:scrolloff > -1 ? &l:scrolloff : &scrolloff)
        let &l:scrolloff = min_scroll_offset
        endif

    let target = s:indent_level(lineno)
    if target && ! a:or_same
        let target -= 1
        endif
    while 1
        execute move_1
        let lineno = s:line()
        if lineno == end
            break
            endif
        let text = getline(lineno)
        if text =~ s:blank_line || text =~ s:close_line
            continue
            endif
        if s:shift_count(text) <= target
            break
            endif
        endwhile

    let &l:scrolloff = saved_scrolloff
    endfunction

set foldmethod=expr foldexpr=s:fold_level()
set foldtext=s:fold_text()
set fillchars+=fold:\ ,
set commentstring=#\ %s

function s:line(expr = '.')
    " Line number for expr (see line()), ignoring folded lines (other than the first in the fold).
    let x = foldclosed(a:expr)
    return x == -1 ? line(a:expr) : x
    endfunction
function s:line_prev(expr = '.')
    " Previous line to expr, ignoring folded lines (other than the first in the fold).
    let lineno = s:line(a:expr) - 1
    let x = foldclosed(lineno)
    return x == -1 ? lineno : x
    endfunction
function s:line_next(expr = '.')
    " Next line to expr, ignoring folded lines (other than the first in the fold).
    let lineno = s:line(a:expr)
    let x = foldclosedend(lineno)
    return x == -1 ? lineno + 1 : x
    endfunction

let s:blank_line = '\v^[\t ]*$'
let s:close_line = '\v^[\t ]*[\]}),]+$'
function s:is_top(text = getline(s:line()))
    return a:text !~ s:close_line && s:shift_count(a:text) == 0
    endfunction
function s:shift_count(text = getline(s:line()))
    if a:text =~ s:blank_line
        return -1
        endif
    " Count leading tabs as having width of &tabstop.
    let tabs = len(matchstr(a:text, '\v^\t*'))
    let spaces = len(matchstr(a:text, '\v^ *', tabs))
    return (tabs * &tabstop + spaces) / shiftwidth()
    endfunction


function s:indent_level(lnum)
    let lineno = a:lnum
    const last = s:line('$')
    if lineno < 1 || last < lineno
        return 0
        endif
    let text = getline(lineno)
    if text =~ s:close_line
        " Return 1 + indent level for prior non-blank, non-close line.
        let continue = 1
        while continue
            if lineno == 1
                return 0
                endif
            let lineno -= 1
            let text = getline(lineno)
            let continue = text =~ s:close_line || text =~ s:blank_line
            endwhile
        return s:indent_level(lineno) + 1
        endif
    while text =~ s:blank_line
        " Return indent level of next non-blank line.
        if lineno == last
            return 0
            endif
        let lineno += 1
        let text = getline(lineno)
        if text =~ s:close_line
            return s:indent_level(lineno)
            endif
        endwhile
    return s:shift_count(text)
    endfunction
function s:fold_level()
    const line = getline(v:lnum)
    if line =~ s:blank_line || line =~ s:close_line
        return s:indent_level(v:lnum)
        endif
    const level = s:indent_level(v:lnum)
    const next = s:indent_level(v:lnum + 1)
    if level < next
        return ">" . next
        endif
    return level
    endfunction

function s:fold_text()
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
