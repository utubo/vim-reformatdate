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
nnoremap <silent> <C-a> :<C-u>call reformatdate#inc(v:count)<CR>
nnoremap <silent> <C-x> :<C-u>call reformatdate#dec(v:count)<CR>
```
- Note
  - If sepalator is `-`, then `<C-a>` will decrement days.


## Options
```vim
" The support formats
" Default is
let g:reformatdate_formats = [
  \'%Y/%m/%d',
  \'%d-%m-%Y',
  \'%B %dth, %Y',
  \'%A',
  \'%a',
  \'%B',
  \'%b',
  \]
]
```
- Note
  - You can use `%Y`, `%m`, `%d`, `%a`, `%A`, `%b`, `%B`

