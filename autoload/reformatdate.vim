function! s:Mlen(str)
  return len(substitute(a:str, '.', 'x', 'g'))
endfunction

function! s:YmdToSec(y, m, d)
  let l:y = a:m < 3 ? a:y - 1 : a:y
  let l:m = a:m < 3 ? 12 + a:m : a:m
  return (365 * l:y + l:y / 4 - l:y / 100 + l:y / 400 + 306 * (l:m + 1) / 10 + a:d - 428 - 719163) * 86400 " 1970/01/01=719163
endfunction

let s:dayNames = []
function! s:Init()
  let g:reformatdate_formats = get(g:, 'reformatdate_formats',['%Y/%m/%d', '%d-%m-%Y'])
  let s:dayNames = get(g:, 'reformatdate_dayNames',[])
  if empty(s:dayNames)
    for l:i in range(0, 6)
      call add(s:dayNames, strftime('%a', l:i * 86400))
    endfor
  endif
endfunction

function! reformatdate#reformat(...)
  call s:Init()
  for l:fmt in g:reformatdate_formats
    let l:reg = substitute(substitute(l:fmt, '%Y', '\\(\\d\\{4}\\)', ''), '%[md]', '\\(\\d\\{1,2}\\)', 'g')
    let l:len = len(substitute(l:fmt, '%Y', '9999', ''))
    let l:start = match(getline('.'), l:reg, col('.') - l:len) + 1
    if 0 < l:start && l:start <= col('.') + l:len
      let l:is_match = 1
      break
    endif
  endfor
  if !exists('l:is_match')
    return
  endif

  let l:ymd_match = matchlist(getline('.'), l:reg, col('.') - l:len)
  if a:0
    " from argument
    let l:date = a:1
  else
    " from current line
    let l:ymd = {}
    " default date
    for l:i in ['Y', 'm', 'd']
      let l:ymd[l:i] = str2nr(strftime('%'.l:i))
    endfor
    " grep yyyymmdd
    let l:index = 0
    let l:offset = -1
    while 1
      let l:offset = match(l:fmt, '%\zs[Ymd]', l:offset + 1)
      if 0 < l:offset
        let l:index += 1
        let l:ymd[l:fmt[l:offset]] = str2nr(l:ymd_match[l:index])
      else
        break
      endif
    endwhile
    let l:date = s:YmdToSec(l:ymd['Y'], l:ymd['m'], l:ymd['d'])
  endif

  " reformat !
  let l:cur = getpos('.') " ('.')/ < Hello !
  call cursor(0, l:start)
  execute 'normal! "_'.s:Mlen(l:ymd_match[0]).'s'.strftime(l:fmt, l:date)."\<ESC>"

  " support day name
  for l:name in  s:dayNames
    let l:a_pos = match(getline('.'), l:name, col('.')) + 1
    if 0 < l:a_pos && l:a_pos < l:start + len(l:ymd_match[0]) + 3
      call cursor(0, l:a_pos)
      execute 'normal! "_'.s:Mlen(l:name).'s'.strftime('%a', l:date)."\<ESC>"
      break
    endif
  endfor

  " complete
  call setpos('.', l:cur) " ('.')/ < bye.
endfunction

