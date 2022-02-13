{$R midiplayer.res}
//{$define video}
program midiplayer;

uses {$ifdef video}videooutput,{$endif}Windows,MMSystem,Display{$ifdef D3D},Direct3D9,D3Dx9{$endif};

var maxevent:longword=$1;
var fb:boolean=true;
var midiOut:longword=0;
var rs:ansistring;
var tempdirs:array[0..$FF]of char;

{$i freg.inc}
{$i flist.inc}

type tevent=packed record track:word;curtick,msg:longword;ticktime:double;end;
var event:packed array of tevent;
var eventi:longint;
var eventn:longword=0;
var event0:packed array of tevent;
var eventj:longword=0;
var eventk:longint=0;

const maxeventtm=$100000;
var eventtm:packed array[0..maxeventtm-1]of tevent;
var eventtmn:longword=0;
var eventtmi:longint=0;

const maxeventmu=$100000;
var eventmu:packed array[0..maxeventmu-1]of tevent;
var eventmun:longword=0;
var eventmui:longword;

const maxeventch=$100000;
var eventch:packed array[0..maxeventch-1]of tevent;
var eventchn:longword=0;
var eventchi:longint;

const maxeventseek=$1000;
var eventmsg:array[$0000..$FFFF]of word;
var eventmsgb:array[$0000..$FFFF]of boolean;
var eventmsgi:word;

const maxtrack0=10;
const maxtrack=1 shl maxtrack0;
const maxchan=maxtrack shl 4;
var track0:packed array[0..maxtrack-1]of longword;
var track1:packed array[0..maxtrack-1]of longword;
var tracki:longint;
var trackn:longword;
var trackj:longword;

var chancn:packed array[0..maxchan-1]of longword;
var chanci:packed array[0..maxchan-1]of longword;
var chancc:packed array[0..maxchan-1]of longword;
var chancw:packed array[0..maxchan-1]of longword;
var chancb:packed array[0..maxchan-1]of longword;
var chani:longword;
const chanc0:packed array[0..23]of byte=
(85,170,255,42,127,212,21,63,106,148,191,233,10,31,52,74,95,116,137,159,180,201,222,244);
const chanc0m:longword=24;
var chanc0n:longword;
var chanc00:packed array[0..maxchan-1]of byte;
var chanc0i:longword;
var chanc0s1,chanc0s2:ansistring;
var chanc0d:longint;
var chanc0r:word;
var chanc0b:boolean;
var chanc0p:longword;

var chordb:packed array[0..31]of byte=(
11,06,01,08,03,10,05,00,07,02,09,04,11,06,01,00,
08,03,10,05,00,07,02,09,04,11,06,01,08,03,10,00);
var chords:packed array[0..31]of ansistring=(
'Cb','Gb','Db','Ab','Eb','Bb','F','C','G','D','A','E','B','F#','C#','',
'ab','eb','bb','f','c','g','d','a','e','b','f#','c#','g#','d#','a#','');
var chord0,chord1:shortint;
var chordtmp:shortint=-1;
var sig0,sig1:byte;

var cs1:TRTLCriticalSection;
var cs2:TRTLCriticalSection;
var cs3:TRTLCriticalSection;
var cs4:TRTLCriticalSection;
var csfevent0:TRTLCriticalSection;
var csnote:TRTLCriticalSection;

var len0,head:longword;
var fpos,flen:longword;
var dvs:word;
var len:longint;
var tick,tick0,curtick,curtickm,tpq,tpqm:longword;
var ticktime0,ticktime0m:double;
var tempo:longword=500000;
var fps:double;
var stat0,stat,hex0,hex1,data0,data1:byte;
var lens:longword;
var meta:byte;
var msg:longword;
var begintime:double=-1;
var finaltime:double;
var finaltick:longword;
var chord:byte=7;
var tempo0:longword;
var tempo00:longword;
var drawr:double;
var smidiout:ansistring;

type tnotemap=packed record note:byte;note0,note1:double;notec:longword;chord:byte;end;
var notemap:packed array of tnotemap;
var notemapi:longint;
var notemapn:longword;

var fi:longint;
var fni:longint;
var fni0:longint;

{$i fevent.inc}
{$i fevent0.inc}
{$i fnote.inc}

procedure DrawTitle();forward;

var getb0:byte;
var getbb:boolean;
procedure GetB(b:byte);begin getb0:=b;getbb:=true;
len:=len+1;fpos:=fpos-1;end;
function Get1():byte;begin if fpos<flen then
begin
if getbb then Get1:=getb0 else Get1:=GetByte();getbb:=false;
len:=len-1;fpos:=fpos+1;end else Get1:=0;
if len0>0 then if fpos<=len0 then begin drawr:=fpos/len0;if fpos and $FFF=0 then DrawTitle();end;
end;
function Get2():Word;begin Get2:=Get1() shl 8 or Get1();end;
function Get3():longword;begin Get3:=Get2() shl 8 or Get1();end;
function Get4():longword;begin Get4:=Get3() shl 8 or Get1();end;
function Get0():longword;var l:longword=0;b:byte;n:shortint=0;
begin repeat b:=Get1();l:=(l shl 7) or (b and $7F);
n:=n+8;until (b and $80)=0;Get0:=l;end;
procedure swapc(var a,b:longword);var c:longword;begin c:=a;a:=b;b:=c;end;
function MixColor(a,b:longword;m:double):longword;var cmix:longword;
begin display.MixColor(a,b,cmix,m);MixColor:=cmix;end;
function t2s(r:double):ansistring;var h,m,s,ss:longword;var i:int64;
begin
if r<0 then r:=0;i:=trunc(r*1000);ss:=i mod 1000;s:=i div 1000;m:=s div 60;s:=s mod 60;h:=m div 60;m:=m mod 60;
t2s:=i2s(m)+':'+i2s(s,2,'0')+'.'+i2s(ss div 100);if h>0 then t2s:=i2s(h)+':'+i2s(m,2,'0')+':'+i2s(s,2,'0')+'.'+i2s(ss div 100);
end;
function r2s(bpm:double):ansistring;var r0,r1:longint;var s:ansistring='';
begin r0:=round(bpm*10) div 10;r1:=round(bpm*10) mod 10;s:=i2s(r0);if r1>0 then s:=s+'.'+i2s(r1);r2s:=s;end;

procedure AddEventTempo(tr:word;cu:longword;tm:longword);
begin
with eventtm[eventtmi] do
  begin
  track:=tr;
  curtick:=cu;
  msg:=tm;
  eventtmi:=eventtmi+1;
  end;
end;

procedure AddEventMessure(tr:word;cu:longword;t:double;ms:longword);
begin
with eventmu[eventmun] do
  begin
  track:=tr;
  curtick:=cu;
  msg:=ms;
  ticktime:=t;
  if eventmui=0 then msg:=msg or $01000000;
  eventmui:=(eventmui+1) mod sig0;
  eventmun:=eventmun+1;
  end;
end;

procedure AddEventChord(tr:word;cu:longword;ch:longword);
begin
with eventch[eventchi] do
  begin
  if eventchi>0 then if cu<eventch[eventchi-1].curtick then exit;
  track:=tr;
  curtick:=cu;
  msg:=ch;
  eventchi:=eventchi+1;
  end;
end;

procedure AddEvent(tr:word;cu,ms,tm:longword;ch:shortint);
var fi:longint;
begin
if ms and $FFFF=$51FF then AddEventTempo(tr,cu,tm)
else if ms and $FFFF=$59FF then AddEventChord(tr,cu,ch);
if fb then begin fi:=eventi;eventi:=0;end;
if not(fb) then if maxevent<=eventi then
  begin
  maxevent:=maxevent shl 1;
  setlength(event,maxevent);
  setlength(event0,maxevent);
  end;
with event[eventi] do
  begin
  track:=tr;
  curtick:=cu;
  msg:=ms;
  if msg and $F0=$90 then
    if msg shr 16 and $00FF=0 then
      msg:=msg and $FFFFFF8F;
  end;
if fb then begin SetFEvent(event[eventi],0,fi);eventi:=fi;end;
eventi:=eventi+1;
if finaltick<cu then finaltick:=cu;
end;

procedure LoadMidi(fname:UnicodeString);
begin
OpenFileW(fname);
fpos:=0;
flen:=GetFileLen();
len0:=GetFileLen();
head:=Get4();
if head=$52494646 then
  begin
  Get4();
  Get4();
  Get4();
  len0:=GetLongword();
  end;
while (head<>$4D546864) and (GetFilePos()<len0) do head:=Get4();
chord:=7;
dvs:=0;
if GetFilePos<len0 then
  begin
  Get4();
  Get2();
  Get2();
  dvs:=Get2();
  tpq:=0;if dvs and $8000=0 then tpq:=dvs and $7FFF;
  fps:=0;if dvs and $8000=1 then fps:=(dvs and $00FF)/(-((dvs and $7FFF) shr 8));
  end;
tracki:=0;
eventi:=0;
eventtmi:=0;
eventchi:=0;
finaltick:=0;
if fb then begin close(fevent);rewrite(fevent);feventw:=true;for bjfeventi:=0 to maxfeventm-1 do bjfevent[bjfeventi]:=-1;end;
while GetFilePos<len0 do
  begin
  curtick:=0;
  head:=0;
  while (head<>$4D54726B) and (GetFilePos<len0) do head:=Get4();
  if GetFilePos>=len0 then break;
  len:=Get4();
  while len>0 do
    begin
    if GetFilePos>=len0 then break;
    tick:=Get0();
    curtick:=curtick+tick;
    stat0:=Get1();
    if stat0>=$80 then
      stat:=stat0
    else
      GetB(stat0);
    hex0:=stat div 16;
    hex1:=stat mod 16;
    Data0:=0;
    Data1:=0;
    case hex0 of
      $8:begin Data0:=Get1();Data1:=Get1();end;
      $9:begin Data0:=Get1();Data1:=Get1();end;
      $A:begin Data0:=Get1();Data1:=Get1();end;
      $B:begin Data0:=Get1();Data1:=Get1();end;
      $C:begin Data0:=Get1();end;
      $D:begin Data0:=Get1();end;
      $E:begin Data0:=Get1();Data1:=Get1();end;
      $F:begin
         if Hex1=$F then meta:=Get1() else meta:=$FF;
         lens:=Get0();
         if meta=$51 then
           begin
           tempo:=Get3();
           AddEvent(tracki,curtick,meta shl 8 or Stat,tempo,0);
           end
         else if meta=$59 then
           begin
           chord0:=0;
           chord1:=0;
           if lens>0 then begin chord0:=shortint(Get1());lens:=lens-1;end;
           if lens>0 then begin chord1:=shortint(Get1());lens:=lens-1;end;
           while lens>0 do begin Get1();lens:=lens-1;end;
           if chord1<>0 then chord1:=1;
           chord:=chord0+7+chord1*0;
           AddEvent(tracki,max(0,curtick-1),meta shl 8 or Stat,0,chord);
           end
         else if meta=$58 then
           begin
           sig0:=0;
           sig1:=0;
           if lens>0 then begin sig0:=shortint(Get1());lens:=lens-1;end;
           if lens>0 then begin sig1:=shortint(Get1());lens:=lens-1;end;
           while lens>0 do begin Get1();lens:=lens-1;end;
           AddEvent(tracki,curtick,sig1 shl 24 or sig0 shl 16 or meta shl 8 or Stat,0,0);
           end
         else if meta=$2F then
           len:=0
         else
           while lens>0 do begin Get1();lens:=lens-1;end;
         end;
      end;
      if hex0<$F then
        begin
        msg:=Data1 shl 16 or Data0 shl 8 or Stat;
        addevent(tracki,curtick,msg,0,0);
        end;
    end;
  track1[tracki]:=eventi;
  tracki:=tracki+1;
  end;
drawr:=0;
CloseFile();
end;

const maxtrackheap=maxtrack;
var trackheapt:array[0..maxtrackheap-1]of longword;
var trackheap:array[0..maxtrackheap-1]of longword;
var trackheapi:longint;
var trackheapn:longword;

procedure SwapEventHeap(trackheapi,trackheapj:longword);inline;
var trackheapt0,trackheap0:longword;
begin
trackheapt0:=trackheapt[trackheapi];
trackheap0:=trackheap[trackheapi];
trackheapt[trackheapi]:=trackheapt[trackheapj];
trackheap[trackheapi]:=trackheap[trackheapj];
trackheapt[trackheapj]:=trackheapt0;
trackheap[trackheapj]:=trackheap0;
end;

procedure SortEventHeap(trackheapi:longword);
var trackheapj:longword;
begin
trackheapj:=(trackheapi+1)shl 1;
if trackheapj>=trackheapn then
  trackheapj:=trackheapj-1
else
  if trackheapt[trackheapj-1]<=trackheapt[trackheapj] then
    trackheapj:=trackheapj-1;
if trackheapj<trackheapn then
  if trackheapt[trackheapj]<trackheapt[trackheapi] then
    begin
    SwapEventHeap(trackheapi,trackheapj);
    SortEventHeap(trackheapj);
    end;
end;

procedure PrepareMidi();
begin
trackn:=tracki;
if fb then FlushFEvent(0);
if fb then begin feventw:=false;close(fevent);reset(fevent);for bjfeventi:=0 to maxfeventm-1 do bjfevent[bjfeventi]:=-1;end;
eventn:=eventi;
eventtmn:=eventtmi;
eventmun:=0;
eventchn:=eventchi;
track0[0]:=0;
for tracki:=1 to trackn-1 do track0[tracki]:=track1[tracki-1];
EnterCriticalSection(csfevent0);
if fb then begin close(fevent0);rewrite(fevent0);fevent0w:=true;bjfevent0:=-1;end;
eventj:=0;
trackheapi:=0;
for tracki:=0 to trackn-1 do
  if track0[tracki]<track1[tracki] then
    begin
    trackheapt[trackheapi]:=GetFEventCurTick(track0[tracki],tracki);
    trackheap[trackheapi]:=tracki;
    trackheapi:=trackheapi+1;
    end;
trackheapn:=trackheapi;
for trackheapi:=trackheapn-1 downto 0 do SortEventHeap(trackheapi);
while (eventj<eventn) do
  begin
  if eventn>0 then begin drawr:=eventj/eventn;if eventj and $FFF=0 then DrawTitle();end;
  trackj:=trackheap[0];
  SetFEvent0(GetFEvent(track0[trackj],trackj),eventj);
  track0[trackj]:=track0[trackj]+1;
  if track0[trackj]<track1[trackj] then trackheapt[0]:=GetFEventCurTick(track0[trackj],trackj)
  else begin SwapEventHeap(0,trackheapn-1);trackheapn:=trackheapn-1;end;
  SortEventHeap(0);
  eventj:=eventj+1;
  end;
if not(fb) then setlength(event,0);
if fb then
  begin
  EnterCriticalSection(csfevent0);
  close(fevent);rewrite(fevent);feventw:=false;for bjfeventi:=0 to maxfeventm-1 do bjfevent[bjfeventi]:=-1;
  LeaveCriticalSection(csfevent0);
  end;
if fb then FlushFEvent0();
drawr:=0;
tempo:=500000;
finaltime:=0;
curtick:=0;
curtickm:=0;
sig0:=1;
chordtmp:=-1;
tick0:=0;
ticktime0:=0;
tempo00:=0;
eventtmi:=0;
eventchi:=0;
tpqm:=tpq;
AddEventMessure(0,0,0,tempo);eventmui:=1;
for fi:=0 to eventn-1 do
  begin
  if eventn>0 then begin drawr:=fi/eventn;if fi and $FFF=0 then DrawTitle();end;
  if not(fb) then eventi:=fi else begin eventi:=0;event0[eventi]:=GetFEvent0(fi);end;
  tick:=max(0,event0[eventi].curtick-tick0);
  tick0:=tick0+tick;
  if tpq>0 then ticktime0:=ticktime0+tick/tpq*(tempo/1000000);
  if fps>0 then ticktime0:=ticktime0+tick/fps;
  event0[eventi].ticktime:=ticktime0;
  finaltime:=max(finaltime,ticktime0+1);
  while (eventtmi<eventtmn) and (eventtm[eventtmi].curtick<=tick0) do
    begin
    eventtm[eventtmi].ticktime:=ticktime0;
    tempo:=eventtm[eventtmi].msg;
    if tempo00=0 then tempo00:=tempo;
    eventtmi:=eventtmi+1;
    end;
  while curtickm+tpqm<=tick0 do
    begin
    tick:=tick0-(curtickm+tpqm);
    if tpq>0 then ticktime0m:=ticktime0-tick/tpq*(tempo/1000000);
    if fps>0 then ticktime0m:=ticktime0-tick/fps;;
    AddEventMessure(0,curtickm,ticktime0m,tempo);
    curtickm:=curtickm+tpqm;
    end;
  if event0[eventi].msg and $FFFF=$58FF then
    begin
    sig0:=event0[eventi].msg shr 16 and $FF;
    sig1:=event0[eventi].msg shr 24 and $FF;
    tpqm:=tpq shr max(0,sig1-2);
    end;
  while (eventchi<eventchn) and (eventch[eventchi].curtick<=tick0) do
    begin
    eventch[eventchi].ticktime:=ticktime0;
    chord:=eventch[eventchi].msg;
    if chordtmp=-1 then if eventch[eventchi].curtick=0 then chordtmp:=chord else chordtmp:=7;
    eventchi:=eventchi+1;
    end;
  if fb then SetFEvent0(event0[eventi],fi);
  end;
tick:=tpqm;
if tpq>0 then ticktime0m:=ticktime0m+tick/tpq*(tempo/1000000);
if fps>0 then ticktime0m:=ticktime0m+tick/fps;
AddEventMessure(0,curtickm,ticktime0m,tempo);
eventtmi:=0;
eventchi:=0;
drawr:=0;
if tempo00=0 then tempo00:=500000;
if fb then FlushFEvent0();
if fb then begin fevent0w:=false;close(fevent0);reset(fevent0);bjfevent0:=-1;end;
LeaveCriticalSection(csfevent0);
end;

var firsttime:double;
var pauseb:boolean;
var pausetime:double;
{$ifdef video}var videotime:double;{$endif}
{$ifdef video}var videob:boolean=false;{$endif}
var spd0:double=1;
var spdx:double=5;

const volamax=16;
const vola:packed array[1..volamax]of double=
(0,0.01,0.02,0.03,0.04,0.06,0.08,0.12,0.16,0.25,0.35,0.5,0.7,1,1.41,2);
var volchana:packed array[0..$F]of byte;
var volchani:byte;

var msghdr:MIDIHDR;
const maxbuf=$100000;
var msgbuf:packed array[0..maxbuf]of byte;//longword;
var msgbuf0:longword;
var msgbuf1,msgbuf2,msgbuf3:byte;
var msgbufn,msgbufnmax:longint;
var msgbufi:shortint;
var msgbufb:boolean;
var msgchan:array[0..$F,0..$FF,0..1]of byte;
var msgchan0:array[0..$F,0..$FF,0..1]of boolean;
var msgchani,msgchanj,msgchank:byte;

var initb:boolean=false;

procedure AddMsgBufStream(buf1,buf2,buf3:byte);
begin
if msgbufn+11<maxbuf then
  begin
//writeln('#',i2hs(buf1),i2hs(buf2),i2hs(buf3));
  for msgbufi:=0 to 9 do msgbuf[msgbufn+msgbufi]:=0;msgbuf[msgbufn+11]:=0;
  msgbuf[msgbufn+8]:=buf1;
  msgbuf[msgbufn+9]:=buf2;
  msgbuf[msgbufn+10]:=buf3;
  msgbufn:=msgbufn+12;
  end;
end;

procedure AddMsgBufLong(buf1,buf2,buf3:byte);
begin
if msgbufn<maxbuf-1 then
  begin
  msgbuf[msgbufn+0]:=buf1;
  msgbuf[msgbufn+1]:=buf2;
  msgbuf[msgbufn+2]:=buf3;
  msgbufn:=msgbufn+3;
  end;
end;

procedure AddMsgBuf(buf1,buf2,buf3:byte);
begin
if msgbufb1=1 then
  AddMsgBufLong(buf1,buf2,buf3)
else
  AddMsgBufStream(buf1,buf2,buf3);
end;

procedure CleanMsgChan();
begin
for msgchani:=0 to $F do
  for msgchanj:=0 to $FF do
    for msgchank:=0 to 1 do
      begin
      msgchan[msgchani][msgchanj][msgchank]:=0;
      msgchan0[msgchani][msgchanj][msgchank]:=false;
      end;
end;

var notemapa:longint;
var notemapb:longint;

procedure InitKbdC();forward;

procedure InitMidiChanVol(volchan:byte);
begin
for volchani:=0 to $F do volchana[volchani]:=volchan;
end;

procedure SetMidiChanVol(chan,volchan:byte);
begin
volchana[chan]:=volchan;
midiOutShortMsg(midiOut,$000007B0 or chan or min($7F,trunc(volchan*vola[voli]))shl 16);
end;

procedure SetMidiVol(v:shortint);
begin
voli:=max(1,min(volamax,v));
for volchani:=0 to $F do SetMidiChanVol(volchani,volchana[volchani]);
end;

procedure ResetMidiKeyVol();
var chani:byte;
begin for chani:=0 to $F do midiOutShortMsg(midiOut,$00007BB0 or chani);end;

function GetMidiTime():double;
begin
{$ifdef video}if videob then GetMidiTime:=videotime else{$endif}
if pauseb then GetMidiTime:=pausetime
else GetMidiTime:=GetTimeR()*spd0-firsttime;
end;

function SeekMidiTimeFEvent(seekt:double):longword;
var seeki,seekn:longword;seekx:longint;
begin
seekn:=eventn;
seeki:=seekn div 2;
seekx:=(seeki+1) div 2;
repeat
if seekx=0 then break;
if GetFEvent0Ticktime(seeki)>=seekt then seeki:=max(0,seeki-seekx) else seeki:=min(seeki+seekx,seekn-1);
if seekx=1 then break;
seekx:=(seekx+1) div 2;
until false;
if seekx>0 then if GetFEvent0Ticktime(seeki)<seekt then seeki:=min(seeki+1,seekn);
SeekMidiTimeFEvent:=seeki;
end;

function SeekMidiTimeFNote(seekt:double):longword;
var seeki,seekn:longword;seekx:longint;
begin
seekn:=notemapn;
seeki:=seekn div 2;
seekx:=(seeki+1) div 2;
repeat
if seekx=0 then break;
if GetFNote(seeki).note0>=seekt then seeki:=max(0,seeki-seekx) else seeki:=min(seeki+seekx,seekn-1);
if seekx=1 then break;
seekx:=(seekx+1) div 2;
until false;
if seekx>0 then if GetFNote(seeki).note0<seekt then seeki:=min(seeki+1,seekn);
SeekMidiTimeFNote:=seeki;
end;

function SeekMidiTimeTempo(seekt:double):longint;
var seeki,seekn:longword;seekx:longint;
begin
seekn:=eventtmn;
seeki:=(seekn-1) div 2;
seekx:=(seeki+1) div 2;
repeat
if seekx=0 then break;
if eventtm[seeki].ticktime>=seekt then seeki:=max(0,seeki-seekx) else seeki:=min(seeki+seekx,seekn-1);
if seekx=1 then break;
seekx:=(seekx+1) div 2;
until false;
if seekx>0 then if eventtm[seeki].ticktime<seekt then seeki:=min(seeki+1,seekn);
SeekMidiTimeTempo:=max(0,seeki-1);
end;

function SeekMidiTimeChord(seekt:double):longint;
var seeki,seekn:longword;seekx:longint;
begin
seekn:=eventchn;
seeki:=(seekn-1) div 2;
seekx:=(seeki+1) div 2;
repeat
if seekx=0 then break;
if eventch[seeki].ticktime>=seekt then seeki:=max(0,seeki-seekx) else seeki:=min(seeki+seekx,seekn-1);
if seekx=1 then break;
seekx:=(seekx+1) div 2;
until false;
if seeki>0 then if eventch[seeki-1].ticktime>seekt then seeki:=seeki-1;
if seeki<seekn-1 then if eventch[seeki].ticktime<seekt then seeki:=seeki+1;
SeekMidiTimeChord:=seeki-1;
end;

procedure SetMidiTime(settime:double;initkbd:boolean);
begin
settime:=max(begintime,min(finaltime,settime));
EnterCriticalSection(cs2);
if settime<=0 then midiOutReset(midiOut);
ResetMidiKeyVol();
firsttime:=GetTimeR()*spd0-settime;
EnterCriticalSection(csfevent0);
eventj:=SeekMidiTimeFEvent(settime);
tempo0:=tempo00;
for eventmsgi:=0 to $FFFF do
  begin
  if eventmsgb[eventmsgi] then
    midiOutShortMsg(midiOut,eventmsg[eventmsgi] shl 16);
  eventmsgb[eventmsgi]:=false;
  end;
for fi:=0 to min(eventj,eventn-1) do
if (fi<maxeventseek) or (fi>min(eventj,eventn-1)-maxeventseek) then
  begin
  if not(fb) then eventk:=fi else begin eventk:=0;event0[eventk]:=GetFEvent0(fi);end;
  if event0[eventk].msg and $F0 shr 4<$F then
    begin
    if(event0[eventk].msg and $F0 shr 4=$B) and(event0[eventk].msg shr 8 and $FF=$07)then
      SetMidiChanVol(event0[eventk].msg and $F,event0[eventk].msg shr 16 and $FF)
    else if (event0[eventk].msg and $F0<>$90) and (event0[eventk].msg and $F0<>$80) then
      begin
      eventmsg[event0[eventk].msg and $FFFF]:=event0[eventk].msg shr 16;
      eventmsgb[event0[eventk].msg and $FFFF]:=true;
      end;
//      midiOutShortMsg(midiOut,event0[eventk].msg);
    end;
  end;
for eventmsgi:=0 to $FFFF do
  if eventmsgb[eventmsgi] then
    midiOutShortMsg(midiOut,eventmsg[eventmsgi] shl 16 or eventmsgi);
if (eventtmn>0) then begin eventtmi:=SeekMidiTimeTempo(settime);tempo0:=eventtm[eventtmi].msg;end;
if (eventchn>0) then begin eventchi:=SeekMidiTimeChord(settime);if (eventchi>=0) then chord:=eventch[eventchi].msg else chord:=7;end;eventchi:=max(0,eventchi);
LeaveCriticalSection(csfevent0);
tempo:=tempo0;
eventi:=eventj;
if pauseb then pausetime:=settime;
if voli>0 then SetMidiVol(voli);
if settime<=0 then if chordtmp<>-1 then chord:=chordtmp;
notemapa:=0;
notemapb:=0;
if initkbd then InitKbdC();
LeaveCriticalSection(cs2);
end;

procedure SetMidiTime(settime:double);
begin SetMidiTime(settime,true);end;

procedure PauseMidi();
begin
if pauseb=false then pausetime:=GetMidiTime();
SetMidiTime(pausetime,false);
pauseb:=not(pauseb);
if not(pauseb) then InitKbdC();
end;

procedure SetMidiSpd(spd:longword);
begin
spd1:=max(0,min(1600,spd));
firsttime:=firsttime+GetTimeR()*(spd1/100-spd0);
spd0:=spd1/100;
end;

Procedure SetMidiChord(chord:longword);
begin
kchord0:=chord mod 12;
initb:=false;
end;

procedure SetMidiPitch(kkey:longint);
var chord:longword;
begin
kkey:=max(0,min(256,kkey));
chord:=(kchord0+(kkey-kkey0)*7+1800);
kkey0:=kkey;
SetMidiChord(chord);
ResetMidiKeyVol();
end;

const maxnote=$FFFFFF;
var note0:packed array[0..maxnote]of double;
var note1:packed array[0..maxnote]of double;
var notec:packed array[0..maxnote]of longword;
var notech:packed array[0..maxnote]of byte;
//var noteb:packed array[0..maxnote]of boolean;
var notem:packed array[0..maxnote]of longword;
var notei:longword;

var kbdc:packed array[$00..$7F]of longint;
var kbdcc:packed array[0..11]of longword;
var kbdci:byte;
const maxkbdc0=$10000;
var kbdc0k:packed array[0..maxkbdc0-1]of longint;
var kbdc0c:packed array[0..maxkbdc0-1]of longint;
var kbdc0i:longint;
var kbdc0n,kbdc0n0:longword;
var kbdc0m,kbdc0m0:longword;
var kbdc0p:longword;

const black0=$0F0F0F;//chan mix
const black1=$0F0F0F;//bmp bg
const gray0=$1F1F1F;//text bg
const gray1=$3F3F3F;//messure dark
const gray2=$9F9F9F;//messure light
const graym=$2F2F2F;//menu bar

const kbd0n=21;
const kbd1n=21+87;
var kbd0:byte=kbd0n;
var kbd1:byte=kbd1n;

procedure InitChannelColor();
begin
if length(chancolor)>0 then
  begin
  chanc0n:=0;
  chanc0s1:=chancolor;
  repeat
  chanc0b:=false;
  chanc0p:=pos(',',chanc0s1);
  if chanc0p>0 then
    begin
    chanc0s2:=copy(chanc0s1,chanc0p+1,length(chanc0s1)-chanc0p);
    delete(chanc0s1,chanc0p,length(chanc0s1)-chanc0p+1);
    end
  else
    chanc0s2:='';
  if length(chanc0s1)>0 then
    begin
    val(chanc0s1,chanc0d,chanc0r);
    chanc0b:=(chanc0r=0) and (chanc0d<256) and (chanc0d>=0);
    end;
  if chanc0b then
    begin
    chanc00[chanc0n]:=chanc0d;
    chanc0n:=chanc0n+1;
    chanc0s1:=chanc0s2;
    end;
  until chanc0b=false;
  end;
if chanc0n=0 then
  begin
  for chanc0i:=0 to chanc0m-1 do
    chanc00[chanc0i]:=chanc0[chanc0i];
  chanc0n:=chanc0m;
  end;
end;

procedure ResetChannelColor();
begin
for chani:=0 to maxchan-1 do
  begin
  chancn[chani]:=0;
  chanci[chani]:=chani;
  chancc[chani]:=HSN2RGB(chanc00[chani mod chanc0n]or $9FFF00);
  chancw[chani]:=chancc[chani];
  chancb[chani]:=MixColor(chancc[chani],black0,3/4);
  end;
end;

procedure AddNoteMap(notei:longword);
begin
notem[notei]:=notemapi;
if fb then begin fni:=notemapi;notemapi:=0;end;
notemap[notemapi].note:=notei and $7F;
notemap[notemapi].note0:=note0[notei];
notemap[notemapi].note1:=note1[notei];
notemap[notemapi].notec:=notec[notei];
notemap[notemapi].chord:=notech[notei];
if fb then begin SetFNote(notemap[notemapi],fni);notemapi:=fni;end;
chancn[notec[notei]]:=chancn[notec[notei]]+1;
notemapi:=notemapi+1;
//noteb[notei]:=false;
end;

procedure CreateNoteMap();
var ei:longint;
begin
EnterCriticalSection(csfevent0);
chord:=7;
eventchi:=0;
notemapi:=0;
notemapn:=0;
notemap:=nil;
for notei:=0 to maxnote-1 do notem[notei]:=0;
setlength(notemap,maxevent);
kbd0:=kbd0n;
kbd1:=kbd1n;
if fb then begin close(fnote);rewrite(fnote);fnotew:=true;for bjfnotei:=0 to maxfnotem-1 do bjfnote[bjfnotei]:=-1;bjfnotek:=-1;end;
for fi:=0 to eventn-1 do
  begin
  if eventn>0 then if fi and $FFF=0 then begin drawr:=fi/eventn;DrawTitle();end;
  if not(fb) then ei:=fi else begin ei:=0;event0[ei]:=GetFEvent0(fi);end;
  if event0[ei].msg and $F<>$9 then
    begin
    notei:=(event0[ei].msg shr 8 and $7F) or ((event0[ei].track or event0[ei].msg and $F shl maxtrack0) shl 8);
    if event0[ei].msg and $F0=$90 then
      begin
      if GetFNoteNote1(notem[notei])>event0[ei].ticktime then SetFNoteNote1(notem[notei],event0[ei].ticktime);
      kbd0:=min(notei and $7F,kbd0);
      kbd1:=max(notei and $7F,kbd1);
      while (eventchi<eventchn) and (eventch[eventchi].curtick<=event0[ei].curtick) do
        begin chord:=eventch[eventchi].msg;eventchi:=eventchi+1;end;
      notech[notei]:=chord;
      notec[notei]:=event0[ei].track or event0[ei].msg and $F shl maxtrack0;
      note0[notei]:=event0[ei].ticktime;
      note1[notei]:=finaltime;
      AddNoteMap(notei);
      end;
    if event0[ei].msg and $F0=$80 then
      SetFNoteNote1(notem[notei],event0[ei].ticktime);
    end;
  end;
eventtmi:=0;
//eventmui:=0;
eventchi:=0;
drawr:=0;
EnterCriticalSection(csnote);
if fb then FlushFNoteAll();
if fb then begin fnotew:=false;close(fnote);reset(fnote);for bjfnotei:=0 to maxfnotem-1 do bjfnote[bjfnotei]:=-1;bjfnotek:=-1;end;
LeaveCriticalSection(csnote);
LeaveCriticalSection(csfevent0);
notemapn:=notemapi;
end;

procedure SortNoteMapColorQuick1(n1,n2:longword);
var qv,q1,q2:longword;
begin
qv:=chancn[n1];
q1:=n1;
q2:=n2;
while (q1<q2) do
  begin
  while (q1<q2) and (chancn[q2]<qv) do
    q2:=q2-1;
  if (q1<q2) then
    begin
    swapc(chancn[q1],chancn[q2]);
    swapc(chanci[q1],chanci[q2]);
    q1:=q1+1;
    end;
  while (q1<q2) and (chancn[q1]>qv) do
    q1:=q1+1;
  if (q1<q2) then
    begin
    swapc(chancn[q1],chancn[q2]);
    swapc(chanci[q1],chanci[q2]);
    q2:=q2-1;
    end;
  end;
if (q1-1>n1) then SortNoteMapColorQuick1(n1,q1-1);
if (n2>q1+1) then SortNoteMapColorQuick1(q1+1,n2);
end;

procedure SortNoteMapColorQuick2(n1,n2:longword);
var qv,q1,q2:longword;
begin
qv:=chanci[n1];
q1:=n1;
q2:=n2;
while (q1<q2) do
  begin
  while (q1<q2) and (chanci[q2]>qv) do
    q2:=q2-1;
  if (q1<q2) then
    begin
    swapc(chancn[q1],chancn[q2]);
    swapc(chanci[q1],chanci[q2]);
    swapc(chancw[q1],chancw[q2]);
    swapc(chancb[q1],chancb[q2]);
    q1:=q1+1;
    end;
  while (q1<q2) and (chanci[q1]<qv) do
    q1:=q1+1;
  if (q1<q2) then
    begin
    swapc(chancn[q1],chancn[q2]);
    swapc(chanci[q1],chanci[q2]);
    swapc(chancw[q1],chancw[q2]);
    swapc(chancb[q1],chancb[q2]);
    q2:=q2-1;
    end;
  end;
if (q1-1>n1) then SortNoteMapColorQuick2(n1,q1-1);
if (n2>q1+1) then SortNoteMapColorQuick2(q1+1,n2);
end;

procedure SortNoteMapColor();
begin
SortNoteMapColorQuick1(0,maxchan-1);
SortNoteMapColorQuick2(0,maxchan-1);
SortNoteMapColorQuick1(0,maxchan-1);
end;

procedure ResetNoteMap();
begin
InitChannelColor();
ResetChannelColor();
CreateNoteMap();
SortNoteMapColor();
end;

type tchord=packed record
  ticktime0:double;
  ticktime1:double;
  chord:byte;
  end;
const maxchordmu=maxeventmu;
var chordmu:packed array[0..maxeventmu-1]of tchord;
var chordmui,chordmuj,chordmun:longword;
var notetime:array[0..$F,0..11]of double;
var notetimei,notetimej:byte;
const notetimechc:array[0..11]of shortint=(0,1,0,1,0,0,1,0,1,0,1,0);
var notetimech:array[0..11]of double;
var notetimechi:byte;
var notetimechmin:double;

procedure CalcChord();
begin
notetimei:=chordmui and $F;
write(chordmui-1:3,' ');
//for notetimej:=0 to 11 do if notetime[notetimei,notetimej]>0 then write(notetime[notetimei,notetimej]:0:3,' ')else write('      ');writeln();
for notetimechi:=0 to 11 do
  begin
  notetimech[notetimechi]:=0;
  for notetimej:=0 to 11 do notetimech[notetimechi]:=notetimech[notetimechi]+notetime[notetimei,notetimej]*notetimechc[(notetimej+notetimechi)mod 12];
  end;
notetimechmin:=notetimech[0];
for notetimechi:=1 to 11 do notetimechmin:=min(notetimechmin,notetimech[notetimechi]);
for notetimechi:=0 to 11 do notetimech[notetimechi]:=notetimech[notetimechi]-notetimechmin;
//for notetimechi:=0 to 11 do if notetimech[(notetimechi*5)mod 12]>0 then write(notetimech[(notetimechi*5)mod 12]:0:2,' ') else write('     ');writeln();
for notetimej:=0 to 11 do notetime[notetimei,notetimej]:=0;
chordmui:=chordmui+1;
end;

procedure MakeChord();
var x:double;
begin
chordmu[0].ticktime0:=-1;
for chordmun:=0 to eventmun-1 do
   begin
   chordmu[chordmun].ticktime1:=eventmu[chordmun].ticktime;
   chordmu[chordmun+1].ticktime0:=eventmu[chordmun].ticktime;
   end;
chordmu[eventmun].ticktime1:=finaltime;
chordmun:=eventmun+1;
//for chordmui:=0 to chordmun-1 do with chordmu[chordmui] do writeln(chordmui:5,#9,ticktime0:0:10,#9,ticktime1:0:10);
for notetimei:=0 to $F do
  for notetimej:=0 to 11 do
    notetime[notetimei,notetimej]:=0;
chordmui:=0;
for fni:=0 to notemapn-1 do
  begin
  if notemapn>0 then if fni and $FFF=0 then begin drawr:=fni/notemapn;DrawTitle();end;
  if fb then begin notemapi:=0;notemap[notemapi]:=GetFNote(fni);end else notemapi:=fni;
  with notemap[notemapi] do
    begin
    while note0>=chordmu[chordmui].ticktime1 do CalcChord();
    chordmuj:=chordmui-1;
    repeat
    chordmuj:=chordmuj+1;
    notetimei:=chordmuj and $F;
    notetimej:=note mod 12;
x:=(min(chordmu[chordmuj].ticktime1,note1)-max(chordmu[chordmuj].ticktime0,note0));
    notetime[notetimei,notetimej]:=notetime[notetimei,notetimej]+x;
//writeln(fni:3,#9,notemapi:3,#9,note0:0:5,chordmui:3,#9,chordmuj:3,#9,notetimei:3,#9,notetimej:3,#9,notetime[notetimei,notetimej]:0:5,#9,note:5,#9,x:0:10);
    until(chordmu[chordmuj].ticktime1>=note1)or(chordmuj-chordmui>=$F);
//writeln(note:5,#9,note0:0:5,#9,note1:0:5,#9,i2hs(notec):5,#9,chord:5);
    end;
  end;
CalcChord();
end;

var w:longword;
var h:longword;
var sz:longword;
var fw,fh:longword;
var frametime:double;
var printtime:double;
var scrtime:double;
var delaytime:double=0;

var k_shift,k_ctrl:boolean;
var k_pos:double;

const klen0:double=1.15;//black key pos
const klen1:double=0.65;//font size
var kbd:packed array[0..11]of double;
const keyblack:packed array[0..11]of byte=(0,1,0,1,0,0,1,0,1,0,1,0);
const keychord:packed array[0..3,0..11]of char=(
('1',' ','2',' ','3','4',' ','5',' ','6',' ','7'),
('C','d','D','e','E','F','g','G','a','A','b','B'),
(' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '),
(' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '));

var kleny0:double=6.5;
var kleny1:double=4.5;

var kbdi,kbdn:byte;

const fhr=0.7;
const mult0=600;

const maxbnote=$80;
const maxbnotebuf=$100000;
var bnote:packed array[0..1,0..maxbnote-1]of pbitmap;
var bnotej0:packed array[0..1,0..maxbnote-1]of longint;
var bnotej1:packed array[0..1,0..maxbnotebuf-1]of longint;
//var bnoten:longint=-1;
var bnoten0:longint=-1;
var bnoten00:longint=-1;
var bnotej:longint;
var bnoteh:longword=0;
var bnoteh0:longword=$1000;
var bnoteb:boolean=false;
var bnoteb0:longint;
var bnoteb1:array[0..1]of longint;
var bmpname:ansistring;

type tbnotekey=packed record
x,y,w,h:longint;bi:shortint;cbg,cfg:longword;
s:ansistring;sx,sy:longint;sc:longword;
end;
var bnotekey:packed array[0..$7F]of tbnotekey;
var bnotekeyn:longword;

procedure InitkbdPos();
begin
kbd[0]:=0;
kbd[1]:=1+(klen0-3*klen1)/2;
kbd[2]:=1;
kbd[3]:=2-(klen0-klen1)/2;
kbd[4]:=2;
kbd[5]:=3;
kbd[6]:=5-(2*klen0+klen1)/2;
kbd[7]:=4;
kbd[8]:=5-(klen1)/2;
kbd[9]:=5;
kbd[10]:=5-(-2*klen0+klen1)/2;
kbd[11]:=6;
end;

procedure InitkbdColor();
begin for kbdi:=0 to 11 do kbdcc[kbdi]:=HSN2RGB($9FFF00 or round((kbdi*5+7)mod 12*$FF/12));end;

function GetKeyChordS(chord:byte):ansistring;
begin chord:=(chord and $F)+kchord0;if chord>=$F then chord:=chord-12;GetKeyChordS:=chords[chord]+'/'+chords[$10 or chord];end;

function GetKeyChord(k:byte;chord:byte):ansistring;
begin GetKeyChord:=keychord[kchb,(k-chordb[chord]+kchord0*5+12) mod 12];end;

function GetKeyChord0(k:byte;chord:byte):byte;
begin GetKeyChord0:=(k-chordb[chord]+kchord0*5+12) mod 12;end;

function GetKeyChordC(k:byte;chord:byte):longword;
begin GetKeyChordC:=kbdcc[GetKeyChord0(k,chord)];end;

function GetKeyChord(k:byte):ansistring;
begin GetKeyChord:=GetKeyChord(k,chord);end;

function IsKeynoteBlack(k:byte):byte;
begin IsKeynoteBlack:=keyblack[k mod 12];end;

function GetKeykey(k:byte):byte;var key:longint;
begin key:=k+kkey0-128;while key<0 do key:=key+12;while key>$7F do key:=key-12;GetKeykey:=key;end;

function GetKeynote(k:byte):double;
begin GetKeynote:=7*(k div 12)+kbd[k mod 12];end;

function GetKeynote0(k:byte):double;
begin if(IsKeynoteBlack(k)=0)then GetKeynote0:=GetKeynote(k)+1 else GetKeynote0:=GetKeynote(k)+klen1;end;

function GetKeynoteX(k:byte):longint;
begin GetKeyNoteX:=round((GetKeynote(k)-GetKeynote(kbd0))*GetWidth()/(GetKeynote0(kbd1)-GetKeynote(kbd0)));end;

function GetKeynoteX0(k:byte):longint;
begin GetKeyNoteX0:=round((GetKeynote0(k)-GetKeynote(kbd0))*GetWidth()/(GetKeynote0(kbd1)-GetKeynote(kbd0)));end;

function GetKeynoteW0():longword;
begin GetKeynoteW0:=round(GetWidth()/(GetKeynote(kbd1+1)-GetKeynote(kbd0)));end;

function GetKeynoteW1():longword;
begin GetKeynoteW1:=round(GetWidth()/(GetKeynote(kbd1+1)-GetKeynote(kbd0))*klen1);end;

function GetKeynoteW(k:byte):longword;
begin if(IsKeynoteBlack(k)=1) then GetKeynoteW:=GetKeynoteW1() else GetKeynoteW:=GetKeynoteW0();end;

function GetKeynoteC(k:byte;chan:word):longword;
begin if(IsKeynoteBlack(k)=1) and (kbdcb=1) then GetKeynoteC:=chancb[chan] else GetKeynoteC:=chancw[chan];end;

procedure InitKbdC();
begin
for kbdci:=$00 to $7F do kbdc[kbdci]:=-1;
for kbdc0i:=0 to (maxkbdc-1) do
  begin
  kbdc0k[kbdc0i]:=-1;
  kbdc0c[kbdc0i]:=-1;
  end;
kbdc0n:=0;
kbdc0m:=0;
kbdc0p:=0;
end;

procedure PushKbdC(k,c:longint);
begin
kbdc0k[kbdc0n]:=k;
kbdc0c[kbdc0n]:=c;
kbdc0n:=(kbdc0n+1)and(maxkbdc-1);
kbdc0k[kbdc0n]:=-1;
kbdc0p:=kbdc0p+1;
end;

procedure PopKbdC(k:longint);
var kbdc0b:boolean=false;
begin
kbdc0n0:=kbdc0n;if kbdc0m>kbdc0n0 then kbdc0n0:=kbdc0n0 or maxkbdc;kbdc0m0:=kbdc0n0-kbdc0m;
for kbdc0i:=kbdc0m to kbdc0n0-1 do
  if kbdc0b=false then
    if kbdc0k[kbdc0i and (maxkbdc-1)]=k then
      begin
      kbdc0k[kbdc0i and (maxkbdc-1)]:=-1;
      kbdc0c[kbdc0i and (maxkbdc-1)]:=-1;
      kbdc0b:=true;
      end;
kbdc0p:=max(0,kbdc0p-1);
while (kbdc0m<>kbdc0n) and (kbdc0k[kbdc0m]=-1) do
  kbdc0m:=(kbdc0m+1)and(maxkbdc-1);
end;

procedure ResetKbdC();
begin
kbdc0n0:=kbdc0n;if kbdc0m>kbdc0n0 then kbdc0n0:=kbdc0n0 or maxkbdc;kbdc0m0:=kbdc0n0-kbdc0m;
for kbdc0i:=kbdc0m to kbdc0n0-1 do
  if kbdc0k[kbdc0i and (maxkbdc-1)]>-1 then
    kbdc[kbdc0k[kbdc0i and (maxkbdc-1)] and $7F]:=kbdc0c[kbdc0i and (maxkbdc-1)];
end;

procedure SetNoteLength(m:longint);
begin
EnterCriticalSection(cs4);
mult:=max(0,min(1000,m));
initb:=false;
LeaveCriticalSection(cs4);
end;

procedure SetDrawFont(sz:double);
begin
fw:=max(1,round((GetKeynoteW1()-2)*sz));
fh:=max(1,round(fw*2.2));
SetFontSize(fw,fh);
SetFont();
end;

procedure SetDrawFont();
begin SetDrawFont(1);end;

procedure GetDrawTime();
begin printtime:=GetMidiTime();end;

procedure ClearBMP(bi,bnoteb0:longint);
begin
if bnote[bi,bnoteb0]<>nil then
  begin
  bmpname:=tempdir+'bmp'+'_'+i2s(bi)+'_'+i2s(bnotej0[bi,bnoteb0])+'_'+rs+'.png';
  if bnotej0[bi,bnoteb0]>=0 then SaveBMP(bnote[bi,bnoteb0],bmpname);
  ReleaseBMP(bnote[bi,bnoteb0]);
  bnote[bi,bnoteb0]:=nil;
  end;
end;

procedure FreshBMP(bi,bj:longint);
begin
if bnotej0[bi,bnotej1[bi,bj]]<>bj then
  begin
  bnoteb1[bi]:=(bnoteb1[bi]+1) and (maxbnote-1);
//  bnoteb1[bi]:=min(maxbnote-1,bnoteb1[bi]+1);
  if bnote[bi,bnoteb1[bi]]<>nil then bnoteb1[bi]:=random(maxbnote);
  bnoteb0:=bnoteb1[bi];
  ClearBMP(bi,bnoteb0);
  bnotej0[bi,bnoteb0]:=bj;
  bnotej1[bi,bj]:=bnoteb0;
  end
else
  bnoteb0:=bnotej1[bi,bj];
if bnote[bi,bnoteb0]=nil then
  begin
  bmpname:=tempdir+'bmp'+'_'+i2s(bi)+'_'+i2s(bnotej0[bi,bnoteb0])+'_'+rs+'.png';
  if IsFile(bmpname) then
    begin
    bnote[bi,bnoteb0]:=LoadBMP(bmpname,black1);
    DeleteFile(bmpname);
    end
  else
    begin
    bnote[bi,bnoteb0]:=CreateBMP(GetWidth(),bnoteh0,black1);
    end;
  SetDrawFont();
  SetFont(bnote[bi,bnoteb0]);
  end;
end;

{$ifdef D3D}
{$i d3d.inc}
{$else}
procedure AddBar(bi,bj:longint;x,y,w,h:longint;cfg,cbg:longword);
begin
FreshBMP(bi,bj);
Bar(bnote[bi,bnotej1[bi,bj]],x,y,w,h,cfg,cbg);
end;

procedure AddDrawTextXY(bi,bj:longint;s:ansistring;x,y:longint;c:longword);
begin
FreshBMP(bi,bj);
DrawTextXY(bnote[bi,bnotej1[bi,bj]],s,x,y,c);
if bj>0 then if y+fh>bnoteh0 then DrawTextXY(bnote[bi,bnotej1[bi,bj-1]],s,x,y-bnoteh0,c);
end;
{$endif}

procedure AddLine(bi,bj:longint;x,y,w,h:longint;c:longword);
begin
FreshBMP(bi,bj);
Line(bnote[bi,bnotej1[bi,bj]],x,y,w,h,c);
end;

procedure FlushBar(flushb:boolean);
var keyi:byte;
var y0,h0:longword;
var bnotej:longint;
begin
for keyi:=0 to $7F do
  with bnotekey[keyi] do
  begin
  if h>0 then
    begin
    bnotej:=(y+h)div bnoteh0;
    y0:=bnoteh0-(y+h-bnotej*bnoteh0);
    h0:=h;
    while h0>(bnoteh0-y0) do
      begin
      if (bnotej>=0) then
        AddBar(bi,bnotej,x,y0-1,w,bnoteh0-y0+2,cfg,cbg);
      h0:=h0-(bnoteh0-y0);
      y0:=0;
      bnotej:=bnotej-1;
      end;
    if (bnotej>=0) then
      AddBar(bi,bnotej,x,y0-1,w,h0+1,cfg,cbg);
    bnotej:=(sy+fh+2)div bnoteh0;
    y0:=bnoteh0-(sy+fh+2-bnotej*bnoteh0);
    if kchb<=1 then
      AddDrawTextXY(bi,bnotej,s,sx,y0+1,sc);
    if y0+fh>=bnoteh0 then
      if bnotej>1 then
        if kchb<=1 then
          AddDrawTextXY(bi,bnotej-1,s,sx,y0-bnoteh0+1,sc);
    h:=0;
    end;
  end;
if flushb then
  begin
  EnterCriticalSection(csnote);
  if fb then FlushFNoteAll();
  LeaveCriticalSection(csnote);
  end;
end;

procedure DrawBNote(ni:longword);
var x,y,w,h:longint;
var key:byte;
var bi:shortint;
begin
if fb then begin fni0:=ni;ni:=0;notemap[ni]:=GetFNote(fni0);end;
key:=GetKeykey(notemap[ni].note);
bi:=IsKeynoteBlack(key);
x:=GetKeynoteX(key);
w:=GetKeynoteX0(key)-GetKeynoteX(key);
y:=trunc((notemap[ni].note0)*mult*GetWidth()/mult0)+round(GetKeynoteW0()*kleny0);
h:=max(1,trunc((notemap[ni].note1-notemap[ni].note0)*mult*GetWidth()/mult0));
if kchb<=1 then h:=max(round(fh*fhr),h);
if ((h+y)<>bnotekeyn) then FlushBar(false);
bnotekeyn:=(h+y);
if(h>=bnotekey[key].h)then
  begin
  bnotekey[key].x:=x;
  bnotekey[key].y:=y;
  bnotekey[key].w:=w;
  bnotekey[key].h:=h;
  bnotekey[key].bi:=bi;
  if kbdcb=0 then
    bnotekey[key].cbg:=GetKeyChordC(key,notemap[ni].chord)
  else
    bnotekey[key].cbg:=GetKeynoteC(key,notemap[ni].notec);
  bnotekey[key].cfg:=MixColor(bnotekey[key].cbg,black,3/4);
  bnotekey[key].s:=GetKeyChord(key,notemap[ni].chord);
  bnotekey[key].sx:=x+(w-fw)div 2;
  bnotekey[key].sy:=min(y+round((h-fh)*fhr),y);
  bnotekey[key].sc:=black;
  end;
end;

procedure _Bar(x,y,w,h:longint;cfg,cbg:longword);
begin Bar(x,GetHeight()-y-h,w,h,cfg,cbg);end;

procedure _Line(bi:shortint;x,y,w,h:longint;c:longword);
var y0:longword;
var bnotej:longint;
begin
bnotej:=y div bnoteh0;
y0:=bnoteh0-(y-bnotej*bnoteh0);
if ((bnotej>=0) and ((bnotej<maxbnote) or bnoteb)) then
  AddLine(bi,bnotej,x,y0,w,h,c);
end;

procedure _Line(b:pbitmap;x,y,w,h:longint;c:longword);
begin Line(b,x,bnoteh-y-h,w,h,c);end;

procedure _Line(x,y,w,h:longint;c:longword);
begin Line(x,GetHeight()-y-h,w,h,c);end;

procedure _DrawTextXY(bi:shortint;s:ansistring;sx,sy:longint;sc:longword);
var y0:longword;
var bnotej:longint;
begin
bnotej:=(sy+fh+2)div bnoteh0;
y0:=bnoteh0-(sy+fh+2-bnotej*bnoteh0);
if (bnotej>=0) and (bnotej<maxbnote) then
AddDrawTextXY(bi,bnotej,s,sx,y0+1,sc);
if y0+fh>=bnoteh0 then
  if (bnotej-1>=0) and (bnotej-1<maxbnote) then
    AddDrawTextXY(bi,bnotej-1,s,sx,y0-bnoteh0+1,sc);
end;

procedure _DrawTextXY(s:ansistring;x,y:longint;c:longword);
begin DrawTextXY(s,x,GetHeight()-y-fh-2,c);end;

procedure _DrawTextXY_Top(s:ansistring;x,y:longint;c:longword);
begin DrawTextXY(s,x,y,c,gray0);end;

procedure _DrawTextXY_Btm(s:ansistring;x,y:longint;c:longword);
begin DrawTextXY(s,x,GetHeight()-round(GetKeynoteW0()*kleny0)-y-fh-2,c,gray0);end;

procedure _DrawTextXY_Mid(s:ansistring;x,y:longint;c:longword);
begin DrawTextXY(s,x,(GetHeight()-round(GetKeynoteW0()*kleny0)-fh-2)div 2,c,gray0);end;

procedure DrawMessureLine(t:double;ms:longword;tempo:longword;c:longword);
var w0,y:longint;
var bpm:double;
begin
tempo:=tempo and $FFFFFF;
w0:=GetKeynoteW0();
y:=trunc(t*mult*GetWidth()/mult0)+round(w0*kleny0);
_line(0,0,y,GetWidth(),0,c);
_DrawTextXY(0,i2s(ms),0,y,c);
if tempo>0 then bpm:=60000000/tempo*spd0 else bpm:=0;
_DrawTextXY(0,r2s(bpm),GetWidth()-fw*length(r2s(bpm)),y,c);
end;

procedure DrawChordLine(t:double;ch:byte;c:longword);
var w0,y:longint;
begin
w0:=GetKeynoteW0();
y:=trunc(t*mult*GetWidth()/mult0)+round(w0*kleny0);
_line(0,0,y,GetWidth(),0,c);
_DrawTextXY(0,GetKeyChordS(ch),0,y-fh-4,c);
end;

procedure DrawMessureLineAll();
var grayx:longword;
var eventmui,eventchi:longint;
begin
grayx:=gray0;if kmessure=1 then grayx:=gray1;
if eventmun>0 then
  for eventmui:=0 to eventmun-1 do
    if (kmessure<=1) then if eventmu[eventmui].msg shr 24=0 then DrawMessureLine(eventmu[eventmui].ticktime,eventmui,eventmu[eventmui].msg,grayx);
if eventmun>0 then
  for eventmui:=0 to eventmun-1 do
    if (kmessure<=2) then if eventmu[eventmui].msg shr 24=1 then DrawMessureLine(eventmu[eventmui].ticktime,eventmui,eventmu[eventmui].msg,gray1);
if eventchn>0 then
  for eventchi:=0 to eventchn-1 do
    if (kmessure<=3) then DrawChordLine(eventch[eventchi].ticktime,eventch[eventchi].msg,gray2);
end;

procedure DrawNoteLine();
var kbd:byte;
var x:longword;
begin
for kbd:=kbd0 to kbd1 do
  begin
  x:=GetKeynoteX(kbd);
  if (kbd) mod 12=0 then _Line(x,0,0,GetHeight(),gray1);
  if (kbd) mod 12=5 then _Line(x,0,0,GetHeight(),gray0);
  end;
end;

procedure DrawKeyBoardKeys(opt:shortint);
var kbd0i,kbd1i:byte;
var kbdi:byte;
var x,w,w0:longint;
begin
kbd0i:=kbd0;
kbd1i:=kbd1;
if IsKeynoteBlack(kbd0i)=1 then kbd0i:=max($00,kbd0i-1);
if IsKeynoteBlack(kbd1i)=1 then kbd1i:=min($7F,kbd1i+1);
for kbdi:=kbd0i to kbd1i do
  begin
  x:=GetKeynoteX(kbdi);
  w:=GetKeynoteX0(kbdi)-GetKeynoteX(kbdi);
  w0:=GetKeynoteW0();
  case opt of
    1:if (IsKeynoteBlack(kbdi)=0) and (kbdc[kbdi]=-1) then
	    begin
	    _Bar(x,0,w,round(w0*kleny0),black,white);
	    if kchb<=1 then _DrawTextXY(GetKeyChord(kbdi),x+(w-fw)div 2,4,MixColor(white,black,1/2));
	    end;
    2:if (IsKeynoteBlack(kbdi)=0) and (kbdc[kbdi]<>-1) then
	    begin
	    _Bar(x,0,w,round(w0*kleny0),black,kbdc[kbdi]);
	    if kchb<=1 then _DrawTextXY(GetKeyChord(kbdi),x+(w-fw)div 2,0,black);
	    end;
    3:if (IsKeynoteBlack(kbdi)=1) and (kbdc[kbdi]=-1) then
	    begin
	    _Bar(x,round(w0*(kleny0-kleny1)),w,round(w0*kleny1),black,black);
		_DrawTextXY(GetKeyChord(kbdi),x+(w-fw)div 2,round(w0*(kleny0-kleny1))+4,MixColor(black,white,1/2));
		end;
    4:if (IsKeynoteBlack(kbdi)=1) and (kbdc[kbdi]<>-1) then
	    begin
		_Bar(x,round(w0*(kleny0-kleny1)),w,round(w0*kleny1),black,kbdc[kbdi]);
        _DrawTextXY(GetKeyChord(kbdi),x+(w-fw)div 2,round(w0*(kleny0-kleny1)),black);
        end;
    end;
  end;
end;

procedure DrawKeyboard();
begin
EnterCriticalSection(cs3);
ResetKbdC();
DrawKeyBoardKeys(1);
DrawKeyBoardKeys(2);
DrawKeyBoardKeys(3);
DrawKeyBoardKeys(4);
LeaveCriticalSection(cs3);
end;

procedure InitBNote0(force:boolean);
begin
if notemapn-1>=0 then
  bnoteh:=round(finaltime*mult*GetWidth()/mult0)+GetHeight();
bnoten0:=bnoteh div bnoteh0;
bnoten00:=max(bnoten0,bnoten00);
{$ifdef D3D}CreateD3D(GetWidth(),bnoteh0);{$endif}
{$ifdef D3D}CreateD3DBMP(GetWidth(),bnoteh0);{$endif}
for bnoteb0:=0 to maxbnote-1 do
  begin
  bnotej0[0,bnoteb0]:=-1;
  bnotej0[1,bnoteb0]:=-1;
  clearbmp(0,bnoteb0);
  clearbmp(1,bnoteb0);
  end;
{
bnoten0:=min(bnoten0,maxbnote-1);
for bnotej:=bnoten0+1 to bnoten do
  begin
  ReleaseBMP(bnote[0,bnotej]);
  ReleaseBMP(bnote[1,bnotej]);
  end;
for bnotej:=0 to min(bnoten0,bnoten) do
  begin
  if force or (bnote[0,bnotej]^.width<>GetWidth()) then
    begin
    ReleaseBMP(bnote[0,bnotej]);
    bnote[0,bnotej]:=CreateBMP(GetWidth(),bnoteh0,black1);
    end
  else
    begin
    Clear(bnote[0,bnotej]);
    end;
  if force or (bnote[1,bnotej]^.width<>GetWidth()) then
    begin
    ReleaseBMP(bnote[1,bnotej]);
    bnote[1,bnotej]:=CreateBMP(GetWidth(),bnoteh0,black1);
    end
  else
    begin
    Clear(bnote[1,bnotej]);
    end;
  end;
for bnotej:=bnoten+1 to bnoten0 do
  begin
  bnote[0,bnotej]:=CreateBMP(GetWidth(),bnoteh0,black1);
  bnote[1,bnotej]:=CreateBMP(GetWidth(),bnoteh0,black1);
  end;
SetDrawFont();
for bnotej:=0 to bnoten0 do
  begin
  SetFont(bnote[0,bnotej]);
  SetFont(bnote[1,bnotej]);
  end;
bnoten:=bnoten0;
  }
end;

procedure InitBNote(force:boolean);
begin
EnterCriticalSection(cs4);
InitBnote0(force);
DrawMessureLineAll();
InitFNoteDraw(0,notemapn-1);
EnterCriticalSection(csnote);
if fb then FlushFNoteAll();
LeaveCriticalSection(csnote);
scrtime:=(GetHeight()-round(GetKeynoteW0()*kleny0))/(mult*GetWidth()/mult0);
delaytime:=scrtime;
if not(force) then
begin
for fni:=0 to notemapn-1 do
  begin
  if notemapn>0 then if fni and $FFF=0 then begin drawr:=fni/notemapn;DrawTitle();end;
  if fb then begin notemapi:=0;notemap[notemapi]:=GetFNote(fni);end else notemapi:=fni;
  if(notemap[notemapi].note1-notemap[notemapi].note0>delaytime)then DrawBNote(notemapi);
  end;
FlushBar(true);
{$ifdef D3D}FreshD3DAll();{$endif}
drawr:=0;
end;
notemapa:=0;
notemapb:=0;
GetDrawTime();
InitKbdC();
initb:=true;
LeaveCriticalSection(cs4);
end;

procedure DrawBNoteAll();
begin
EnterCriticalSection(cs1);
if initb=false then InitBNote(false);
notemapa:=SeekMidiTimeFNote(printtime-delaytime);
notemapb:=SeekMidiTimeFNote(printtime+scrtime);
GetFNoteDraw(notemapa,notemapb);
notemapb:=min(notemapa+$10000,notemapb);
if notemapn>0 then
for notemapi:=notemapa to notemapb do
  begin
  if (notemapb-notemapa)>0 then if (notemapi-notemapa) and $FFF=0 then begin drawr:=(notemapi-notemapa)/(notemapb-notemapa);DrawTitle();end;
  if GetFNoteDraw(notemapi)=false then DrawBNote(notemapi);
  end;
if notemapa<=notemapb then SetFNoteDraw(notemapa,notemapb);
FlushBar(true);
{$ifdef D3D}FreshD3DAll();{$endif}
drawr:=0;
LeaveCriticalSection(cs1);
end;

procedure DrawBNoteAll0();
var pauseb0:boolean;
begin
if bnoteb=true then
begin
EnterCriticalSection(cs1);
pauseb0:=pauseb;
if pauseb0=false then PauseMidi();
InitBNote(true);
for notemapi:=0 to notemapn-1 do
  begin
  if notemapn>0 then if notemapi and $FFF=0 then begin drawr:=notemapi/notemapn;DrawTitle();end;
  DrawBNote(notemapi);
  end;
SetFNoteDraw(0,notemapn-1);
FlushBar(true);
{$ifdef D3D}FreshD3DAll();{$endif}
drawr:=0;
bnoteb:=false;
if pauseb0=false then PauseMidi();
LeaveCriticalSection(cs1);
end;
end;

procedure DrawBNoteBB();
var y:longint;
var y0,h,h0:longword;
var bnotej:longint;
begin
EnterCriticalSection(cs1);
y:=min(bnoteh,round(printtime*mult*GetWidth()/mult0)+GetHeight());
if y>0 then
  begin
  y0:=bnoteh0-(y mod bnoteh0);
  bnotej:=y div bnoteh0;
  h:=0;
  repeat
  h0:=bnoteh0-y0;
  h0:=min(h0,max(0,GetHeight()-h));
  FreshBMP(0,bnotej);DrawBMP(bnote[0,bnotej1[0,bnotej]],0,y0,GetWidth(),h0,0,h,GetWidth(),h0);
  FreshBMP(1,bnotej);DrawBMP(bnote[1,bnotej1[1,bnotej]],0,y0,GetWidth(),h0,0,h,GetWidth(),h0);
  bnotej:=bnotej-1;
  h:=h+h0;
  y0:=0;
  until (h=GetHeight()) or (bnotej<0);
  end;
LeaveCriticalSection(cs1);
end;

procedure DrawTime();
begin
if max(0,finaltime-1)>0 then
  begin
  _Line(trunc(GetMidiTime()/max(0,finaltime-1)*GetWidth()),0,0,GetHeight(),white);
  _DrawTextXY_Top(t2s(min(max(0,finaltime-1),GetMidiTime()))+'/'+t2s(max(0,finaltime-1))+'('
    +i2s(max(0,trunc(min(max(0,finaltime-1),GetMidiTime())*100/max(0,finaltime-1))))+'%)',0,0,white);
  end;
end;

procedure DrawChannel();
var chani:longword=0;
var chanci0:longword=0;
begin
while chancn[chani]>0 do
  begin
  Bar(0,chani*fh+fh,fh,fh,chancc[chani]);
  DrawTextXY(i2s(chancn[chani]),fh,chani*fh+fh,chancc[chani]);
  chanci0:=chanci[chani];
  if chanci0 and $F=0 then chanci0:=chanci0 shr 12 else chanci0:=chanci0 and $F;
  DrawTextXY(i2s(chanci0,2),0,chani*fh+fh,black);
  chani:=chani+1;
  end;
end;

procedure DrawChord();
begin
if (max(0,finaltime-1)>0) then
  _DrawTextXY_Btm(GetKeyChordS(chord),0,0,white);
end;

procedure DrawBPM();
var bpm:double;
var bmps:ansistring='';
begin
if tempo>0 then bpm:=60000000/tempo*spd0 else bpm:=0;
if(bpm>=0)then
  begin
  bmps:=r2s(bpm)+' BPM';
  if round(spd0*100)<>100 then bmps:=bmps+'('+i2s(round(spd0*100))+'%)';
  _DrawTextXY_Btm(bmps,GetWidth()-fw*length(bmps),0,white);
  end;
end;

procedure DrawNoteN();
var notes:ansistring='';
var notemapi:longword;
begin
notemapi:=SeekMidiTimeFNote(printtime);
notes:=i2s(notemapi)+'/'+i2s(notemapn);
SetDrawFont(1.5);
_DrawTextXY_Top(notes,(GetWidth()-fw*length(notes))div 2,0,white);
SetDrawFont();
end;

procedure DrawFPS();
var fpss:ansistring='';
begin
fpss:=i2s(GetFPS())+'/'+i2s(framerate);
if abs(GetFPSR-framerate)>1 then
  _DrawTextXY_Top(fpss,GetWidth()-fw*length(fpss),_fh,white);
end;

var hinttime:double=-3;
var hints:ansistring;

procedure SetHint(s:ansistring;v:ansistring);
begin
hinttime:=GetTimeR();
hints:=s+': '+v;
end;

procedure DrawHint();
begin
if GetTimeR()<hinttime+1 then
  begin
  _DrawTextXY_Mid(hints,(GetWidth()-fw*length(hints))div 2,0,white);
  end;
end;

procedure DrawLongMsg();
begin
if kbdc0p>0 then _DrawTextXY_Top(i2s(kbdc0m0)+'/'+i2s(kbdc0p),GetWidth()-fw*length(i2s(kbdc0m0)+'/'+i2s(kbdc0p)),0,white);
if msgbufnmax>0 then _DrawTextXY_Top(i2s(msgbufnmax),GetWidth()-fw*length(i2s(msgbufnmax)),_fh*2,white);
end;

procedure DrawReal();
begin
if drawr>0 then
  begin
  Line(0,GetHeight() div 2,GetWidth(),0,black);
  Line(0,GetHeight() div 2,round(drawr*GetWidth()),0,white);
  end;
end;

var menuw_,menuh_:longword;
var menuwh_:double;

var moused:boolean;
var moused1:boolean;
var mousex,mousey:double;
var mousepx,mousepy:longword;
var mousepx0,mousepy0:longword;
var mousepx1,mousepy1:longword;
var mousexc,mousexcp:double;

var ctrlt:double;
var ctrlb:boolean=false;
var menub:boolean=false;
var menui:real;
const menuh:real=0.03;
const menug:real=0.01;
const menuy:real=0.06;
const menul0:real=0.2;
const menul1:real=0.3;
const menur1:real=0.75;
const menur0:real=0.8;
const menum:real=0.1;
{$ifdef video}
const menum0:real=0.5;
{$endif}
const menum1:real=0.525;


var vi:longint;
var menuw,menur,menuwb:real;
const menut:array[1..7]of ansistring=('?','|<','<','.','>','>|','*');

procedure DrawTextPercent(x1,x2,y1,y2:double;s:ansistring;c:longword);
begin DrawTextXY(s,round(((x1+x2)*menuw_-length(s)*fw)/2),round(((y1+y2)*menuh_-fh)/2),c);end;

procedure DrawTextPercent(x1,x2,y:double;s:ansistring;c:longword);
begin DrawTextXY(s,round(((x1+x2)*menuw_-length(s)*fw)/2),round(y*menuh_-fh/2),c);end;

procedure DrawTextPercent(x,y:double;s:ansistring;c:longword);
begin DrawTextXY(s,round(x*menuw_),round(y*menuh_-fh/2),c);end;

procedure DrawBarPercent(x1,x2,y1,y2:double;cf,cg:longword;p:shortint);
begin
if (x1<=mousex) and (mousex<=x2) and (y1<=mousey) and (mousey<=y2) then
  begin
  case p of
    1:mousepx0:=round(x1*1000);
    2:mousepx0:=round((x1+x2)/2*1000);
    3:mousepx0:=round(x2*1000);
    end;
  mousepy0:=round(y1*1000);
  cg:=gray2;
  moused:=(moused1) and (mousepx1=mousepx0) and (mousepy1=mousepy0);
  if moused then
    if (cf<>transparent) then cf:=gray2;
  end;
Bar(round(x1*menuw_),round(y1*menuh_),round(x2*menuw_)-round(x1*menuw_),round(y2*menuh_)-round(y1*menuh_),cg,cf);
end;

procedure DrawBarPercent(x1,x2,y1,y2:double;c:longword);
begin Bar(round(x1*menuw_),round(y1*menuh_),round(x2*menuw_)-round(x1*menuw_),round(y2*menuh_)-round(y1*menuh_),c);end;

procedure DrawCirclePercent(x,y,r:double;cf,cg:longword);
begin
if (x-r/menuwh_<=mousex) and (mousex<=x+r/menuwh_) and (y-r<=mousey) and (mousey<=y+r) then
  begin
  if (cf=transparent) then
    begin
    cg:=gray2;
    if moused then cf:=gray2;
    //Bar(round(x*menuw_-r*menuh_),round(y*menuh_-r*menuh_),round(r*2*menuh_),round(r*2*menuh_),cg,gray0);
    end;
  end;
Circle(round(x*menuw_),round(y*menuh_),round(r/3*2*menuh_),cg,cf);
end;

procedure DrawMenuTitle(s:ansistring);
begin
menui:=menui+menug;
DrawBarPercent(menul0,menur0,menui-menug,menui+menuh+menug,gray1);
DrawTextPercent(menul0,menur0,menui,menui+menuh,s,white);
menui:=menui+menuh;
menui:=menui+menug;
end;

procedure DrawMenuBar(s:ansistring;v:double;m:longword;n:ansistring);
begin
DrawTextPercent(menul0,menui+menuh/2,s,white);
menur:=menuh/2;
menuw:=menuh/menuwh_;
menuwb:=menuw*1.5;
DrawBarPercent(menul1+menuwb,menur1-menuwb,menui,menui+menuh,transparent,graym,2);
if m>0 then begin
  if m<=50 then for vi:=0 to m do
    DrawCirclePercent(menul1+menuwb+menuw/2+(menur1-menul1-menuw-menuwb*2)/m*vi,menui+menur,menur,gray0,gray1);
  DrawCirclePercent(menul1+menuwb+menuw/2+(menur1-menul1-menuw-menuwb*2)/m*v,menui+menur,menur,gray1,gray1);
  if (menui<=mousey) and (mousey<=menui+menur*2) then
    DrawCirclePercent(mousexc,menui+menur,menur,transparent,gray1);
  end
else
  begin
  DrawBarPercent(menul1+menuwb,menur1-menuwb,menui,menui+menuh,gray0,graym,2);
  DrawTextPercent(menul1+menuwb,menur1-menuwb,menui,menui+menuh,smidiout,white);
  end;
DrawBarPercent(menul1,menul1+menuwb,menui,menui+menuh,gray1,graym,1);
DrawBarPercent(menur1-menuwb,menur1,menui,menui+menuh,gray1,graym,3);
DrawTextPercent(menul1,menul1+menuwb,menui,menui+menuh,'-',white);
DrawTextPercent(menur1-menuwb,menur1,menui,menui+menuh,'+',white);
DrawTextPercent(menur1,menur0,menui+menuh/2,n,white);
menui:=menui+menuh;
end;

procedure DrawMenuBtn(s:ansistring;v,m:longword;n:array of ansistring);
var ni:longword;
begin
DrawTextPercent(menul0,menui+menuh/2,s,white);
for vi:=0 to m-1 do
  DrawBarPercent(menul1+vi*menum,menul1+(vi+1)*menum,menui,menui+menuh,gray0,graym,1);
DrawBarPercent(menul1+v*menum,menul1+(v+1)*menum,menui,menui+menuh,gray1,graym,1);
for ni:=0 to 4 do
  if m>=ni+1 then DrawTextPercent(menul1+menum*ni,menul1+menum*(ni+1),menui+menuh/2,n[ni],white);
menui:=menui+menuh;
end;

procedure DrawMenuLine(x1,x2,y1,y2:double;s:ansistring);
begin
DrawBarPercent(x1,x2,y1,y2,gray0,graym,1);
DrawTextPercent(x1,x2,y1,y2,s,white);
end;

procedure SetMenuFont();
begin
menui:=menuy;
fh:=max(1,round(menuh*menuh_*klen1*1.5));
fw:=max(1,round(fh/2.2));
SetFontSize(fw,fh);
SetFont();
end;

procedure SetCtrlFont();
begin
menui:=menuy;
fh:=max(1,round(menuh*menuh_*klen1*3));
fw:=max(1,round(fh/2.2));
SetFontSize(fw,fh);
SetFont();
end;

function log2(v:double):double;begin log2:=v;if v>=1 then log2:=ln(v)/ln(2)+1;if v<=-1 then log2:=-ln(-v)/ln(2)-1;end;
function exp2r(v:double):double;begin exp2r:=v;if v>=1 then exp2r:=exp((v-1)*ln(2));if v<=-1 then exp2r:=-exp((-v-1)*ln(2));end;
function exp2(v:double):longint;begin exp2:=round(exp2r(v));end;
function sgn(v:double):longint;begin if v>=0 then sgn:=1 else sgn:=0;end;

const msgbufb1_s:array[0..4]of ansistring=('Long','Stream','','','');
const msgbufb0_s:array[0..4]of ansistring=('Yes','No','','','');
const autofresh_s:array[0..4]of ansistring=('Auto','Manual','','','');
const kbdcb_s:array[0..4]of ansistring=('Chord','Track Black','Track','','');
const kchb_s:array[0..4]of ansistring=('Number','Letter','Blank','','');
const kchb2_s:array[0..4]of ansistring=('All','No Track','No Message','Key','None');
const kmessure_s:array[0..4]of ansistring=('Minor','All','Major','Chord','None');
const loop_s:array[0..4]of ansistring=('Single','All','None','','');
const fbi_s:array[0..4]of ansistring=('Memory','File','','','');

procedure DrawMenu();
begin
SetMenuFont();
DrawBarPercent(menul0,menur0,menuy,menuy+menuh*26+menug*5*2,gray0);
DrawMenuTitle('Play');
DrawMenuBar('Volumn',voli-1,15,i2s(longword(round(vola[voli]*100)))+'%');
DrawMenuBar('Speed',sgn(spd1-100)*(log2(spd1/100)+4)+sgn(99.99-spd1)*(spd1/20),9,i2s(spd1)+'%');
DrawMenuBar('Chord',kchord0,11,i2s(kchord0));
DrawMenuBar('Pitch',log2(kkey0-128)+8,16,i2s(longint(kkey0-128)));
DrawMenuTitle('Device');
DrawMenuBar('Synthesizer',0,0,i2s(midiouti+1)+'/'+i2s(midiOutGetNumDevs));
DrawMenuBtn('MIDI Event',1-msgbufb1,2,msgbufb1_s);
DrawMenuBtn('Combine Notes',1-msgbufb0,2,msgbufb0_s);
DrawMenuTitle('Display');
DrawMenuBtn('Draw Notes',1-autofresh,2,autofresh_s);
DrawMenuBar('Note Length',mult/100,10,i2s(mult)+'%');
DrawMenuBtn('Note Color',kbdcb,3,kbdcb_s);
DrawMenuBtn('Note Text',kchb,3,kchb_s);
DrawMenuBtn('Info Text',kchb2,5,kchb2_s);
DrawMenuBtn('Messur Line',kmessure,5,kmessure_s);
DrawMenuBtn('Loop Mode',(loop+2)mod 3,3,loop_s);
DrawMenuTitle('Options');
DrawMenuBtn('Storage',fbi,2,fbi_s);
DrawMenuBar('Short Event',log2(msgbufn0)-1,24,i2s(round(log2(msgbufn0))-1));
DrawMenuBar('Min Volume',log2(msgvol0+1)-1,7,i2s(msgvol0));
DrawMenuBar('Max Key',log2(maxkbdc)-1,16,i2s(round(log2(maxkbdc))-1));
DrawMenuBar('Frame Rate',framerate/60,8,i2s(framerate));
DrawMenuTitle('Others');
{$ifdef video}
DrawMenuLine(menul0,menum0,menui,menui+menuh*2,'Record Video');
DrawMenuLine(menum0,menur0,menui,menui+menuh*2,'Reset All Settings');
{$else}
DrawMenuLine(menul0,menur0,menui,menui+menuh*2,'Reset All Settings');
{$endif}
SetDrawFont();
end;

procedure DrawCtrl();
begin
SetCtrlFont();
for vi:=1 to 7 do
  DrawMenuLine(menul0+(vi-1)*(menur0-menul0)/7,menul0+vi*(menur0-menul0)/7,1-menuy,1,menut[vi]);
SetDrawFont();
end;

procedure DrawMenuAll();
begin
if GetWidth()>0 then menuw_:=GetWidth();
if GetHeight()>0 then menuh_:=GetHeight();
if (menuw_>0) and (menuh_>0) then
  begin
  menuwh_:=menuw_/menuh_;
  if (GetMousePosX/menuw_<>mousex) and (GetMousePosY/menuh_<>mousey) then
    begin ctrlb:=true;ctrlt:=GetTimeR();end;
  mousex:=GetMousePosX/menuw_;mousey:=GetMousePosY/menuh_;
  mousexc:=min(max(mousex,menul1+menuwb+menuw/2),menur1-menuwb-menuw/2);
  mousexcp:=(mousexc-(menul1+menuwb+menuw/2))/((menur1-menuwb-menuw/2)-(menul1+menuwb+menuw/2));
  end;
if GetTimeR()>ctrlt+0.5 then ctrlb:=false;
if mousey>=1-menuy then ctrlb:=true;
mousepx0:=0;mousepy0:=0;
if menub then DrawMenu();
if ctrlb or menub then DrawCtrl();
mousepx:=mousepx0;mousepy:=mousepy0;
end;

procedure DrawAll();
begin
SetDrawFont();
Clear();
GetDrawTime();
DrawNoteLine();
DrawBNoteAll0();
DrawBNoteAll();
DrawBNoteBB();
DrawKeyboard();
if kchb2<=2 then DrawTime();
if kchb2<=0 then DrawChannel();
if kchb2<=2 then DrawChord();
if kchb2<=2 then DrawBPM();
if kchb2<=3 then DrawNoteN();
if kchb2<=2 then DrawLongMsg();
if kchb2<=1 then {$ifdef video}if not(videob)then{$endif}DrawFPS();
{$ifdef video}if not(videob) then {$endif}DrawMenuAll();
{$ifdef video}if not(videob) then {$endif}DrawHint();
DrawReal();
FreshWin();
end;

procedure DrawTitle();
var stitle0,stitle1:ansistring;
var miditime,curtime:double;
begin
stitle0:='';
stitle1:='';
miditime:=max(0,finaltime-1);
curtime:=max(0,min(miditime,GetMidiTime()));
if (miditime>0) then
  begin
  stitle0:='('+i2s(trunc(curtime/miditime*100))+'%)';
  stitle1:='<'+i2s(find_current)+'/'+i2s(find_count)+':'+loop_s[(loop+2)mod 3]+'>';
  stitle1:=stitle1+'['+GetKeyChordS(chord)+']';
  end;
if voli<>14 then stitle1:=stitle1+'(volumn:'+i2s(longword(round(vola[voli]*100)))+'%)';
if spd1<>100 then stitle1:=stitle1+'[speed:'+i2s(spd1)+'%]';
if kkey0<>128 then stitle1:=stitle1+'<pitch:'+i2s(longint(kkey0-128))+'>';
if mult<>100 then stitle1:=stitle1+'<note:'+i2s(mult)+'%>';
if drawr>0 then stitle0:='<load:'+i2s(trunc(drawr*100))+'%>'+stitle0;
SetTitleW(UnicodeString(stitle0)+GetFileNameW(fnames)+UnicodeString(stitle1));
end;

{$ifdef video}
var vnamec:pchar;
var vsz:longint=0;
var videobb:pbitbuf;
{$endif}

procedure DrawProc();
begin
repeat
if GetTimeR()>frametime+1/framerate then
  begin
  while GetTimeR()>frametime+1/framerate do frametime:=frametime+1/framerate;
  if not(IsIconic(GetHWnd())) then DrawAll();
  DrawTitle();
  end
else
  Delay(1);
{$ifdef video}
if videob then
  begin
  vnamec:=PChar(vname);
  videotime:=-1;
  while(_w and 1=1)or(_h and 1=1)do
    begin
    vsz:=vsz+1;
    SetSize((_w shr vsz) shl vsz,(_h shr vsz) shl vsz);
    end;
  videobb:=CreateBB(GetWin());
  EncodeVideo(vnamec,vrate,vquality);
  if not(pauseb) then PauseMidi();
  SetMidiTime(begintime);
  while (videotime<finaltime) and (IsWin()) do
    begin
    //SetMidiTime(videotime);
    DrawAll();
    Display.GetBB(videobb);
    EncodeFrame(videobb);
    videotime:=videotime+1/vrate;
    end;
  ReleaseVideo();
  ReleaseBB(videobb);
  SetMidiTime(begintime);
  PauseMidi();
  videotime:=-1;
  end;
videob:=false;
{$endif}
until not(iswin());
end;

procedure ResetMidi();
begin
spd0:=1;
eventi:=0;
pauseb:=false;
InitMidiChanVol($7F);
SetMidiTime(begintime);
end;

procedure ResetMidiSoft();
var tmptime:double;
begin
tmptime:=GetMidiTime();
InitMidiChanVol($7F);
SetMidiTime(begintime);
SetMidiTime(tmptime);
end;

procedure ResetMidiHard(i:longint;b:longword);
var n:longword;
var caps:MIDIOUTCAPS;
begin
n:=midiOutGetNumDevs();
if n>0 then midiOuti:=(i+n) mod n else midiOuti:=0;
if midiOut>0 then
  if msgbufb1=1 then
    midiOutClose(midiOut)
  else
    midiStreamClose(midiOut);
midiOutGetDevCaps(midiOuti,@caps,sizeof(caps));
smidiout:=caps.szPname+'(Loading...)';
msgbufb1:=b;
if msgbufb1=1 then
  midiOutOpen(@midiOut,midiOuti,0,0,0)
else
  midiStreamOpen(@midiOut,@midiOuti,DWORD(1),0,0,0);
smidiout:=caps.szPname;
ResetMidiSoft();
end;

procedure ResetMidiHard(i:longint);
begin ResetMidiHard(i,msgbufb1);end;

var startb:boolean=true;

procedure PlayMidi(fname:UnicodeString);
begin
if IsFileW(fname) then
  begin
  if pauseb=false then PauseMidi();
  SetMidiTime(begintime);
  find_file(fname);
  fnames:=fname;
  EnterCriticalSection(cs2);
  maxevent:=1;
  event:=nil;setlength(event,maxevent);
  event0:=nil;setlength(event0,maxevent);
  if fb then
    begin
    EnterCriticalSection(csfevent0);
    close(fevent);rewrite(fevent);feventw:=true;for bjfeventi:=0 to maxfeventm-1 do bjfevent[bjfeventi]:=-1;
    close(fevent0);rewrite(fevent0);fevent0w:=true;bjfevent0:=-1;
    EnterCriticalSection(csnote);
    notemap:=nil;setlength(notemap,maxevent);
    close(fnote); rewrite(fnote);fnotew:=true;for bjfnotei:=0 to maxfnotem-1 do bjfnote[bjfnotei]:=-1;bjfnotek:=-1;
    LeaveCriticalSection(csnote);
    LeaveCriticalSection(csfevent0);
    end;
  LoadMidi(fname);
  PrepareMidi();
  LeaveCriticalSection(cs2);
  EnterCriticalSection(cs1);
  ResetNoteMap();
  //MakeChord();
  ResetMidi();
  initb:=false;
  if startb=false then
    begin
    spd1:=100;
    kchord0:=0;
    kkey0:=128;
    end;
  spd0:=spd1/100;
  startb:=false;
  LeaveCriticalSection(cs1);
  if autofresh=1 then bnoteb:=true;
  //midipos:=round((GetMidiTime()+1)*1000);
  SaveReg();
  while IsNextMsg() do ;
  end;
end;

procedure ResetAll();
begin
ResetReg();
ResetNoteMap();
SetMidiVol(volamax-2);
SetMidiSpd(spd1);
ResetMidiHard(midiOuti);
SaveReg();
initb:=false;
PlayMidi(fnames);
end;

var fdir:unicodestring;
var fpara:unicodestring='';

procedure helpproc();
begin
  if IsFileW(fdir+UnicodeString('README.md')) then
    ShellExecuteW(0,nil,PWChar('notepad.exe'),PWChar(fdir+UnicodeString('README.md')),nil,1)
  else
    MsgboxW(UnicodeString('Missing help file: ')+fdir+UnicodeString('README.md'),UnicodeString('Help file not found!'));
  helpb:=1;
end;

procedure DoAct();
begin
if ismsg(WM_USER) then
  begin
  if _ms.lParam=0 then fpara:=fpara+widechar(_ms.wParam mod $10000);
  if _ms.lParam=1 then fpara:='';
  if _ms.lParam=2 then PlayMidi(fpara);
  end;
if isDropFile() then
  PlayMidi(GetDropFileW());
if (GetSize>0) and (GetSize()<>sz) then
  begin
  sz:=GetSize();
  initb:=false;
  end;
if iskey() then
  begin
  k_shift:=GetKeyState(VK_SHIFT)<0;
  k_ctrl:=GetKeyState(VK_CONTROL)<0;
  if iskey(K_SPACE) then begin PauseMidi();end;
  k_pos:=1;if k_ctrl then k_pos:=5;if k_shift then k_pos:=30;
  if iskey(K_LEFT) then begin SetMidiTime(GetMidiTime()-k_pos);end;
  if iskey(K_RIGHT) then begin SetMidiTime(GetMidiTime()+k_pos);end;
  if iskey(K_UP) then begin SetMidiVol(voli+1);SetHint('Volumn',i2s(longword(round(vola[voli]*100)))+'%');end;
  if iskey(K_DOWN) then begin SetMidiVol(voli-1);SetHint('Volumn',i2s(longword(round(vola[voli]*100)))+'%');end;
  k_pos:=0.1;if k_ctrl then k_pos:=0.03;if k_shift then k_pos:=0.01;
  if iskey(K_ADD) or iskey(187) then begin SetMidiSpd(round((spd0+k_pos)*100));SetHint('Speed',i2s(spd1)+'%');end;
  if iskey(K_SUB) or iskey(189) then begin SetMidiSpd(round((spd0-k_pos)*100));SetHint('Speed',i2s(spd1)+'%');end;
  if iskey(221) then begin SetMidiChord(kchord0+1);SetHint('Chord',i2s(kchord0));end;
  if iskey(219) then begin SetMidiChord(kchord0+11);SetHint('Chord',i2s(kchord0));end;
  if iskey(222) then begin SetMidiPitch(kkey0+1);SetHint('Pitch',i2s(longint(kkey0-128)));end;
  if iskey(186) then begin SetMidiPitch(kkey0-1);SetHint('Pitch',i2s(longint(kkey0-128)));end;
  if iskey(K_PGUP) then begin PlayMidi(get_file(find_current-1));end;
  if iskey(K_PGDN) then begin PlayMidi(get_file(find_current+1));end;
  if iskey(K_HOME) then begin PlayMidi(get_file(1));end;
  if iskey(K_END) then begin PlayMidi(get_file(find_count));end;
  if iskey(K_F) then begin PlayMidi(get_file(find_current));end;
  if iskey(K_H) then begin ResetMidiHard(midiOuti);SetHint('Synthesizer',smidiout+'('+i2s(midiouti+1)+'/'+i2s(midiOutGetNumDevs)+')');end;
  if iskey(K_S) and not(k_shift) and not(k_ctrl) then begin ResetMidiHard(midiOuti+1);SetHint('Synthesizer',smidiout+'('+i2s(midiouti+1)+'/'+i2s(midiOutGetNumDevs)+')');end;
  if iskey(K_S) and not(k_shift) and (k_ctrl) then begin ResetMidiHard(midiOuti,1-msgbufb1);SetHint('MIDI Event',msgbufb1_s[msgbufb1]);end;
  if iskey(K_S) and (k_shift) and not(k_ctrl) then begin msgbufb0:=1-msgbufb0;SetHint('Combine Notes',msgbufb0_s[msgbufb0]);end;
  if iskey(K_D) then begin bnoteb:=true;end;
  if iskey(K_A) then begin autofresh:=1-autofresh;SetHint('Draw Notes',autofresh_s[1-autofresh]);end;
  k_pos:=10;if k_ctrl then k_pos:=3;if k_shift then k_pos:=1;
  if iskey(188) then begin SetNoteLength(mult-round(k_pos));SetHint('Note Length',i2s(mult)+'%');end;
  if iskey(190) then begin SetNoteLength(mult+round(k_pos));SetHint('Note Length',i2s(mult)+'%');end;
  if iskey(K_C) then begin kbdcb:=(kbdcb+1)mod 3;initb:=false;SetHint('Note Color',kbdcb_s[kbdcb]);end;
  if iskey(K_T) then begin kchb:=(kchb+1) mod 3;initb:=false;SetHint('Note Text',kchb_s[kchb]);end;
  if iskey(K_I) then begin kchb2:=(kchb2+1) mod 5;SetHint('Info Text',kchb2_s[kchb2]);end;
  if iskey(K_L) then begin kmessure:=(kmessure+1) mod 5;initb:=false;SetHint('Messur Line',kmessure_s[kmessure]);end;
  if iskey(K_M) then begin loop:=(loop+1) mod 3;SetHint('Loop Mode',loop_s[(loop+2)mod 3]);end;
  if iskey(K_F2) then begin fbi:=1-fbi;SetHint('Storage',fbi_s[fbi]);end;
  if iskey(K_F3) then begin msgbufn0:=max(1,msgbufn0 shr 1);SetHint('Short Event',i2s(round(log2(msgbufn0))-1));end;
  if iskey(K_F4) then begin msgbufn0:=min($1000000,msgbufn0 shl 1);SetHint('Short Event',i2s(round(log2(msgbufn0))-1));end;
  if iskey(K_F5) then begin msgvol0:=max(0,msgvol0-1);SetHint('Min Volume',i2s(msgvol0));end;
  if iskey(K_F6) then begin msgvol0:=min($7F,msgvol0+1);SetHint('Min Volume',i2s(msgvol0));end;
  if iskey(K_F7) then begin maxkbdc:=max(1,maxkbdc shr 1);InitKbdC();SetHint('Max Key',i2s(round(log2(maxkbdc))-1));end;
  if iskey(K_F8) then begin maxkbdc:=min(maxkbdc0,maxkbdc shl 1);InitKbdC();SetHint('Max Key',i2s(round(log2(maxkbdc))-1));end;
  if iskey(K_F11) then begin framerate:=max(1,framerate-((framerate-1) div 60+1));SetHint('Frame Rate',i2s(framerate));end;
  if iskey(K_F12) then begin framerate:=min(480,framerate+(framerate div 60+1));SetHint('Frame Rate',i2s(framerate));end;
  if iskey(K_F1) then begin newthread(@helpproc);end;
  if iskey(K_F9) then begin menub:=not(menub);end;
  if iskey(K_R) then begin ResetAll();end;
  {$ifdef video}
  if iskey(K_V) then begin bnoteb:=true;videob:=true;end;
  {$endif}
  if iskey(K_ESC) then begin CloseWin();end;
  end;
if not((mousepx1=mousepx) and (mousepy1=mousepy)) then moused1:=false;
if IsMsg(WM_LBUTTONDOWN) then
  begin
  mousepx1:=mousepx;
  mousepy1:=mousepy;
  if (mousepx>0) or (mousepy>0) then moused1:=true;
  end;
if IsMsg(WM_LBUTTONUP) then
  begin
  if moused1 then
    begin
    k_shift:=GetKeyState(VK_SHIFT)<0;
    k_ctrl:=GetKeyState(VK_CONTROL)<0;
    if (mousepx1=0) and (mousepy1=0) then ;
    if (mousepx1=round(menul1*1000)) and (mousepy1=round((menuy+menug*1*2+menuh*1)*1000)) then begin SetMidiVol(voli-1);end;
    if (mousepx1=round(menur1*1000)) and (mousepy1=round((menuy+menug*1*2+menuh*1)*1000)) then begin SetMidiVol(voli+1);end;
    if (mousepx1=round(menum1*1000)) and (mousepy1=round((menuy+menug*1*2+menuh*1)*1000)) then begin SetMidiVol(round(mousexcp*15)+1);end;
    k_pos:=0.1;if k_ctrl then k_pos:=0.03;if k_shift then k_pos:=0.01;
    if (mousepx1=round(menul1*1000)) and (mousepy1=round((menuy+menug*1*2+menuh*2)*1000)) then begin SetMidiSpd(round((spd0-k_pos)*100));end;
    if (mousepx1=round(menur1*1000)) and (mousepy1=round((menuy+menug*1*2+menuh*2)*1000)) then begin SetMidiSpd(round((spd0+k_pos)*100));end;
    if (mousepx1=round(menum1*1000)) and (mousepy1=round((menuy+menug*1*2+menuh*2)*1000)) then begin spdx:=mousexcp*9;SetMidiSpd(round(sgn(spdx-5)*exp2r(spdx-4)*100+sgn(4.999-spdx)*(spdx*20)));end;
    if (mousepx1=round(menul1*1000)) and (mousepy1=round((menuy+menug*1*2+menuh*3)*1000)) then begin SetMidiChord(kchord0+11);end;
    if (mousepx1=round(menur1*1000)) and (mousepy1=round((menuy+menug*1*2+menuh*3)*1000)) then begin SetMidiChord(kchord0+1);end;
    if (mousepx1=round(menum1*1000)) and (mousepy1=round((menuy+menug*1*2+menuh*3)*1000)) then begin SetMidiChord(round(mousexcp*11));end;
    if (mousepx1=round(menul1*1000)) and (mousepy1=round((menuy+menug*1*2+menuh*4)*1000)) then begin SetMidiPitch(kkey0-1);end;
    if (mousepx1=round(menur1*1000)) and (mousepy1=round((menuy+menug*1*2+menuh*4)*1000)) then begin SetMidiPitch(kkey0+1);end;
    if (mousepx1=round(menum1*1000)) and (mousepy1=round((menuy+menug*1*2+menuh*4)*1000)) then begin SetMidiPitch(exp2(mousexcp*16-8)+128);end;
    if (mousepx1=round(menul1*1000)) and (mousepy1=round((menuy+menug*2*2+menuh*6)*1000)) then begin ResetMidiHard(midiOuti-1);end;
    if (mousepx1=round(menur1*1000)) and (mousepy1=round((menuy+menug*2*2+menuh*6)*1000)) then begin ResetMidiHard(midiOuti+1);end;
    if (mousepx1=round(menum1*1000)) and (mousepy1=round((menuy+menug*2*2+menuh*6)*1000)) then begin ResetMidiHard(midiOuti);end;
    if (mousepx1=round((menul1+menum*0)*1000)) and (mousepy1=round((menuy+menug*2*2+menuh*7)*1000)) then begin ResetMidiHard(midiOuti,1);end;
    if (mousepx1=round((menul1+menum*1)*1000)) and (mousepy1=round((menuy+menug*2*2+menuh*7)*1000)) then begin ResetMidiHard(midiOuti,0);end;
    if (mousepx1=round((menul1+menum*0)*1000)) and (mousepy1=round((menuy+menug*2*2+menuh*8)*1000)) then begin msgbufb0:=1;end;
    if (mousepx1=round((menul1+menum*1)*1000)) and (mousepy1=round((menuy+menug*2*2+menuh*8)*1000)) then begin msgbufb0:=0;end;
    if (mousepx1=round((menul1+menum*0)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*10)*1000)) then begin autofresh:=1;end;
    if (mousepx1=round((menul1+menum*1)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*10)*1000)) then begin autofresh:=0;end;
    k_pos:=10;if k_ctrl then k_pos:=3;if k_shift then k_pos:=1;
    if (mousepx1=round(menul1*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*11)*1000)) then begin SetNoteLength(mult-round(k_pos));end;
    if (mousepx1=round(menur1*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*11)*1000)) then begin SetNoteLength(mult+round(k_pos));end;
    if (mousepx1=round(menum1*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*11)*1000)) then begin SetNoteLength(round(mousexcp*1000));end;
    if (mousepx1=round((menul1+menum*0)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*12)*1000)) then begin kbdcb:=0;initb:=false;end;
    if (mousepx1=round((menul1+menum*1)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*12)*1000)) then begin kbdcb:=1;initb:=false;end;
    if (mousepx1=round((menul1+menum*2)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*12)*1000)) then begin kbdcb:=2;initb:=false;end;
    if (mousepx1=round((menul1+menum*0)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*13)*1000)) then begin kchb:=0;initb:=false;end;
    if (mousepx1=round((menul1+menum*1)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*13)*1000)) then begin kchb:=1;initb:=false;end;
    if (mousepx1=round((menul1+menum*2)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*13)*1000)) then begin kchb:=2;initb:=false;end;
    if (mousepx1=round((menul1+menum*0)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*14)*1000)) then begin kchb2:=0;end;
    if (mousepx1=round((menul1+menum*1)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*14)*1000)) then begin kchb2:=1;end;
    if (mousepx1=round((menul1+menum*2)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*14)*1000)) then begin kchb2:=2;end;
    if (mousepx1=round((menul1+menum*3)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*14)*1000)) then begin kchb2:=3;end;
    if (mousepx1=round((menul1+menum*4)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*14)*1000)) then begin kchb2:=4;end;
    if (mousepx1=round((menul1+menum*0)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*15)*1000)) then begin kmessure:=0;initb:=false;end;
    if (mousepx1=round((menul1+menum*1)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*15)*1000)) then begin kmessure:=1;initb:=false;end;
    if (mousepx1=round((menul1+menum*2)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*15)*1000)) then begin kmessure:=2;initb:=false;end;
    if (mousepx1=round((menul1+menum*3)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*15)*1000)) then begin kmessure:=3;initb:=false;end;
    if (mousepx1=round((menul1+menum*4)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*15)*1000)) then begin kmessure:=4;initb:=false;end;
    if (mousepx1=round((menul1+menum*0)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*16)*1000)) then begin loop:=1;end;
    if (mousepx1=round((menul1+menum*1)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*16)*1000)) then begin loop:=2;end;
    if (mousepx1=round((menul1+menum*2)*1000)) and (mousepy1=round((menuy+menug*3*2+menuh*16)*1000)) then begin loop:=0;end;
    if (mousepx1=round((menul1+menum*0)*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*18)*1000)) then begin fbi:=0;end;
    if (mousepx1=round((menul1+menum*1)*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*18)*1000)) then begin fbi:=1;end;
    if (mousepx1=round(menul1*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*19)*1000)) then begin msgbufn0:=max(1,msgbufn0 shr 1);end;
    if (mousepx1=round(menur1*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*19)*1000)) then begin msgbufn0:=min($1000000,msgbufn0 shl 1);end;
    if (mousepx1=round(menum1*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*19)*1000)) then begin msgbufn0:=exp2(round(mousexcp*24)+1);end;
    if (mousepx1=round(menul1*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*20)*1000)) then begin msgvol0:=max(0,msgvol0-1);end;
    if (mousepx1=round(menur1*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*20)*1000)) then begin msgvol0:=min($7F,msgvol0+1);end;
    if (mousepx1=round(menum1*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*20)*1000)) then begin msgvol0:=exp2(mousexcp*7+1)-1;end;
    if (mousepx1=round(menul1*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*21)*1000)) then begin maxkbdc:=max(1,maxkbdc shr 1);InitKbdC();end;
    if (mousepx1=round(menur1*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*21)*1000)) then begin maxkbdc:=min(maxkbdc0,maxkbdc shl 1);InitKbdC();end;
    if (mousepx1=round(menum1*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*21)*1000)) then begin maxkbdc:=exp2(round(mousexcp*16)+1);InitKbdC();end;
    if (mousepx1=round(menul1*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*22)*1000)) then begin framerate:=max(1,framerate-((framerate-1) div 60+1));end;
    if (mousepx1=round(menur1*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*22)*1000)) then begin framerate:=min(480,framerate+(framerate div 60+1));end;
    if (mousepx1=round(menum1*1000)) and (mousepy1=round((menuy+menug*4*2+menuh*22)*1000)) then begin framerate:=round(mousexcp*479)+1;end;
    {$ifdef video}
    if (mousepx1=round(menul0*1000)) and (mousepy1=round((menuy+menug*5*2+menuh*24)*1000)) then begin bnoteb:=true;videob:=true;end;
    if (mousepx1=round(menum0*1000)) and (mousepy1=round((menuy+menug*5*2+menuh*24)*1000)) then begin ResetAll();end;
    {$else}
    if (mousepx1=round(menul0*1000)) and (mousepy1=round((menuy+menug*5*2+menuh*24)*1000)) then begin ResetAll();end;
    {$endif};
    if (mousepx1=round((menul0*7+menur0*0)/7*1000)) and (mousepy1=round((menuy+menug*5*2+menuh*26)*1000)) then begin newthread(@helpproc);end;
    if (mousepx1=round((menul0*6+menur0*1)/7*1000)) and (mousepy1=round((menuy+menug*5*2+menuh*26)*1000)) then begin PlayMidi(get_file(1));end;
    if (mousepx1=round((menul0*5+menur0*2)/7*1000)) and (mousepy1=round((menuy+menug*5*2+menuh*26)*1000)) then begin PlayMidi(get_file(find_current-1));end;
    if (mousepx1=round((menul0*4+menur0*3)/7*1000)) and (mousepy1=round((menuy+menug*5*2+menuh*26)*1000)) then begin PlayMidi(get_file(find_current));end;
    if (mousepx1=round((menul0*3+menur0*4)/7*1000)) and (mousepy1=round((menuy+menug*5*2+menuh*26)*1000)) then begin PlayMidi(get_file(find_current+1));end;
    if (mousepx1=round((menul0*2+menur0*5)/7*1000)) and (mousepy1=round((menuy+menug*5*2+menuh*26)*1000)) then begin PlayMidi(get_file(find_count));end;
    if (mousepx1=round((menul0*1+menur0*6)/7*1000)) and (mousepy1=round((menuy+menug*5*2+menuh*26)*1000)) then begin menub:=not(menub);end;
    end;
  moused1:=false;
  mousepx1:=0;
  mousepy1:=0;
  end;
if not(menub) then
if GetMousePosY()<GetHeight()-round(GetKeynoteW0()*kleny0) then
  begin
  if ismouseleft() or (ismousemove() and (_ms.wparam=1)) and (max(0,finaltime-1)>0) then
    begin
    SetMidiTime(GetMousePosX()/GetWidth()*max(0,finaltime-1));
    while IsNextMsg() do ;
    end;
  end
else if not((GetMousePosX()>=menul0*GetWidth()) and (GetMousePosX()<=menur0*GetWidth()) and (GetMousePosY()>=(1-menuy)*GetHeight())) then
  begin
  if IsMsg(WM_LBUTTONDOWN) then
    begin
    for kbdi:=$00 to $7F do
      if(IsKeynoteBlack(kbdi)=0)then
        if(GetMousePosX()>GetKeynoteX(kbdi))then kbdn:=kbdi;
    for kbdi:=$00 to $7F do
      if(IsKeynoteBlack(kbdi)=1)then
        if GetMousePosY()<GetHeight()-round(GetKeynoteW0()*(kleny0-kleny1)) then
          if(GetMousePosX()>GetKeynoteX(kbdi))
          and(GetMousePosX()<GetKeynoteX0(kbdi)) then kbdn:=kbdi;
    midiOutShortMsg(midiOut,$7F0090 or kbdn shl 8);
    end;
  if IsMsg(WM_LBUTTONUP) then
    midiOutShortMsg(midiOut,$000080 or kbdn shl 8);
  end;
if ismouseright() then
  if menub then menub:=not(menub) else PauseMidi();
if IsMouseWheel() then
  begin
  if longint(_ms.wParam)>0 then SetMidiVol(min(volamax,voli+1));
  if longint(_ms.wParam)<0 then SetMidiVol(max(1,voli-1));
  end;
end;

procedure SetKey(skey,sval:UnicodeString);
var ival:longint;
var sret:word;
begin
val(sval,ival,sret);
case skey of
  'fnames':fnames:=sval;
  'tempdir':tempdir:=ansistring(sval);
  'chancolor':chancolor:=ansistring(sval);
  {$ifdef video}
  'vname':vname:=ansistring(sval);
  {$endif}
  end;
if (length(sval)>0) and (sret=0) and (ival>0) then
case skey of
  'midipos':midipos:=ival;
  'voli':voli:=ival;
  'spd1':spd1:=ival;
  'kchord0':kchord0:=ival;
  'kkey0':kkey0:=ival;
  'midiouti':midiouti:=ival;
  'msgbufb0':msgbufb0:=ival;
  'msgbufb1':msgbufb1:=ival;
  'autofresh':autofresh:=ival;
  'mult':mult:=ival;
  'kbdcb':kbdcb:=ival;
  'kchb':kchb:=ival;
  'kchb2':kchb2:=ival;
  'kmessure':kmessure:=ival;
  'loop':loop:=ival;
  'fbi':fbi:=ival;
  'msgbufn0':msgbufn0:=ival;
  'msgvol0':msgvol0:=ival;
  'maxkbdc':maxkbdc:=ival;
  'framerate':framerate:=ival;
  'helpb':helpb:=ival;
  {$ifdef video}
  'vrate':vrate:=ival;
  'vquality':vquality:=ival;
  {$endif}
  end;
end;

procedure LoadIni();
var fini:text;
var line0,line1,line2:UnicodeString;
var linep:longword;
begin
assign(fini,fdir+UnicodeString('midiplayer.ini'));
if IsFileW(fdir+UnicodeString('midiplayer.ini')) then
  begin
  reset(fini);
  while not(eof(fini)) do
    begin
    readln(fini,line0);
    linep:=pos('=',line0);
    if linep>0 then
      begin
      line1:=copy(line0,1,linep-1);
      line2:=copy(line0,linep+1,length(line0)-linep);
      SetKey(line1,line2);
      end;
    end;
  close(fini);
  end;
end;

procedure GetDirPath();
begin
fdir:=UnicodeString(paramstr(0));
repeat
if length(fdir)>0 then delete(fdir,length(fdir),1);
until (length(fdir)<=1) or (fdir[length(fdir)]='\');
end;

procedure SendToInstance(iname:UnicodeString);
var hwm:longword;
var inamei:longword;
begin
hwm:=FindWindow('MidiPlayer3Class',nil);
if hwm<>0 then
  begin
  SendMessage(hwm,WM_USER,0,1);
  for inamei:=1 to length(iname) do
    begin
    SendMessage(hwm,WM_USER,longword(word(iname[inamei])),0);
    end;
  SendMessage(hwm,WM_USER,0,2);
  halt;
  end;
end;

Procedure DoCommandLine();
var para,parakey,parafname:UnicodeString;
var parai:longword;
begin
para:='';
parakey:='';
parafname:='';
for parai:=1 to ParamCount() do
  begin
  para:=UnicodeString(ParamStr(parai));
  if (para[1]='-') or (para[1]='/') then
    parakey:=para
  else
    begin
    if parakey<>'' then
      begin
      delete(parakey,1,1);
      SetKey(parakey,para);
      end
    else
      parafname:=para;
    parakey:='';
    end;
  end;
if (parafname<>'') and (parafname<>fnames) then
  begin
  if IsFileW(parafname) then SendToInstance(parafname);
  fnames:=parafname;
  midipos:=0;
  startb:=false;
  end
else
  if helpb=0 then newthread(@helpproc);
end;

procedure InitCS();
begin
InitializeCriticalSection(cs1);
InitializeCriticalSection(cs2);
InitializeCriticalSection(cs3);
InitializeCriticalSection(cs4);
InitializeCriticalSection(csfevent0);
InitializeCriticalSection(csnote);
end;

procedure InitDraw();
begin
w:=2*GetScrWidth()div 3;
h:=2*GetScrHeight()div 3;
_class:='MidiPlayer3Class';
CreateWin(w,h,black1);
//_wc.HIcon:=LoadImage(0,'midiplayer.ico',IMAGE_ICON,0,0,LR_LOADFROMFILE);
_wc.HIcon:=LoadImage(HInstance,'MIDIPLAYER_ICON',IMAGE_ICON,0,0,0);
//_wc.HIcon:=LoadIcon(HInstance,'MIDIPLAYER_ICON');
sendmessage(_hw,WM_SETICON,ICON_SMALL,longint(_wc.HIcon));
SetFontName('Consolas');
InitkbdPos();
InitkbdColor();
NewThread(@DrawProc);
end;

procedure OpenRS();
begin
GetKeyS('rs',rs);
DeleteFile(tempdir+'fevent0'+rs);
DeleteFile(tempdir+'fevent'+rs);
DeleteFile(tempdir+'fnote'+rs);
randomize();rs:=i2hs(longword(random($FFFFFFFF)));
SetKeyS('rs',rs);
if fb then
  begin
  assign(fevent0,tempdir+'fevent0'+rs);fillchar(bfevent0_,maxfevent0n*sizeof(tevent),0);fevent0w:=false;rewrite(fevent0);bjfevent0:=-1;
  assign(fevent,tempdir+'fevent'+rs);fillchar(bfevent_,maxfeventn*sizeof(tevent),0);feventw:=false;rewrite(fevent);for bjfeventi:=0 to maxfeventm-1 do bjfevent[bjfeventi]:=-1;
  assign(fnote,tempdir+'fnote'+rs);fillchar(bfnote_,maxfnoten*sizeof(tnotemap),0);fnotew:=true;rewrite(fnote);for bjfnotei:=0 to maxfnotem-1 do bjfnote[bjfnotei]:=-1;bjfnotek:=-1;
  end;
end;

procedure CloseRS();
begin
if fb then
  begin
  feventw:=false;close(fevent0);DeleteFile(tempdir+'fevent0'+rs);
  fevent0w:=false;close(fevent);DeleteFile(tempdir+'fevent'+rs);
  fnotew:=false;close(fnote);DeleteFile(tempdir+'fnote'+rs);
  end;
for bnotej:=-1 to bnoten00 do
  begin
  bmpname:=tempdir+'bmp'+'_'+i2s(0)+'_'+i2s(bnotej)+'_'+rs+'.png';DeleteFile(bmpname);
  bmpname:=tempdir+'bmp'+'_'+i2s(1)+'_'+i2s(bnotej)+'_'+rs+'.png';DeleteFile(bmpname);
  end;
end;

begin
GetTempPath($100,tempdirs);tempdir:=tempdirs;
ResetReg();
LoadReg();
GetDirPath();
LoadIni();
DoCommandLine();
fb:=(fbi>0);
OpenRS();
{$ifdef D3D}InitD3D();{$endif}
InitCS();
InitDraw();
if IsFileW(fnames) then
  begin
  PlayMidi(fnames);
  SetMidiTime(midipos/1000-1);
  end;
ResetMidiHard(midiOuti);
SetMidiVol(volamax-2);
repeat
if isnextmsg then DoAct() else Delay(1);
if GetMidiTime()>finaltime then
  case loop of
    0:begin if pauseb=false then PauseMidi();SetMidiTime(begintime);end;
    1:SetMidiTime(begintime);
    2:PlayMidi(get_file(find_current+1));
    end;
EnterCriticalSection(csfevent0);
CleanMsgChan();
if eventi<eventn then
  begin
  msgbufn:=-msgbufn0;
//  msgbufn:=0;
  while GetMidiTime()>GetFEvent0TickTime(eventi) do
    begin
    if isnextmsg then DoAct();
    if fb then begin fi:=eventi;eventi:=0;event0[eventi]:=GetFEvent0(fi);end;
    while (eventtmi<eventtmn) and (eventtm[eventtmi].curtick<=event0[eventi].curtick) do begin tempo:=eventtm[eventtmi].msg;eventtmi:=eventtmi+1;end;
    while (eventchi<eventchn) and (eventch[eventchi].curtick<=event0[eventi].curtick) do begin chord:=eventch[eventchi].msg;eventchi:=eventchi+1;end;
    if event0[eventi].msg and $F0 shr 4<$F then
      begin
      if(event0[eventi].msg and $F0 shr 4=$B)
      and(event0[eventi].msg shr 8 and $FF=$07)then
        SetMidiChanVol(event0[eventi].msg and $F,event0[eventi].msg shr 16 and $FF)
      else
        begin
        if (event0[eventi].msg and $F0<>$90) and (event0[eventi].msg and $F0<>$80) then
          midiOutShortMsg(midiOut,event0[eventi].msg)
        else
          begin
          EnterCriticalSection(cs3);
          if event0[eventi].msg and $F<>$9 then
            begin
            notei:=GetKeykey(event0[eventi].msg shr 8 and $7F) or ((event0[eventi].track or event0[eventi].msg and $F shl maxtrack0) shl 8);
            if event0[eventi].msg and $F0=$90 then
              begin
              notech[notei]:=chord;
              notec[notei]:=event0[eventi].track or event0[eventi].msg and $F shl maxtrack0;
              if kbdcb=0 then
                begin
                PushKbdC(notei,GetKeyChordC(notei and $7F,notech[notei]));
                kbdc[notei and $7F]:=GetKeyChordC(notei and $7F,notech[notei]);
                end
              else
                begin
                PushKbdC(notei,GetKeynoteC(notei and $7F,notec[notei]));
                kbdc[notei and $7F]:=GetKeynoteC(notei and $7F,notec[notei]);
                end;
              end;
            if event0[eventi].msg and $F0=$80 then
              begin
              PopKbdC(notei);
              kbdc[notei and $7F]:=-1;
              end;
            end;
          LeaveCriticalSection(cs3);
          if (event0[eventi].msg and $F0<>$90) or (event0[eventi].msg shr 16 and $FF>=msgvol0) then
            begin
            msgbuf0:=event0[eventi].msg;
            if event0[eventi].msg and $0F<>$09 then
              msgbuf0:=msgbuf0 and $FFFF00FF or GetKeykey(msgbuf0 shr 8 and $7F) shl 8;
            if (msgbufn<0) then
              begin
              midiOutShortMsg(midiOut,msgbuf0);
              msgbufn:=msgbufn+1;
              end
            else
              begin
              msgbuf1:=(msgbuf0) and $FF;
              msgbuf2:=(msgbuf0 shr 8) and $FF;
              msgbuf3:=(msgbuf0 shr 16) and $FF;
              if msgbufb0=1 then
                begin
                msgbufb:=true;
                if msgbuf1 and $F0=$90 then
                  if (msgchan0[msgbuf1 and $F][msgbuf2][0]=true) and (msgchan[msgbuf1 and $F][msgbuf2][0]=msgbuf3) then
                    msgbufb:=false
                  else
                    begin msgchan0[msgbuf1 and $F][msgbuf2][0]:=true;msgchan[msgbuf1 and $F][msgbuf2][0]:=msgbuf3;end;
                if msgbuf1 and $F0=$80 then
                  if (msgchan0[msgbuf1 and $F][msgbuf2][1]=true) and (msgchan[msgbuf1 and $F][msgbuf2][1]=msgbuf3) then
                    msgbufb:=false
                  else
                    begin msgchan0[msgbuf1 and $F][msgbuf2][1]:=true;msgchan[msgbuf1 and $F][msgbuf2][1]:=msgbuf3;end;
                if msgbufb then AddMsgBuf(msgbuf1,msgbuf2,msgbuf3);
                end
              else
                AddMsgBuf(msgbuf1,msgbuf2,msgbuf3);
              end
            end
          end
        end
      end;
    if fb then eventi:=fi;
    eventi:=eventi+1;
    if eventi>=eventn then break;
    end;
  end;
LeaveCriticalSection(csfevent0);
if msgbufb1=1 then
  msgbufnmax:=msgbufn
else
  msgbufnmax:=msgbufn div 12;
if msgbufn>0 then
  begin
//writeln(msgbufn);
  with msghdr do
    begin
    lpData:=@msgbuf;
    dwBufferLength:=msgbufn;
    dwBytesrecorded:=msgbufn;
    dwFlags:=0;
    dwOffset:=0;
    end;
  midiOutPrepareHeader(midiOut,@msghdr,sizeof(msghdr));
  if msgbufb1=1 then
    midiOutLongMsg(midiOut,@msghdr,sizeof(msghdr))
  else
    begin
    midiStreamOut(midiOut,@msghdr,sizeof(msghdr));
    midiStreamRestart(midiOut);
    end;
  midiOutUnPrepareHeader(midiOut,@msghdr,sizeof(msghdr));
  end;
//for msgbufn:=0 to maxbuf-1 do msgbuf[msgbufn]:=0;
midipos:=round((GetMidiTime()+1)*1000);
until not(iswin());
midiOutClose(midiOut);
CloseRS();
SaveReg();
end.
