let g:recent_file = expand('.vim/recent')
let g:recent_files_list = []

" Load recent files into memory at startup
function! s:LoadRecentFiles() abort
  if filereadable(g:recent_file)
    let g:recent_files_list = readfile(g:recent_file)
  endif
endfunction

" Save recent files from memory to disk
function! s:SaveRecentFiles() abort
  if !empty(g:recent_files_list)
    call writefile(g:recent_files_list, g:recent_file)
  endif
endfunction

function! RecentFilesComplete(ArgLead, CmdLine, CursorPos) abort
  return empty(a:ArgLead) ? g:recent_files_list : matchfuzzy(g:recent_files_list, a:ArgLead)
endfunction

function! s:AddToRecent() abort
  let file = expand('%:p')
  if file ==# '' || !filereadable(file) | return | endif

  " Only track files under cwd
  let cwd = getcwd()
  if file !~# '^' . escape(cwd, '\') | return | endif

  " Convert to relative path
  let file = substitute(file, '^' . escape(cwd, '\') . '/', '', '')

  " Update in-memory list
  call filter(g:recent_files_list, 'v:val !=# file')
  call insert(g:recent_files_list, file, 0)
  let g:recent_files_list = g:recent_files_list[0:99]
endfunction

function! RecentFilesPopup() abort
  if empty(g:recent_files_list)
    echo "No recent files"
    return
  endif

  call inputsave()
  let query = input('Recent: ', '', 'customlist,RecentFilesComplete')
  call inputrestore()

  if empty(query)
    return
  endif

  let filtered = matchfuzzy(g:recent_files_list, query)
  if empty(filtered)
    echo "\nNo matches for: " . query
    return
  endif

  if len(filtered) == 1
    execute 'edit' fnameescape(filtered[0])
    return
  endif

  let choices = [printf('Select file (matched %d):', len(filtered))]
  let i = 1
  for f in filtered[0:19]
    call add(choices, printf('%2d. %s', i, f))
    let i += 1
  endfor

  let choice = inputlist(choices)
  if choice >= 1 && choice <= len(filtered)
    execute 'edit' fnameescape(filtered[choice - 1])
  endif
endfunction

function! s:OpenRecent(arg) abort
  if empty(a:arg)
    " No argument provided - open the most recent file other than the current file
    let current = expand('%:p')
    let cwd = getcwd()
    if current =~# '^' . escape(cwd, '\')
      let current = substitute(current, '^' . escape(cwd, '\') . '/', '', '')
    endif

    let all = filter(copy(g:recent_files_list), 'v:val !=# current')

    if !empty(all)
      execute 'edit' fnameescape(all[0])
    else
      echo "No recent files"
    endif
  else
    " Argument provided - find the first match and open it
    let filtered = matchfuzzy(g:recent_files_list, a:arg)
    if !empty(filtered)
      execute 'edit' fnameescape(filtered[0])
    else
      echo "No matches for: " . a:arg
    endif
  endif
endfunction

command! -nargs=? -complete=customlist,RecentFilesComplete Recent call s:OpenRecent(<q-args>)

augroup vimrcRecent
  autocmd!
  autocmd VimEnter * call s:LoadRecentFiles()
  autocmd VimLeavePre * call s:SaveRecentFiles()
  autocmd BufEnter * call s:AddToRecent()
  autocmd CmdlineChanged : if getcmdline() =~# '^Recent\s' | call wildtrigger() | endif
augroup END

nnoremap <leader>re :Recent<space>
