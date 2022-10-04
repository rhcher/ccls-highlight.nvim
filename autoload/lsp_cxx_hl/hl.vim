" Helper functions for unifying match and textprop
" Variables:
" b:lsp_cxx_hl_disabled - disable highlighting for this buffer

" Check if highlighting in the current buffer needs updating
function! lsp_cxx_hl#hl#check(...) abort
    if get(b:, 'lsp_cxx_hl_disabled', 0)
        call lsp_cxx_hl#hl#clear()
        return
    endif

    return
endfunction

" Clear highlighting in this buffer
function! lsp_cxx_hl#hl#clear() abort
    let l:bufnr = winbufnr(0)

    call lsp_cxx_hl#textprop_nvim#symbols#clear(l:bufnr)
    call lsp_cxx_hl#textprop_nvim#skipped#clear(l:bufnr)
endfunction

" Enable the highlighting for this buffer
function! lsp_cxx_hl#hl#enable() abort
    unlet! b:lsp_cxx_hl_disabled

    let l:bufnr = winbufnr(0)

    call lsp_cxx_hl#textprop_nvim#symbols#highlight(l:bufnr)
    call lsp_cxx_hl#textprop_nvim#skipped#highlight(l:bufnr)
endfunction

" Disable the highlighting for this buffer
function! lsp_cxx_hl#hl#disable() abort
    let b:lsp_cxx_hl_disabled = 1

    call lsp_cxx_hl#hl#clear()
endfunction

" Notify of new semantic highlighting symbols
function! lsp_cxx_hl#hl#notify_symbols(bufnr, symbols) abort
    if get(b:, 'lsp_cxx_hl_disabled', 0)
        call lsp_cxx_hl#hl#clear()
    else
        call lsp_cxx_hl#textprop_nvim#symbols#notify(a:bufnr, a:symbols)
    endif
endfunction

" Notify of new preprocessor skipped regions
function! lsp_cxx_hl#hl#notify_skipped(bufnr, skipped) abort
    if get(b:, 'lsp_cxx_hl_disabled', 0)
        call lsp_cxx_hl#hl#clear()
    else
        if !empty(a:skipped)
            call lsp_cxx_hl#textprop_nvim#skipped#notify(a:bufnr, a:skipped)
            call s:stop_clear(a:bufnr, 'skipped_clear_timer')
        else
            call s:start_clear(a:bufnr, 'skipped_clear_timer',
                        \ function('lsp_cxx_hl#textprop_nvim#skipped#clear'
                        \ ))
        endif
    endif
endfunction

" Helper for running clear after some time has passed this clears the last
" symbol or skipped region leftover after a
" user deletes it
let s:has_timers = has('timers')
function! s:start_clear(bufnr, timer_var, ClearFn) abort
    if !s:has_timers
        call lsp_cxx_hl#log('WARNING: timers not available, '
                    \ 'delay cannot be done!')
        call a:ClearFn()
        return
    endif

    let l:timer = getbufvar(a:bufnr, a:timer_var, -1)
    if l:timer != -1
        call timer_stop(l:timer)
    endif

    let l:timer = timer_start(g:lsp_cxx_hl_clear_delay_ms,
                \ function('s:clear_timer_fn',
                \ [a:bufnr, a:timer_var, a:ClearFn]))
    call setbufvar(a:bufnr, a:timer_var, l:timer)
endfunction

function! s:stop_clear(bufnr, timer_var) abort
    if !s:has_timers
        return
    endif

    let l:timer = getbufvar(a:bufnr, a:timer_var, -1)
    if l:timer != -1
        call timer_stop(l:timer)
    endif
    call setbufvar(a:bufnr, a:timer_var, -1)
endfunction

function! s:clear_timer_fn(bufnr, timer_var, ClearFn, timer) abort
    call lsp_cxx_hl#verbose_log(a:timer_var, ' clear_timer_fn ', a:timer)
    call a:ClearFn(a:bufnr)
    call setbufvar(a:bufnr, a:timer_var, -1)
endfunction
