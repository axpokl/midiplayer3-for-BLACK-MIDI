const find_max=$10000;
var find_info:TSearchRec;
var find_count:longword;
var find_current:longword;
var find_result:array[0..find_max] of ansistring;

procedure find_file(s:ansistring);
var dir:ansistring;
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
  dir:=ExtractFilePath(s);
  if findfirst(dir+'*',0,find_info)=0 then
    begin
    find_count:=find_count+1;
    find_result[find_count]:=dir+find_info.name;
    if find_result[find_count]=s then find_current:=find_count;
    while findnext(find_info)=0 do
      begin
      find_count:=find_count+1;
      find_result[find_count]:=dir+find_info.name;
      if find_result[find_count]=s then find_current:=find_count;
      end;
    end;
  end;
end;

function get_file(n:longword):ansistring;
begin
if n<1 then n:=n+find_count;
if n>find_count then n:=n-find_count;
find_current:=n;
get_file:=find_result[find_current];
end;
