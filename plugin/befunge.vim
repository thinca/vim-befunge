" Befunge interpreter.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

if exists('g:loaded_befunge')
  finish
endif
let g:loaded_befunge = 1

let s:save_cpo = &cpo
set cpo&vim


function! s:pospat(pos)  " {{{2
  return '\%' . (a:pos[0] + 1) . 'c\%' . (a:pos[1] + 1) . 'l'
endfunction


function! s:run(verbose)  " {{{2
  let bef = befunge#new()
  if !a:verbose
    call bef.run(getline(0, '$'))
    return
  endif
  let source = getline(0, '$')
  call bef.set_source(source)
  new
  silent 0 put =source
  silent $ put =['', '------', '', '', '']

  let bef.stline = line('$') - 1
  function! bef.stack_changed(inc)  " {{{2
    call setline(self.stline, 'stack: ' . string(self.stack))
  endfunction

  let bef.outline = line('$')
  function! bef.write(c)  " {{{2
    if a:c == "\n"
      silent $ put =[]
      let self.outline = line('$')
    else
      call setline(self.outline, getline(self.outline) . a:c)
    endif
  endfunction

  function! bef.code_changed(pos, v)  " {{{2
    let line = split(getline(a:pos[1] + 1), '.\zs')
    let line[a:pos[0]] = nr2char(a:v)
    call setline(a:pos[1] + 1, join(line, ''))
  endfunction

  let mid = matchadd('Todo', s:pospat(bef.pos))
  let bef.running = 1
  while bef.running
    call bef.step()
    call cursor(bef.pos[1] + 1, bef.pos[0] + 1)
    call matchdelete(mid)
    let mid = matchadd('Todo', s:pospat(bef.pos))
    $
    redraw
    if bef.getch(bef.pos) != ' '
      sleep 500m
    endif
  endwhile
endfunction


command! -bang -bar Befunge call s:run(<bang>0)

let &cpo = s:save_cpo
unlet s:save_cpo
