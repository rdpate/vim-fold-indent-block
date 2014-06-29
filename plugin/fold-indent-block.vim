set foldmethod=expr
set foldexpr=GetIndentFold(v:lnum)

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
        if getline(current) =~? '\v\S'
            return current
        endif
        let current += 1
    endwhile
    return -1
endfunction

function! GetIndentFold(lnum)
    if getline(a:lnum) =~? '\v^\s*$'
        return '-1'
    endif

    let this_indent = s:IndentLevel(a:lnum)
    let next_indent = s:IndentLevel(s:NextNonBlankLine(a:lnum))

    if next_indent > this_indent
        return '>' . next_indent
    else
        return this_indent
    endif
endfunction
