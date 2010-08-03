" Befunge interpreter.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim


function! befunge#new(...)  " {{{2
  return copy(s:Befunge).init()
endfunction



let s:dir = {
\ 'left': [-1, 0],
\ 'right': [1, 0],
\ 'up': [0, -1],
\ 'down': [0, 1],
\ }

let s:Operator = {}

let s:Befunge = {}

function! s:Befunge.run(source)  " {{{2
  call self.init()
  call self.set_source(a:source)
  let self.running = 1
  while self.running
    call self.step()
  endwhile
endfunction

function! s:Befunge.init()  " {{{2
  let self.pos = [0, 0]
  let self.dir = s:dir.right
  let self.running = 0
  let self.stack = []
  let self.operator = s:Operator
  return self
endfunction

function! s:Befunge.set_source(source)  " {{{2
  if self.running
    return
  endif

  let source = type(a:source) == type([]) ? copy(a:source)
  \                                       : split(a:source, "\n")

  let width = 0
  let height = len(source)
  for line in source
    let len = strlen(line)
    if width < len
      let width = len
    endif
  endfor

  for i in range(len(source))
    let source[i] = split(source[i] . repeat(' ', width - strlen(source[i])),
    \                     '.\zs')
  endfor

  let self.source = source
  let self.max = [width, height]
endfunction

function! s:Befunge.step()  " {{{2
  call self.execute(self.getch(self.pos))
  if self.running
    call self.move()
  endif
endfunction

function! s:Befunge.getch(pos)  " {{{2
  let len = len(a:pos)
  let s = self.source
  while 1 < len
    let len -= 1
    let s = s[a:pos[len]]
  endwhile
  return s[a:pos[0]]
endfunction

function! s:Befunge.setch(pos, v)  " {{{2
  let len = len(a:pos)
  let s = self.source
  while 1 < len
    let len -= 1
    let s = s[a:pos[len]]
  endwhile
  let s[a:pos[0]] = a:v
  call self.code_changed(a:pos, a:v)
endfunction

function! s:Befunge.read()  " {{{2
  let c = getchar()
  return type(c) == type(0) ? nr2char(c) : c
endfunction

function! s:Befunge.read_num()  " {{{2
  return input('number:') - 0
endfunction

function! s:Befunge.write(c)  " {{{2
  echon a:c
endfunction

function! s:Befunge.move(...)  " {{{2
  let dir = a:0 ? a:1 : self.dir
  let pos = self.pos
  for i in range(len(pos))
    let pos[i] += dir[i]
    if self.max[i] <= pos[i]
      let pos[i] = 0
    elseif pos[i] < 0
      let pos[i] = self.max[i] - 1
    endif
  endfor
endfunction

function! s:Befunge.pop()  " {{{2
  if empty(self.stack)
    throw 'befunge: Empty stack'
  endif
  let r = remove(self.stack, -1)
  call self.stack_changed(0)
  return r
endfunction

function! s:Befunge.push(d)  " {{{2
  call add(self.stack, type(a:d) == type(0) ? a:d : char2nr(a:d))
  call self.stack_changed(1)
endfunction

function! s:Befunge.code_changed(pos, v)  " {{{2
endfunction

function! s:Befunge.stack_changed(inc)  " {{{2
endfunction

function! s:Befunge.execute(op)  " {{{2
  call self.operator.execute(self, a:op)
endfunction


" Default operator.
function! s:Operator.execute(bef, op)  " {{{2
  let bef = a:bef
  if a:op ==# '<'
    let bef.dir = s:dir.left
  elseif a:op ==# '>'
    let bef.dir = s:dir.right
  elseif a:op ==# '^'
    let bef.dir = s:dir.up
  elseif a:op ==# 'v'
    let bef.dir = s:dir.down
  elseif a:op ==# '_'
    let bef.dir = bef.pop() ? s:dir.left : s:dir.right
  elseif a:op ==# '|'
    let bef.dir = bef.pop() ? s:dir.up : s:dir.down
  elseif a:op ==# '?'
    " XXX: cheat random
    let bef.dir = values(s:dir)[reltime()[1] % 4]
  elseif a:op ==# ' '
  elseif a:op ==# '#'
    let fake_operator = {}
    function fake_operator.execute(bef, op)
      let a:bef.operator = self.origin
    endfunction
    let fake_operator.origin = self
    let bef.operator = fake_operator
  elseif a:op ==# '@'
    let bef.running = 0
  elseif a:op =~# '\d'
    call bef.push(a:op - 0)
  elseif a:op ==# '"'
    let ascii_operator = {}
    function ascii_operator.execute(bef, op)
      if a:op ==# '"'
        let a:bef.operator = self.origin
      else
        call a:bef.push(a:op)
      endif
    endfunction
    let ascii_operator.origin = self
    let bef.operator = ascii_operator
  elseif a:op ==# '&'
    call a:bef.push(a:bef.read_num())
  elseif a:op ==# '~'
    call a:bef.push(a:bef.read())
  elseif a:op ==# '.'
    call a:bef.write(a:bef.pop() . ' ')
  elseif a:op ==# ','
    call a:bef.write(nr2char(a:bef.pop()))
  elseif a:op ==# '+'
    let y = a:bef.pop()
    let x = a:bef.pop()
    call a:bef.push(x + y)
  elseif a:op ==# '-'
    let y = a:bef.pop()
    let x = a:bef.pop()
    call a:bef.push(x - y)
  elseif a:op ==# '*'
    let y = a:bef.pop()
    let x = a:bef.pop()
    call a:bef.push(x * y)
  elseif a:op ==# '/'
    let y = a:bef.pop()
    let x = a:bef.pop()
    call a:bef.push(x / y)
  elseif a:op ==# '%'
    let y = a:bef.pop()
    let x = a:bef.pop()
    call a:bef.push(x % y)
  elseif a:op ==# '`'
    let y = a:bef.pop()
    let x = a:bef.pop()
    call a:bef.push(x > y)
  elseif a:op ==# '!'
    call a:bef.push(!a:bef.pop())
  elseif a:op ==# ':'
    let x = a:bef.pop()
    call a:bef.push(x)
    call a:bef.push(x)
  elseif a:op ==# '\'
    let y = a:bef.pop()
    let x = a:bef.pop()
    call a:bef.push(y)
    call a:bef.push(x)
  elseif a:op ==# '$'
    call a:bef.pop()
  elseif a:op ==# 'g'
    let y = a:bef.pop()
    let x = a:bef.pop()
    call a:bef.push(a:bef.getch([x, y]))
  elseif a:op ==# 'p'
    let y = a:bef.pop()
    let x = a:bef.pop()
    let v = a:bef.pop()
    call a:bef.setch([x, y], v)
  else
    throw 'befunge: Unknown operator: ' . a:op
  endif
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
