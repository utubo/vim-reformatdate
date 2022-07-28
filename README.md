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


## Settings
### Support formats
```vim
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

" You can add formats
" Example
let g:reformatdate_extend_formats = [
  \'%Y',
  \]
```
- Note
  - You can use `%Y`, `%m`, `%d`, `%a`, `%A`, `%b`, `%B`

### Day names and Months names
```vim
" Default depends on locale
" Example
echo g:reformatdate_names
[{
  \'a': ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
  \'b': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  \'A': ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
  \'B': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
  \}]
" You can add formats
" Example
let g:reformatdate_extend_names = [{
  \'a': ['日', '月', '火', '水', '木', '金', '土'],
  \'A': ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'],
  \}, {
  \'a': ['S', 'M', 'T', 'W', 'H', 'F', 'A'],
  \}]
```

### Init

If you change the settings after execute reformat, you must call `init()`.

```vim
call reformatdate#init()
```

