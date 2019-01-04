let SessionLoad = 1
if &cp | set nocp | endif
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/xueyp.github.io/_posts
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +0 ~/xueyp.github.io/_posts/2018-12-26-大数据-日志采集和转发rsyslog-auditd.markdown
badd +279 ~/xueyp.github.io/_posts/2019-01-04-大数据-Flume到kafka.markdown
badd +1 ~/xueyp.github.io/_posts/\*01-04
argglobal
silent! argdel *
$argadd 2018-12-26-大数据-日志采集和转发rsyslog-auditd.markdown
edit ~/xueyp.github.io/_posts/2018-12-26-大数据-日志采集和转发rsyslog-auditd.markdown
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
setlocal fdm=manual
setlocal fde=Foldexpr_markdown(v:lnum)
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal nofen
silent! normal! zE
7,9fold
7,9fold
10,10fold
11,55fold
56,56fold
61,108fold
110,150fold
152,164fold
166,196fold
57,196fold
197,197fold
198,444fold
7
normal! zo
7
normal! zc
57
normal! zo
166
normal! zo
let s:l = 159 - ((29 * winheight(0) + 26) / 52)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
159
normal! 0102|
tabnext 1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToOc
set winminheight=1 winminwidth=1
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
