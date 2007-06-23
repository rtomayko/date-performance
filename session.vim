let s:project_dir = expand('<sfile>:h')
execute 'chdir '.s:project_dir
let &g:path = &g:path.s:project_dir.'/lib/**,'.s:project_dir.'/app/**,'
set suffixesadd+=.rb
set includeexpr+=substitute(v:fname,'s$','','g')
set includeexpr+=substitute(v:fname,'ies$','y','g')
set tags=tags;/
echo 'project loaded: '.s:project_dir
