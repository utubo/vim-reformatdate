# vim-reformatdate
You can reformat yyyy/mm/dd on cursor.

## Example
- Before
  ```
  2015/05/32(Sun)
  ```
- Reformat
  ```vim
  :call reformatedate#reformat()
  ```
- After
  ```
  2015/06/01(Mon)
  ```

## Install
```vim
call dein('utubo/vim-reformatdate')

" Reformat
nnoremap <silent> <F5> :call reformatdate#reformat()<CR>

" Reset to today
nnoremap <silent> <F6> :call reformatdate#reformat(localtime())<CR>

" Increment/Decrement days
nnoremap <silent> <C-a> <C-a>:call reformatdate#reformat()<CR>
nnoremap <silent> <C-x> <C-x>:call reformatdate#reformat()<CR>
```
- Note
  - If sepalator is `-`, then `<C-a>` will decrement days.


## Options
```vim
" The support formats
let g:reformatdate_formats = ['%Y/%m/%d', '%d-%m-%Y']
```
- Note
  - You can use `%Y`, `%m` and `%d` only.


