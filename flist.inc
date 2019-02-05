const find_max=$10000;
var find_handle:handle;
var find_info:WIN32_FIND_DATAW;
var find_count:longword;
var find_current:longword;
var find_result:array[0..find_max] of unicodestring;
var find_dir:unicodestring;

procedure add_file(s:unicodestring);
begin
if (find_info.cFilename<>'.') and (find_info.cFilename<>'..') then
  begin
  find_count:=find_count+1;
  find_result[find_count]:=find_dir+UnicodeString(find_info.cFilename);
  if find_result[find_count]=s then find_current:=find_count;
  end;
end;

procedure find_file(s:unicodestring);
begin
find_current:=0;
find_result[0]:='';
repeat
find_current:=find_current+1;
if find_current>find_count then break;
until find_result[find_current]=s;
if find_current>find_count then
  begin
  find_count:=0;
  find_dir:=GetFileDirW(s);
  find_handle:=FindFirstFileW(PWideChar(find_dir+'*'),find_info);
  if find_handle<>INVALID_HANDLE_VALUE then
    begin
    add_file(s);
    while FindNextFileW(find_handle,find_info) do add_file(s);
    end;
  end;
end;

function get_file(n:longword):unicodestring;
begin
if n<1 then n:=n+find_count;
if n>find_count then n:=n-find_count;
find_current:=n;
get_file:=find_result[find_current];
end;
