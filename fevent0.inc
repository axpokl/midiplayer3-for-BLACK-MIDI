const maxfevent0n0=16;
const maxfevent0n=1 shl maxfevent0n0;
var fevent0:file of tevent;
var fevent0w:boolean;
var bfevent0:array[0..maxfevent0n-1]of tevent;
var bfevent0_:array[0..maxfevent0n-1]of tevent;
var bifevent0,bjfevent0:longint;

procedure FlushFEvent0();
begin
if bjfevent0>=0 then
  begin
  seek(fevent0,bjfevent0 shl maxfevent0n0);
  blockwrite(fevent0,bfevent0,maxfevent0n);
  end;
end;

procedure GetFEvent0Block(i:longint);
begin
if bjfevent0<>i shr maxfevent0n0 then
  begin
  if fevent0w then FlushFEvent0();
  bjfevent0:=i shr maxfevent0n0;
  if fevent0w then
    if filesize(fevent0)<=(bjfevent0 shl maxfevent0n0) then
      begin
      seek(fevent0,bjfevent0 shl maxfevent0n0);
      blockwrite(fevent0,bfevent0_,maxfevent0n);
      end;
  seek(fevent0,bjfevent0 shl maxfevent0n0);
  blockread(fevent0,bfevent0,maxfevent0n);
  end;
end;

function GetFEvent0(i:longint):tevent;
begin
if fb then
  begin
  GetFEvent0Block(i);
  bifevent0:=i and (maxfevent0n-1);
  GetFEvent0:=bfevent0[bifevent0];
  end
else
  GetFEvent0:=event0[i];
end;

procedure SetFEvent0(e:tevent;i:longint);
begin
if fb then
  begin
  GetFEvent0Block(i);
  bifevent0:=i and (maxfevent0n-1);
  bfevent0[bifevent0]:=e;
  end
else
  event0[i]:=e;
end;

function GetFEvent0TickTime(i:longint):double;
begin
if fb then
  GetFEvent0TickTime:=GetFEvent0(i).ticktime
else
  GetFEvent0TickTime:=event0[i].ticktime;
end;
