const maxfnoten0=16;
const maxfnoten=1 shl maxfnoten0;
var fnote:file of tnotemap;
var fnotew:boolean;
var bfnote:array[0..maxfnoten-1]of tnotemap;
var bfnote_:array[0..maxfnoten-1]of tnotemap;
var bifnote,bjfnote:longint;

procedure FlushFNote();inline;
begin
if bjfnote>=0 then
  begin
  seek(fnote,bjfnote shl maxfnoten0);
  blockwrite(fnote,bfnote,maxfnoten);
  end;
end;

procedure GetFNoteBlock(i:longint);inline;
begin
if bjfnote<>i shr maxfnoten0 then
  begin
  if fnotew then FlushFNote();
  bjfnote:=i shr maxfnoten0;
  if fnotew then
    if filesize(fnote)<=(bjfnote shl maxfnoten0) then
      begin
      seek(fnote,bjfnote shl maxfnoten0);
      blockwrite(fnote,bfnote_,maxfnoten);
      end;
  seek(fnote,bjfnote shl maxfnoten0);
  blockread(fnote,bfnote,maxfnoten);
  end;
end;

function GetFNote(i:longint):tnotemap;inline;
begin
if fb then
  begin
  GetFNoteBlock(i);
  bifnote:=i and (maxfnoten-1);
  GetFNote:=bfnote[bifnote];
  end
else
  GetFNote:=notemap[i];
end;

procedure SetFNote(e:tnotemap;i:longint);inline;
begin
if fb then
  begin
  GetFNoteBlock(i);
  bifnote:=i and (maxfnoten-1);
  bfnote[bifnote]:=e;
  end
else
  notemap[i]:=e;
end;

procedure SetFNoteNote1(i:longint;note1:double);inline;
var e:tnotemap;
begin
e:=GetFNote(i);
if e.note1<>note1 then
  begin
  e.note1:=note1;
  SetFNote(e,i);
  end;
end;

function GetFNoteNote1(i:longint):double;inline;
var e:tnotemap;
begin
e:=GetFNote(i);
GetFNoteNote1:=e.note1;
end;

const maxnotemapdraw=$1000;
var notemapdraw:array[-3..maxnotemapdraw-1+3]of longint;
var notemapdrawn:longword;
var notemapdrawi:longint;
var notemapdrawa:longint;
var notemapdrawb:longint;
var notemapdraw0:array[-3..maxnotemapdraw-1+3]of longint;
var notemapdrawn0:longword;
var notemapdrawi0:longint;
var notemapdrawa0:longint;
var notemapdrawb0:longint;

procedure InitFNoteDraw(a,b:longint);inline;
begin
notemapdraw[0]:=a-3;
notemapdraw[1]:=a-2;
notemapdraw[2]:=b+2;
notemapdraw[3]:=b+3;
notemapdrawn:=4;
end;

procedure SetFNoteDraw(a,b:longint);inline;
begin
notemapdrawa:=0;
while notemapdrawa<notemapdrawn do
  begin
  if (a>=notemapdraw[notemapdrawa]) and (a<=notemapdraw[notemapdrawa+1]) then break;
  notemapdrawa:=notemapdrawa+1;
  end;
notemapdrawb:=0;
while notemapdrawb<notemapdrawn do
  begin
  if (b>=notemapdraw[notemapdrawb]) and (b<=notemapdraw[notemapdrawb+1]) then break;
  notemapdrawb:=notemapdrawb+1;
  end;
notemapdrawi0:=0;
for notemapdrawi:=0 to notemapdrawa do
  begin
  notemapdraw0[notemapdrawi0]:=notemapdraw[notemapdrawi];
  notemapdrawi0:=notemapdrawi0+1;
  end;
notemapdraw0[notemapdrawi0]:=a;
notemapdrawa0:=notemapdrawi0;
notemapdrawi0:=notemapdrawi0+1;
for notemapdrawi:=notemapdrawa+1 to notemapdrawb do
  begin
  notemapdraw0[notemapdrawi0]:=notemapdraw[notemapdrawi];
  notemapdrawi0:=notemapdrawi0+1;
  end;
notemapdraw0[notemapdrawi0]:=b;
notemapdrawb0:=notemapdrawi0;
notemapdrawi0:=notemapdrawi0+1;
for notemapdrawi:=notemapdrawb+1 to notemapdrawn-1 do
  begin
  notemapdraw0[notemapdrawi0]:=notemapdraw[notemapdrawi];
  notemapdrawi0:=notemapdrawi0+1;
  end;
notemapdrawn0:=notemapdrawi0;
notemapdrawa0:=(notemapdrawa0 shr 1 shl 1);
notemapdrawb0:=(notemapdrawb0 shr 1 shl 1)+1;
if notemapdraw0[notemapdrawa0]-notemapdraw0[notemapdrawa0-1]=1 then notemapdrawa0:=notemapdrawa0-2;
if notemapdraw0[notemapdrawb0+1]-notemapdraw0[notemapdrawb0]=1 then notemapdrawb0:=notemapdrawb0+2;
notemapdrawi:=0;
for notemapdrawi0:=0 to notemapdrawa0 do
  begin
  notemapdraw[notemapdrawi]:=notemapdraw0[notemapdrawi0];
  notemapdrawi:=notemapdrawi+1;
  end;
for notemapdrawi0:=notemapdrawb0 to notemapdrawn0-1 do
  begin
  notemapdraw[notemapdrawi]:=notemapdraw0[notemapdrawi0];
  notemapdrawi:=notemapdrawi+1;
  end;
notemapdrawn:=notemapdrawi;
end;

function GetFNoteDraw(i:longint):boolean;inline;
begin
GetFNoteDraw:=false;
notemapdrawi:=0;
while notemapdrawi<notemapdrawn do
  begin
  if (i>=notemapdraw[notemapdrawi]) and (i<=notemapdraw[notemapdrawi+1]) then GetFNoteDraw:=true;
  if GetFNoteDraw then break;
  notemapdrawi:=notemapdrawi+2;
  end;
end;

procedure GetFNoteDraw(var a,b:longint);
begin
notemapdrawi:=0;
while notemapdrawi<notemapdrawn do
  begin
  if (a>=notemapdraw[notemapdrawi]) and (a<=notemapdraw[notemapdrawi+1]) then a:=notemapdraw[notemapdrawi+1];
  if (b>=notemapdraw[notemapdrawi]) and (b<=notemapdraw[notemapdrawi+1]) then b:=notemapdraw[notemapdrawi];
  notemapdrawi:=notemapdrawi+2;
  end;
end;