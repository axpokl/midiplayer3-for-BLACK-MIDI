const maxfeventn0=8;
const maxfeventn=1 shl maxfeventn0;
const maxfeventm0=8;
const maxfeventm=1 shl maxfeventm0;
var fevent:file of tevent;
var feventw:boolean;
var bfevent:array[0..maxfeventm-1,0..maxfeventn-1]of tevent;
var bfevent_:array[0..maxfeventn-1]of tevent;
var bifevent:longint;
var bjfevent:array[0..maxfeventm-1]of longint;
var bjfeventi:byte;

procedure FlushFEvent(tracki:byte);inline;
begin
if bjfevent[tracki]>=0 then
  begin
  seek(fevent,bjfevent[tracki] shl maxfeventn0);
  blockwrite(fevent,bfevent[tracki],maxfeventn);
  end;
end;

procedure GetFEventBlock(i:longint;tracki:byte);inline;
begin
if bjfevent[tracki]<>i shr maxfeventn0 then
  begin
  if feventw then FlushFEvent(tracki);
  bjfevent[tracki]:=i shr maxfeventn0;
  if feventw then
    if filesize(fevent)<=(bjfevent[tracki] shl maxfeventn0) then
      begin
      seek(fevent,bjfevent[tracki] shl maxfeventn0);
      blockwrite(fevent,bfevent_,maxfeventn);
      end;
  seek(fevent,bjfevent[tracki] shl maxfeventn0);
  blockread(fevent,bfevent[tracki],maxfeventn);
  end;
end;

function GetFEvent(i:longint;tracki:byte):tevent;inline;
begin
if fb then
  begin
  GetFEventBlock(i,tracki);
  bifevent:=i and (maxfeventn-1);
  GetFEvent:=bfevent[tracki,bifevent];
  end
else
  GetFEvent:=event[i];
end;

procedure SetFEvent(e:tevent;tracki:byte;i:longint);inline;
begin
if fb then
  begin
  GetFEventBlock(i,tracki);
  bifevent:=i and (maxfeventn-1);
  bfevent[tracki,bifevent]:=e;
  end
else
  event[i]:=e;
end;

function GetFEventCurTick(i:longint;tracki:byte):longword;inline;
begin
if fb then
  begin
  GetFEventBlock(i,tracki);
  bifevent:=i and (maxfeventn-1);
  GetFEventCurTick:=bfevent[tracki,bifevent].curtick;
  end
else
  GetFEventCurTick:=event[i].curtick;
end;
