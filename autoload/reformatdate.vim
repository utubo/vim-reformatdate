let s:default_formats = [
      \'%Y/%m/%d',
      \'%d-%m-%Y',
      \'%B %dth, %Y',
      \'%A',
      \'%a',
      \'%B',
      \'%b',
      \]
function! s:Mlen(str) abort
  return len(substitute(a:str, '.', 'x', 'g'))
endfunction

function! s:YmdToSec(y, m, d) abort
  let l:y = a:m < 3 ? a:y - 1 : a:y
  let l:m = a:m < 3 ? 12 + a:m : a:m
  return (365 * l:y + l:y / 4 - l:y / 100 + l:y / 400 + 306 * (l:m + 1) / 10 + a:d - 428 - 719163) * 86400 " 1970/01/01=719163
endfunction

let s:fmt_cache = ''
let s:fmt = []
let s:names = {}
let s:dayname_search_range = 3
function! reformatdate#init() abort
  " names
  if empty(s:names)
    call s:InitNames()
  endif
  call extend(s:names, get(g:, 'reformatdate_names', {}))
  let g:reformatdate_names = s:names
  " formats
  let g:reformatdate_formats = get(g:, 'reformatdate_formats', s:default_formats)
  let l:fmt_cache = join(g:reformatdate_formats, '\n')
  if s:fmt_cache !=# l:fmt_cache
    call s:InitFormats(l:fmt_cache)
  endif
endfunction

function! s:InitNames() abort
  let s:names.a = []
  let s:names.A = []
  let s:names.b = []
  let s:names.B = []
  for l:i in range(3, 9) " Sun to Sat
    call add(s:names.a, strftime('%a', l:i * 86400))
    call add(s:names.A, strftime('%A', l:i * 86400))
  endfor
  for l:i in range(1, 12)
    let l:m = strptime('%m/%d/%Y', string(l:i) . '/01/2000')
    call add(s:names.b, strftime('%b', l:m))
    call add(s:names.B, strftime('%B', l:m))
  endfor
endfunction

function! s:InitFormats(new_cache) abort
  let s:fmt_cache = a:new_cache
  let s:fmt = []
  let sorted = g:reformatdate_formats
        \->sort({a, b -> len(strftime(b)) - len(strftime(a))})
        \->uniq()
  for l:fmt in sorted
    let l:pat = l:fmt
          \->substitute('%Y', '\\(\\d\\{4}\\)', '')
          \->substitute('%dth', '\\(\\d\\{1,2}\\)\\%(th\\|st\\|nd\\|rd\\)', 'g')
          \->substitute('%[md]', '\\(\\d\\{1,2}\\)', 'g')
    for l:i in ['a', 'A', 'b', 'B']
      let l:pat = l:pat->substitute('%' . l:i, '\\(' . join(s:names[l:i], '\\|') . '\\)', 'g')
    endfor
    call add(s:fmt, { 'fmt': l:fmt, 'pat': l:pat, 'len': len(strftime(l:fmt)) })
  endfor
endfunction

function! s:IncDec(inc = 0)
  if a:inc > 0
    execute "normal! " . string(a:inc) . "\<C-a>"
  elseif a:inc < 0
    execute "normal! " . string(-a:inc) . "\<C-x>"
  endif
endfunction

function s:FindFmt() abort
  let l:line = getline('.')
  let l:col = col('.')
  let l:start = 0
  for l:fmt in s:fmt
    let l:start = match(l:line, l:fmt.pat, max([0, l:col - l:fmt.len])) + 1
    if l:start !=# 0
      break
    endif
  endfor
  if l:start ==# 0 || l:start + l:fmt.len < l:col || l:col < l:start
    return [{}, -1]
  else
    return [l:fmt, l:start]
  endif
endfunction

function! reformatdate#reformat(date = '.', inc = 0) abort
  call reformatdate#init()
  let [l:fmt, l:start] = s:FindFmt()
  if l:start ==# -1
    call s:IncDec(a:inc)
    return
  endif

  " inc/dec the number
  if a:inc !=# 0 && expand('<cword>') =~# '^[0-9-]'
    call s:IncDec(a:inc)
  endif

  let l:ymd_match = matchlist(getline('.'), l:fmt.pat, l:start - 1)

  if a:date !=# '.'
    " from argument
    let l:date = a:date
  else
    " from cursorpos
    let l:ymd = {
          \'Y': strftime('%Y'), 'm': strftime('%m'), 'd': strftime('%d'),
          \'a': '', 'A': '', 'b': '', 'B': '', 'dth': '',
          \}
    let l:index = 0
    let l:offset = -1
    while 1
      let l:offset = match(l:fmt.fmt, '%\zs[YmdaAbB]', l:offset + 1)
      if 0 < l:offset
        let l:index += 1
        let l:ymd[l:fmt.fmt[l:offset]] = l:ymd_match[l:index]
      else
        break
      endif
    endwhile
    let ymd.Y = str2nr(ymd.Y)
    let ymd.m = str2nr(ymd.m)
    let ymd.d = str2nr(ymd.d)

    " names
    if ymd.b !=# ''
      let l:ymd.m = index(s:names.b, l:ymd.b) + 1
    endif
    if ymd.B !=# ''
      let l:ymd.m = index(s:names.B, l:ymd.B) + 1
    endif
    if ymd.a !=# '' && l:fmt.fmt !~# '%[YmdbB]'
      let l:ymd.d += index(s:names.a, l:ymd.a) - index(s:names.a, strftime('%a'))
    endif
    if ymd.A !=# '' && l:fmt.fmt !~# '%[YmdbB]'
      let l:ymd.d += index(s:names.A, l:ymd.A) - index(s:names.A, strftime('%A'))
    endif

    " support inc/dec a name
    if a:inc !=# 0
      let l:cw = expand('<cword>')
      if index(s:names.b, l:cw) !=# -1 || index(s:names.B, l:cw) !=# -1
        let l:ymd.m += a:inc
      elseif index(s:names.a, l:cw) !=# -1 || index(s:names.A, l:cw) !=# -1
        let l:ymd.d += a:inc
      endif
    endif

    let l:date = s:YmdToSec(l:ymd['Y'], l:ymd['m'], l:ymd['d'])
  endif

  " reformat !
  let l:str = strftime(l:fmt.fmt, l:date)
  if stridx(l:fmt.fmt, '%dth')
    let l:str = l:str
          \->substitute('\<0\(\d\)th', '\1th', 'g')
          \->substitute('\<1th', '1st', 'g')
          \->substitute('\<2th', '2nd', 'g')
          \->substitute('\<3th', '3rd', 'g')
  endif
  let l:cur = getpos('.') " ('.')/ < Hello !
  call cursor(0, l:start)
  execute 'normal! "_'.s:Mlen(l:ymd_match[0]).'s'.l:str."\<ESC>"

  " support auto day name
  if l:fmt.fmt !~# '%a\|%A'
    for l:names in [s:names.A, s:names.a]
      for l:name in l:names
        let l:a_pos = match(getline('.'), l:name, col('.')) + 1
        if 0 < l:a_pos && l:a_pos < l:start + len(l:ymd_match[0]) + s:dayname_search_range
          call cursor(0, l:a_pos)
          execute 'normal! "_'.s:Mlen(l:name).'s'.strftime('%a', l:date)."\<ESC>"
          break
        endif
      endfor
    endfor
  endif

  " complete
  call setpos('.', l:cur) " ('.')/ < bye.
endfunction

function! reformatdate#inc(count) abort
  call reformatdate#reformat('.', max([1, a:count]))
endfunction

function! reformatdate#dec(count) abort
  call reformatdate#reformat('.', - max([1, a:count]))
endfunction

