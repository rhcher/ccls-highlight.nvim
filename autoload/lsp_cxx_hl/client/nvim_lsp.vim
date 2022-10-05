" Neovim LSP

function! lsp_cxx_hl#client#nvim_lsp#init() abort
    if has('nvim')
        call s:doinit()

        augroup lsp_cxx_hl_nvim_lsp_init
            autocmd! 
            autocmd VimEnter *  call s:doinit()
        augroup END
    else
        throw 'Not Neovim'
    endif
endfunction

function! s:doinit() abort
lua <<EOF
handlers = vim.lsp.handlers

--[ backwards compatibility with neovim<0.5 --]
if (handlers == nil)
then
  handlers = vim.lsp.callbacks
end

handlers['$ccls/publishSemanticHighlight'] = function(err, method, params, client_id)
    local data = method
    if data['uri'] == nil then
      data = params -- NOTE see change https://github.com/neovim/neovim/pull/15504
    end
    vim.api.nvim_call_function('lsp_cxx_hl#client#nvim_lsp#ccls_hl', {data})
end

handlers['$ccls/publishSkippedRanges'] = function(err, method, params, client_id)
    local data = method
    if data['uri'] == nil then
      data = params -- NOTE see change https://github.com/neovim/neovim/pull/15504
    end
    vim.api.nvim_call_function('lsp_cxx_hl#client#nvim_lsp#ccls_regions', {data})
end
EOF
endfunction

function! lsp_cxx_hl#client#nvim_lsp#ccls_hl(params) abort
    "call lsp_cxx_hl#log('ccls hl:', a:params)

    call lsp_cxx_hl#notify_symbols('ccls', a:params['uri'],
                \ a:params['symbols'])
endfunction

function! lsp_cxx_hl#client#nvim_lsp#ccls_regions(params) abort
    "call lsp_cxx_hl#log('ccls regions:', a:params)

    call lsp_cxx_hl#notify_skipped('ccls', a:params['uri'],
                \ a:params['skippedRanges'])
endfunction
