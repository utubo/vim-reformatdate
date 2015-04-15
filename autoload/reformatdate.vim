scriptencoding utf-8
" -------------------------------------------------------------------
" ReformatDate
" 「%Y/%m/%d」の文字列を再フォーマットします。
" 例
" 「2015/05/32」 → 「2015/06/01」
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
" 設定
" 以下のように対応するフォーマットを指定できます。
"
"    let g:reformatdate_formats = ['%Y/%m/%d', '%d-%m-%Y']
"
" 「%Y」と「%d」と「%m」だけ使えます。気が向いたら他にも対応させるかも。
" 「-」区切りだと<C-a>で減算されちゃうけど気になる人は他のプラグイン使えばいいよ
" -------------------------------------------------------------------

function! s:Mlen(str)
	return len(substitute(a:str, '.', 'x', 'g'))
endfunction

function! s:YmdToSec(y, m, d)
	let l:y = a:m < 3 ? a:y - 1 : a:y
	let l:m = a:m < 3 ? 12 + a:m : a:m
	return (365 * l:y + l:y / 4 - l:y / 100 + l:y / 400 + 306 * (l:m + 1) / 10 + a:d - 428 - 719163) * 86400 " 1970/01/01=719163
endfunction

function! s:Init()
	if !exists('g:reformatdate_formats')
		let g:reformatdate_formats = ['%Y/%m/%d', '%d-%m-%Y']
	endif
	if !exists('s:date_names')
		let s:date_names = []
		for l:i in range(0, 6)
			call add(s:date_names, strftime('%a', l:i * 86400))
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
		" 引数で指定された場合
		let l:dt = a:1
	else
		" 「%Y/%m/%d」を辞書に抽出
		let l:ymd = {}
		" デフォ値
		for l:i in ['Y', 'm', 'd']
			let l:ymd[l:i] = str2nr(strftime('%'.l:i))
		endfor
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
		" 1970/01/01からの経過秒に変換
		let l:dt = s:YmdToSec(l:ymd['Y'], l:ymd['m'], l:ymd['d'])
	endif

	" 再フォーマットして置き換え
	let l:cur = getpos('.') " ('.')ノ < Hello !
	call cursor(0, l:start)
	execute 'normal! "_'.s:Mlen(l:ymd_match[0]).'s'.strftime(l:fmt, l:dt)."\<ESC>"
	" 近くに曜日があったらそれも更新する
	for l:i in range(0, 6)
		let l:a_pos = match(getline('.'), s:date_names[i], col('.')) + 1
		if 0 < l:a_pos && l:a_pos < l:start + len(l:ymd_match[0]) + 3
			call cursor(0, l:a_pos)
			execute 'normal! "_'.s:Mlen(s:date_names[i]).'s'.strftime('%a', l:dt)."\<ESC>"
			break
		endif
	endfor

	" カーソル位置を元に戻して終わり
	call setpos('.', l:cur) " ('.')ﾉｼ < bye.
endfunction

