let s:DEFAULT_FORMATS = [
      \'%Y/%m/%d', '%d-%m-%Y', '%B %dth, %Y',
      \'%A', '%a', '%B', '%b',
      \]
let s:NAME_KEYS = ['A', 'a', 'B', 'b']
let s:dayname_search_range = 3
let s:fmt = []
let s:names_list = []
let s:inited = 0

" Utils
function! s:YmdToSec(y, m, d) abort
  let l:y = a:m < 3 ? a:y - 1 : a:y
  let l:m = a:m < 3 ? 12 + a:m : a:m
  return (365 * l:y + l:y / 4 - l:y / 100 + l:y / 400 + 306 * (l:m + 1) / 10 + a:d - 428 - 719163) * 86400 " 1970/01/01=719163
endfunction

function! s:Strftime(fmt, date, names = {}) abort
  let l:str = a:fmt
  for [l:k, l:v] in items(a:names)
    if l:k ==# 'A' || l:k ==# 'a'
      let l:i = str2nr(strftime('%w', a:date))
    else
      let l:i = str2nr(strftime('%m', a:date)) - 1
    endif
    let l:str = l:str->substitute('%' . l:k, a:names[l:k][l:i], 'g')
  endfor
  if stridx(a:fmt, '%dth')
    let l:dth = strftime('%dth', a:date)
          \->substitute('^0', '', '')
          \->substitute('^1th', '1st', '')
          \->substitute('^2th', '2nd', '')
          \->substitute('^3th', '3rd', '')
    let l:str = l:str->substitute('%dth', l:dth, 'g')
  endif
  for l:i in ['%Y', '%m', '%d', '%A', '%B', '%a', '%b']
    let l:str = l:str->substitute(l:i, strftime(l:i, a:date), 'g')
  endfor
  return l:str
endfunction

function! s:FindNames(a, name) abort
  for l:names in s:names_list
    if has_key(l:names, a:a) && index(l:names[a:a], a:name) !=# -1
      return l:names[a:a]
    endif
  endfor
  return []
endfunction

function! s:IncDec(inc)
  if a:inc > 0
    execute "normal! " . string(a:inc) . "\<C-a>"
  elseif a:inc < 0
    execute "normal! " . string(-a:inc) . "\<C-x>"
  endif
endfunction

" Initialize
function! reformatdate#init() abort
  call s:InitNames()
  call s:InitFormats()
  let s:inited = 1
endfunction

function! s:InitNames() abort
  if exists('g:reformatdate_names')
    let s:names_list = copy(g:reformatdate_names)
  else
    let s:names_list = [{
          \'a': ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
          \'b': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
          \'A': ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
          \'B': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
          \}]
    " System locale
    if strftime('%a') !=# 'Thu'
      call s:AddDefaultNames()
    endif
    let g:reformatdate_names = s:names_list
  endif
  let s:names_list += get(g:, 'reformatdate_extend_names', [])
  " Patterns
  let s:names_pat = {}
  for l:key in s:NAME_KEYS
    let l:all = []
    for l:n in s:names_list
      if has_key(l:n, l:key)
        let l:all += l:n[l:key]
      endif
    endfor
    let l:all = l:all->sort()->uniq()
    let s:names_pat[l:key]  = '\\(' . join(l:all, '\\|') . '\\)'
  endfor
endfunction

function! s:AddDefaultNames() abort
  let l:names = { 'a': [], 'A': [], 'b': [], 'B': [] }
  for l:i in range(3, 9) " from Sun to Sat
    call add(l:names.a, strftime('%a', l:i * 86400))
    call add(l:names.A, strftime('%A', l:i * 86400))
  endfor
  for l:i in range(0, 11)
    let l:m = l:i * 86400 * 31
    call add(l:names.b, strftime('%b', l:m))
    call add(l:names.B, strftime('%B', l:m))
  endfor
  call add(s:names_list, l:names)
endfunction

function! s:InitFormats() abort
  let g:reformatdate_formats = get(g:, 'reformatdate_formats', s:DEFAULT_FORMATS)
  let g:reformatdate_extend_formats = get(g:, 'reformatdate_extend_formats', [])
  let s:fmt = []
  let l:sorted = (g:reformatdate_formats + g:reformatdate_extend_formats)
        \->sort({a, b -> strcharlen(strftime(b)) - strcharlen(strftime(a))})
        \->uniq()
  for l:fmt in l:sorted
    let l:pat = l:fmt
          \->substitute('%Y', '\\(\\d\\{4}\\)', '')
          \->substitute('%dth', '\\(\\d\\{1,2}\\)\\%(th\\|st\\|nd\\|rd\\)', 'g')
          \->substitute('%[md]', '\\(\\d\\{1,2}\\)', 'g')
    for l:i in s:NAME_KEYS
      let l:pat = l:pat->substitute('%' . l:i, s:names_pat[l:i], 'g')
    endfor
    call add(s:fmt, { 'fmt': l:fmt, 'pat': l:pat })
  endfor
endfunction

" Reformat
function s:FindFmt() abort
  let l:cur = getpos('.')
  for l:fmt in s:fmt
    let l:p = '\V' . l:fmt.pat . '\C'
    if search(l:p, 'bc', cur[1]) ==# 0
      continue
    endif
    let l:start = col('.')
    call search(l:p, 'ce', cur[1])
    if l:cur[2] <= col('.')
      call setpos('.', l:cur)
      return [l:fmt, l:start]
    endif
    call setpos('.', l:cur)
  endfor
  return [{}, 0]
endfunction

function! reformatdate#reformat(date = '.', inc = 0) abort
  if ! s:inited
    call reformatdate#init()
  endif

  let [l:fmt, l:start] = s:FindFmt()
  if l:start ==# 0
    call s:IncDec(a:inc)
    return
  endif

  " inc/dec the number
  if a:inc !=# 0 && expand('<cword>') =~# '^[0-9-]'
    if expand('<cword>') =~# '[^0-9]'
      normal! eb
    endif
    call s:IncDec(a:inc)
  endif

  let l:ymd_match = matchlist(getline('.'), l:fmt.pat, l:start - 1)

  if len(l:ymd_match) ==# 0 || l:ymd_match[0] =~# '^[0-9-]*$'
    return
  endif

  " from cursorpos
  let l:ymd = { 'Y': strftime('%Y'), 'm': strftime('%m'), 'd': strftime('%d') }
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
  let l:names = {}
  for l:b in ['B', 'b']
    if has_key(ymd, l:b)
      let l:names[l:b] = s:FindNames(l:b, ymd[l:b])
      let l:ymd.m = index(l:names[l:b], l:ymd[l:b]) + 1
    endif
  endfor
  for l:a in ['A', 'a']
    if has_key(ymd, l:a) && l:fmt.fmt !~# '%[YmdbB]'
      let l:names[l:a] = s:FindNames(l:a, ymd[l:a])
      let l:ymd.d += index(l:names[l:a], l:ymd[l:a]) - str2nr(strftime('%w'))
    endif
  endfor

  " support inc/dec a name
  if a:inc !=# 0
    let l:cw = expand('<cword>')
    for l:k in keys(l:names)
      if index(l:names[l:k], l:cw) !=# -1
        if l:k ==# 'b' || l:k ==# 'B'
          let l:ymd.m += a:inc
        else
          let l:ymd.d += a:inc
        endif
        break
      endif
    endfor
  endif

  " truncate days to prevent e.g. today=7/29, fmt=%m, before=02, after=03
  if l:fmt.fmt !~# '%[daA]'
    let l:ymd.d = 1
  endif

  if a:date ==# '.'
    let l:date = s:YmdToSec(l:ymd.Y, l:ymd.m, l:ymd.d)
  else
    let l:date = a:date
  endif

  " reformat !
  let l:str = s:Strftime(l:fmt.fmt, l:date, l:names)
  let l:cur = getpos('.') " ('.')/ < Hello !
  call cursor(0, l:start)
  execute 'normal! "_' . strcharlen(l:ymd_match[0]) . 's' . l:str . "\<ESC>"

  " support auto day name
  if l:fmt.fmt !~# '%a\|%A'
    for l:key in ['A', 'a']
      for l:names in s:names_list
        if ! has_key(l:names, l:key)
          continue
        endif
        for l:name in l:names[l:key]
          let l:a_pos = match(getline('.'), l:name, col('.')) + 1
          if 0 < l:a_pos && l:a_pos < l:start + len(l:ymd_match[0]) + s:dayname_search_range
            let l:s = s:Strftime('%' . l:key, l:date, l:names)
            call cursor(0, l:a_pos)
            execute 'normal! "_' . strcharlen(l:name) . 's' . l:s . "\<ESC>"
            break
          endif
        endfor
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

