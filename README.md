# vim-reformatdate
カーソル位置の「%Y/%m/%d」の文字列を再フォーマットします。
気が向いたら他のフォーマットにも対応させるかも。

## 例

 "2015/05/31"<br>
 ↓<br>
:call reformatedate#reformat()<br>
 ↓<br>
 "2015/06/01"

## インストール例
~/vim/autoloadにreformatdate.vimを置き、
.vimrcで適当にマッピングを指定してください。

    " 「%Y/%m/%d」の文字列を加算減算
    nnoremap <silent> <C-a> <C-a>:call reformatdate#reformat()<CR>
    nnoremap <silent> <C-x> <C-x>:call reformatdate#reformat()<CR>
    " 「%Y/%m/%d」の文字列を今日の日付に置換
    nnoremap <silent> <F6> :call reformatdate#reformat(localtime())<CR>

