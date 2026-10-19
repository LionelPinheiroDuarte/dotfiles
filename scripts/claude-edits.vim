" Sourced by claude-edits when it opens a file in Vim.
" g:claude_before is the file as it was before Claude's edits ("" if no
" snapshot, "/dev/null" if Claude created the file).
"
"   ,d   toggle a before/after diff: Claude's "before" opens read-only on the left
"   q    while the diff is open: close everything

function! s:ClaudeDiff() abort
  " second ,d: close the diff, back to the plain file
  if exists('t:claude_before_buf') && bufexists(t:claude_before_buf)
    execute 'bwipeout' t:claude_before_buf
    unlet t:claude_before_buf
    diffoff!
    silent! nunmap <buffer> q
    return
  endif

  if empty(get(g:, 'claude_before', ''))
    echo 'no snapshot: edited before diffs were recorded'
    return
  endif
  if g:claude_before ==# '/dev/null'
    echo 'new file: created by Claude, nothing to diff'
    return
  endif

  let l:ft = &filetype
  let l:name = expand('%:t')
  diffthis
  nnoremap <buffer> <silent> q :qa<CR>

  leftabove vertical new
  execute 'silent read' fnameescape(g:claude_before)
  silent 1delete _
  execute 'silent file' fnameescape('[before claude] ' . l:name)
  setlocal buftype=nofile bufhidden=wipe noswapfile nomodifiable readonly
  let &l:filetype = l:ft
  nnoremap <buffer> <silent> q :qa<CR>
  diffthis
  let t:claude_before_buf = bufnr('%')

  wincmd l
endfunction

command! ClaudeDiff call s:ClaudeDiff()
nnoremap <silent> ,d :ClaudeDiff<CR>
