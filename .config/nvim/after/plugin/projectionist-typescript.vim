if exists('g:loaded_projectionist_typescript')
  finish
endif
let g:loaded_projectionist_typescript = 1

let s:base_dir = resolve(expand("<sfile>:p:h"))
let s:proj_jsn = s:base_dir . "/projections-typescript.json"

function! s:setTypescriptProjections()
  " Only activate for TypeScript/JavaScript projects
  if !filereadable('package.json') && !filereadable('tsconfig.json')
    return
  endif
  
  if filereadable(s:proj_jsn)
    let l:json = readfile(s:proj_jsn)
    let l:dict = projectionist#json_parse(l:json)
    call projectionist#append(getcwd(), l:dict)
  endif
endfunction

augroup projectionist_typescript
  autocmd!
  autocmd User ProjectionistDetect :call s:setTypescriptProjections()
augroup end
