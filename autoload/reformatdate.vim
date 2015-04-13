" -------------------------------------------------------------------
" ReformatDate
" 「%Y/%m/%d」の文字列を再フォーマットします。
" 例
" 「2015/05/32」 → 「2015/06/01」
" 気が向いたら他のフォーマットにも対応させるかも。
"
" インストール例
" ~/vim/autoloadにreformatdate.vimを置き、.vimrcで適当にマッピングを
" 指定してください。
"
"    " 「%Y/%m/%d」の文字列を加算減算
"    nnoremap <silent> <C-a> <C-a>:call reformatdate#reformat()<CR>
"    nnoremap <silent> <C-x> <C-x>:call reformatdate#reformat()<CR>
"    " 「%Y/%m/%d」の文字列を今日の日付に置換
"    nnoremap <silent> <F6> :call reformatdate#reformat(localtime())<CR>
"
" -------------------------------------------------------------------

function! s:Mlen(str)
	return len(substitute(a:str, '.', 'x', 'g'))
endfunction

function! s:YmdToSec(y, m, d)
	let l:y = a:m < 3 ? a:y - 1 : a:y
	let l:m = a:m < 3 ? 12 + a:m : a:m
	return (365 * l:y + l:y / 4 - l:y / 100 + l:y / 400 + 306 * (l:m + 1) / 10 + a:d - 428 - 719163) * 86400 " 1970/01/01=719163
endfunction

function! reformatdate#reformat(...)
	let ymd_reg = '\<\(\d\{4}\)/\(\d\{1,3}\)/\(\d\{1,3}\)'
	let l:start = match(getline('.'), l:ymd_reg, col('.') - 12) + 1
	if l:start < 1 || col('.') + 12 < l:start
		return
	endif
	" 「%Y/%m/%d」を抽出して1970/01/01からの経過秒に変換
	let l:ymd = matchlist(getline('.'), l:ymd_reg, col('.') - 12)
	let l:dt = a:0 != 0 ? a:1 : s:YmdToSec(str2nr(l:ymd[1]), str2nr(l:ymd[2]), str2nr(l:ymd[3]))
	" 再フォーマットして置き換え
	let l:cur = getpos('.') " ('.')ノ < Hello !
	call cursor(0, l:start)
	execute 'normal "_'.s:Mlen(l:ymd[0]).'s'.strftime('%Y/%m/%d', l:dt)."\<ESC>"
	" 近くに曜日があったらそれも更新する
	for l:i in range(0, 6)
		let l:a = strftime('%a', l:i * 86400)
		let l:a_pos = match(getline('.'), l:a, col('.')) + 1
		if 0 < l:a_pos && l:a_pos < col('.') + 3
			call cursor(0, l:a_pos)
			execute 'normal "_'.s:Mlen(l:a).'s'.strftime('%a', l:dt)."\<ESC>"
			break
		endif
	endfor
	" カーソル位置を元に戻して終わり
	call setpos('.', l:cur) " ('.')ﾉｼ < bye.
endfunction

