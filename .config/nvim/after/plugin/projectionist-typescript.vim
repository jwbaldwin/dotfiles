if exists('g:loaded_projectionist_typescript')
  finish
endif
let g:loaded_projectionist_typescript = 1

let s:base_dir = resolve(expand("<sfile>:p:h"))
let s:proj_jsn = s:base_dir . "/projections-typescript.json"

function! s:setTypescriptProjections()
  " Skip for special buffer types like oil
  if &filetype ==# 'oil' || expand('%:p') =~# '^oil://'
    return
  endif

  " Find the project root by looking for package.json or tsconfig.json
  let l:file = get(g:, 'projectionist_file', expand('%:p'))
  let l:root = fnamemodify(l:file, ':h')
  
  " Walk up to find project root
  while l:root !=# '/' && l:root !=# ''
    if filereadable(l:root . '/package.json') || filereadable(l:root . '/tsconfig.json')
      break
    endif
    let l:root = fnamemodify(l:root, ':h')
  endwhile
  
  " Only activate for TypeScript/JavaScript projects
  if !filereadable(l:root . '/package.json') && !filereadable(l:root . '/tsconfig.json')
    return
  endif
  
  if filereadable(s:proj_jsn)
    let l:json = readfile(s:proj_jsn)
    let l:dict = projectionist#json_parse(l:json)
    call projectionist#append(l:root, l:dict)
  endif
endfunction

augroup projectionist_typescript
  autocmd!
  autocmd User ProjectionistDetect :call s:setTypescriptProjections()
augroup end
