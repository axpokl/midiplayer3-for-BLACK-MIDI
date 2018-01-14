{$R midiplayer.res}
program midiplayer;
uses Windows,MMSystem,Display,Sysutils;

var maxevent:longword=$1;
var fb:boolean=true;
var fbi:longword=0;

{$i freg.inc}
{$i flist.inc}

type tevent=record track:byte;curtick,msg,tempo:longword;chord:shortint;ticktime:single;end;
var event:packed array of tevent;
var eventi:longint;
var eventn:longword=0;
var event0:packed array of tevent;
var eventj:longword;
var eventk:longint;

const maxeventm=$10000;
var eventm:packed array[0..maxeventm-1]of tevent;
var eventmn:longword;
var eventmi:longword;
var eventmj:longword;
var eventmk:longword;

const maxeventseek=$1000;

const maxtrack=$100;
const maxchan=$1000;
var track0:array[0..maxtrack-1]of longword;
var track1:array[0..maxtrack-1]of longword;
var tracki:longint;
var trackn:longword;
var trackj:longword;

var chancn:array[0..maxchan-1]of longword;
var chancc:array[0..maxchan-1]of longword;
var chancw:array[0..maxchan-1]of longword;
var chancb:array[0..maxchan-1]of longword;
var chani:longword;
var chanj:longword;
const chanc0:array[0..11]of longword=
($55,$AA,$FF,$2A,$7F,$D4,$15,$6A,$BF,$3F,$94,$E9);

var chorda:array[0..1,-7..7]of byte=(
($00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E),
($10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E));
var chordb:array[0..31]of byte=(
11,06,01,08,03,10,05,00,07,02,09,04,11,06,01,00,
08,03,10,05,00,07,02,09,04,11,06,01,08,03,10,00);
var chords:array[0..31]of ansistring=(
'Cb','Gb','Db','Ab','Eb','Bb','F','C','G','D','A','E','B','F#','C#','',
'ab','eb','bb','f','c','g','d','a','e','b','f#','c#','g#','d#','a#','');
var chord0,chord1:shortint;
var chordtmp:shortint=-1;
var sig0,sig1:byte;
var sig:longword;

const loops:array[0..2]of char=('N','S','A');

var cs1:TRTLCriticalSection;
var cs2:TRTLCriticalSection;
var cs3:TRTLCriticalSection;
var cs4:TRTLCriticalSection;
var csfevent0:TRTLCriticalSection;

var len0,head:longword;
var fpos,flen:longword;
var dvs:word;
var len:longint;
var tick,tick0,curtick,tpq:longword;
var ticktime0:single;
var tempo:longword=500000;
var fps:single;
var stat0,stat,hex0,hex1,data0,data1:byte;
var lens:longword;
var meta:byte;
var msg:longword;
var finaltime:single;
var finaltick:longword;
var chord:byte=7;
var tempo0:longword;
var tempo00:longword;
var drawr:single;

type tnotemap=record note:byte;note0,note1:single;notec:longword;chord:byte;end;
var notemap:packed array of tnotemap;
var notemapi:longint;
var notemapn:longword;
var notemapx:longword;

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
function MixColor(a,b:longword;m:single):longword;var cmix:longword;
begin display.MixColor(a,b,cmix,m);MixColor:=cmix;end;
function t2s(r:single):ansistring;var h,m,s,ss:longword;
begin
if r<0 then r:=0;
ss:=trunc(r*1000);s:=ss div 1000;ss:=ss mod 1000;m:=s div 60;s:=s mod 60;h:=m div 60;m:=m mod 60;
t2s:=i2s(m)+':'+i2s(s,2,'0')+'.'+i2s(ss div 100);if h>0 then t2s:=i2s(h)+':'+i2s(m,2,'0')+':'+i2s(s,2,'0')+'.'+i2s(ss div 100);
end;
function r2s(bpm:single):ansistring;var r0,r1:longint;var s:ansistring='';
begin r0:=round(bpm*10) div 10;r1:=round(bpm*10) mod 10;s:=i2s(r0);if r1>0 then s:=s+'.'+i2s(r1);r2s:=s;end;

procedure Addeventm(e:tevent);
begin
eventm[eventmi]:=e;
eventmi:=eventmi+1;
end;

procedure AddEvent(tr:byte;cu,ms,tm:longword;ch:shortint);
var fi:longint;
begin
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
  tempo:=tm;
  chord:=ch;
  if msg and $F0=$90 then
    if msg shr 16 and $00FF=0 then
      msg:=msg and $FFFFFF8F;
  end;
if fb then begin SetFEvent(event[eventi],0,fi);eventi:=fi;end;
if finaltick<cu then finaltick:=cu;
eventi:=eventi+1;
end;

procedure LoadMidi(fname:string);
begin
OpenFile(fname);
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
eventi:=0;
tracki:=0;
finaltick:=0;
if fb then begin close(fevent);feventw:=true;rewrite(fevent);for bjfeventi:=0 to maxfeventm-1 do bjfevent[bjfeventi]:=-1;end;
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
           addEvent(tracki,curtick,meta shl 8 or Stat,tempo,0);
           end
         else if meta=$59 then
           begin
           chord0:=0;
           chord1:=0;
           if lens>0 then begin chord0:=shortint(Get1());lens:=lens-1;end;
           if lens>0 then begin chord1:=shortint(Get1());lens:=lens-1;end;
           while lens>0 do begin Get1();lens:=lens-1;end;
           if chord1<>0 then chord1:=1;
           chord:=chorda[chord1,chord0];
           addEvent(tracki,max(0,curtick-1),meta shl 8 or Stat,0,chord);
           end
         else if meta=$58 then
           begin
           sig0:=0;
           sig1:=0;
           if lens>0 then begin sig0:=shortint(Get1());lens:=lens-1;end;
           if lens>0 then begin sig1:=shortint(Get1());lens:=lens-1;end;
           while lens>0 do begin Get1();lens:=lens-1;end;
           addEvent(tracki,curtick,sig1 shl 24 or sig0 shl 16 or meta shl 8 or Stat,0,0);
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

procedure PrepareMidi();
begin
trackn:=tracki;
if tpq>0 then
  begin
  curtick:=0;
  repeat
  addEvent(trackn,curtick,$5AFF,0,0);
  curtick:=curtick+tpq;
  until curtick>finaltick;
  track1[trackn]:=eventi;
  trackn:=trackn+1;
  end;
if fb then FlushFEvent(0);
if fb then begin close(fevent);feventw:=false;reset(fevent);for bjfeventi:=0 to maxfeventm-1 do bjfevent[bjfeventi]:=-1;end;
eventn:=eventi;
track0[0]:=0;
for tracki:=1 to trackn-1 do track0[tracki]:=track1[tracki-1];
EnterCriticalSection(csfevent0);
if fb then begin close(fevent0);fevent0w:=true;rewrite(fevent0);bjfevent0:=-1;end;
eventj:=0;
while (eventj<eventn) do
  begin
  if eventn>0 then begin drawr:=eventj/eventn;if eventj and $FFF=0 then DrawTitle();end;
  curtick:=$FFFFFFFF;
  for tracki:=0 to trackn-1 do
    if track0[tracki]<track1[tracki] then
      if GetFEventCurTick(track0[tracki],tracki)<curtick then
        begin
        trackj:=tracki;
        curtick:=GetFEventCurTick(track0[tracki],tracki);
        end;
  SetFEvent0(GetFEvent(track0[trackj],trackj),eventj);
  track0[trackj]:=track0[trackj]+1;
  eventj:=eventj+1;
  end;
if fb then FlushFEvent0();
drawr:=0;
tempo:=5000000;
finaltime:=0;
curtick:=0;
sig0:=1;sig:=1;
chordtmp:=-1;
tick0:=0;
ticktime0:=0;
eventmi:=0;
tempo00:=0;
for fi:=0 to eventn-1 do
  begin
  if eventn>0 then begin drawr:=fi/eventn;if fi and $FFF=0 then DrawTitle();end;
  if not(fb) then eventi:=fi else begin eventi:=0;event0[eventi]:=GetFEvent0(fi);end;
  if event0[eventi].msg and $FFFF=$58FF then
    begin
    sig0:=event0[eventi].msg shr 16 and $FF;
    sig1:=event0[eventi].msg shr 24 and $FF;
    sig:=1;while sig1>0 do begin sig:=sig*2;sig1:=sig1-1;end;
    end;
  while curtick<event0[eventi].curtick do curtick:=curtick+tpq*sig0*4 div sig;
  tick:=event0[eventi].curtick-tick0;
  tick0:=event0[eventi].curtick;
  event0[eventi].ticktime:=ticktime0;
  if tpq>0 then event0[eventi].ticktime:=event0[eventi].ticktime+tick/tpq*(tempo/1000000);
  if fps>0 then event0[eventi].ticktime:=event0[eventi].ticktime+tick/fps;
  ticktime0:=event0[eventi].ticktime;
  if event0[eventi].tempo>0 then tempo:=event0[eventi].tempo;
  if event0[eventi].tempo>0 then if tempo00=0 then tempo00:=event0[eventi].tempo;
  if event0[eventi].msg=$5AFF then event0[eventi].tempo:=tempo;
  if event0[eventi].msg=$5AFF then if curtick=event0[eventi].curtick then event0[eventi].msg:=$5BFF;
  if event0[eventi].msg and $FFFF=$59FF then chord:=event0[eventi].chord else event0[eventi].chord:=chord;
  if event0[eventi].msg and $FFFF=$59FF then if chordtmp=-1 then chordtmp:=chord;
  if (event0[eventi].msg and $FFFF=$5AFF) or (event0[eventi].msg and $FFFF=$5BFF) or (event0[eventi].msg and $FFFF=$59FF) then Addeventm(event0[eventi]);
  finaltime:=max(finaltime,event0[eventi].ticktime+1);
  if fb then SetFEvent0(event0[eventi],fi);
  end;
eventmn:=eventmi;
drawr:=0;
if tempo00=0 then tempo00:=5000000;
if fb then FlushFEvent0();
if fb then begin close(fevent0);fevent0w:=false;reset(fevent0);bjfevent0:=-1;end;
LeaveCriticalSection(csfevent0);
end;

var midiOut:longword;
var firsttime:single;
var pauseb:boolean;
var pausetime:single;
var spd0:single=1;
var spd1:single=1;

const volamax=16;
const vola:array[1..volamax]of single=
(0,0.01,0.02,0.03,0.04,0.06,0.08,0.12,0.16,0.25,0.35,0.5,0.7,1,1.41,2);
var volchana:array[0..$F]of byte;
var volchani:byte;

var msghdr:MIDIHDR;
const maxbuf=$10000;
var msgbuf:packed array[0..maxbuf]of byte;
var msgbuf0:longword;
var msgbufn:longint;
var msgbuf1,msgbuf2:shortint;

var notemapa:longint;
var notemapb:longint;

var kbdc:array[$00..$7F]of longint;
var kbdcc:array[0..11]of longword;
var kbdci:byte;

procedure InitKbdC();
begin
for kbdci:=$00 to $7F do kbdc[kbdci]:=-1;
end;

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
voli:=v;
for volchani:=0 to $F do SetMidiChanVol(volchani,volchana[volchani]);
end;

function GetMidiTime():single;
begin
if pauseb then GetMidiTime:=pausetime
else GetMidiTime:=GetTimeR()*spd0-firsttime;
end;

procedure SetMidiTime(settime:single);
var chani:byte;
begin
EnterCriticalSection(cs2);
if settime<=0 then midiOutReset(midiOut);
for chani:=0 to $F do midiOutShortMsg(midiOut,$00007BB0 or chani);
firsttime:=GetTimeR()*spd0-settime;
EnterCriticalSection(csfevent0);
eventj:=eventn div 2;
eventk:=(eventj+1) div 2;
repeat
if eventk=0 then break;
if GetFEvent0Ticktime(eventj)>=settime then eventj:=max(0,eventj-eventk) else eventj:=min(eventj+eventk,eventn-1);
if eventk=1 then break;
eventk:=(eventk+1) div 2;
until false;
if eventn>0 then if GetFEvent0Ticktime(eventj)<settime then
  eventj:=min(eventj+1,eventn);
tempo0:=tempo00;
for fi:=0 to min(eventj,eventn-1) do
if (fi<maxeventseek) or (fi>min(eventj,eventn-1)-maxeventseek) then
  begin
  if not(fb) then eventk:=fi else begin eventk:=0;event0[eventk]:=GetFEvent0(fi);end;
  if event0[eventk].msg and $F0 shr 4<$F then
    begin
    if(event0[eventk].msg and $F0 shr 4=$B) and(event0[eventk].msg shr 8 and $FF=$07)then
      SetMidiChanVol(event0[eventk].msg and $F,event0[eventk].msg shr 16 and $FF)
    else if (event0[eventk].msg and $F0<>$90) and (event0[eventk].msg and $F0<>$80) then
      midiOutShortMsg(midiOut,event0[eventk].msg);
    end;
  if event0[eventk].tempo>0 then
    tempo0:=event0[eventk].tempo;
  end;
LeaveCriticalSection(csfevent0);
tempo:=tempo0;
eventi:=eventj;
if pauseb then pausetime:=settime;
if voli>0 then SetMidiVol(voli);
if settime<=0 then if chordtmp<>-1 then chord:=chordtmp;
notemapa:=0;
notemapb:=0;
if settime=-1 then InitKbdC();
LeaveCriticalSection(cs2);
end;

procedure PauseMidi();
begin
if pauseb=false then pausetime:=GetMidiTime();
SetMidiTime(pausetime);
pauseb:=not(pauseb);
end;

const maxnote=$FFFFF;
var note0:array[0..maxnote]of single;
var note1:array[0..maxnote]of single;
var notec:array[0..maxnote]of longword;
var notech:array[0..maxnote]of byte;
var noteb:array[0..maxnote]of boolean;
var notem:array[0..maxnote]of longword;
var notei:longword;

const black0=$0F0F0F;
const black1=$0F0F0F;
const gray0=$1F1F1F;
const gray1=$3F3F3F;
const gray2=$9F9F9F;

const kbd0n=21;
const kbd1n=21+87;
var kbd0:byte=kbd0n;
var kbd1:byte=kbd1n;

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
noteb[notei]:=false;
end;

procedure CreateNoteMap();
var ei:longint;
begin
for chani:=0 to maxchan-1 do chancn[chani]:=0;
for chani:=0 to maxchan-1 do chancc[chani]:=chani;
for chani:=0 to maxchan-1 do chancw[chani]:=HSN2RGB(chanc0[chani mod 12]or $9FFF00);
for chani:=0 to maxchan-1 do chancb[chani]:=MixColor(chancw[chani],black0,3/4);
notemapi:=0;
kbd0:=kbd0n;
kbd1:=kbd1n;
EnterCriticalSection(csfevent0);
notemap:=nil;setlength(notemap,maxevent);
if fb then begin close(fnote);fnotew:=true;rewrite(fnote);bjfnote:=-1;end;
for fi:=0 to eventn-1 do
  begin
  if eventn>0 then if fi and $FFF=0 then begin drawr:=fi/eventn;DrawTitle();end;
  if not(fb) then ei:=fi else begin ei:=0;event0[ei]:=GetFEvent0(fi);end;
  if event0[ei].msg and $F<>$9 then
    begin
    if event0[ei].msg and $F0=$90 then
      begin
      notei:=(event0[ei].msg shr 8 and $7F) or ((event0[ei].track or event0[ei].msg and $F shl 8) shl 8);
      kbd0:=min(notei and $7F,kbd0);
      kbd1:=max(notei and $7F,kbd1);
      if noteb[notei]=true then SetFNoteNote1(notem[notei],event0[ei].ticktime);
      noteb[notei]:=true;
      notech[notei]:=event0[ei].chord;
      notec[notei]:=event0[ei].track or event0[ei].msg and $F shl 8;
      note0[notei]:=event0[ei].ticktime;
      note1[notei]:=event0[ei].ticktime;
      AddNoteMap(notei);
      end;
    if event0[ei].msg and $F0=$80 then
      begin
      notei:=(event0[ei].msg shr 8 and $7F) or ((event0[ei].track or event0[ei].msg and $F shl 8) shl 8);
      SetFNoteNote1(notem[notei],event0[ei].ticktime)
      end;
    end;
  end;
drawr:=0;
if fb then FlushFNote();
if fb then begin close(fnote);fnotew:=false;reset(fnote);bjfnote:=-1;end;
LeaveCriticalSection(csfevent0);
notemapn:=notemapi;
for chani:=0 to maxchan-1 do
  for chanj:=0 to maxchan-1 do
    if chancn[chani]>chancn[chanj] then
      begin
      swapc(chancn[chani],chancn[chanj]);
      swapc(chancc[chani],chancc[chanj]);
      end;
for chani:=0 to maxchan-1 do
  for chanj:=0 to maxchan-1 do
    if chancc[chani]<chancc[chanj] then
      begin
      swapc(chancn[chani],chancn[chanj]);
      swapc(chancc[chani],chancc[chanj]);
      swapc(chancw[chani],chancw[chanj]);
      swapc(chancb[chani],chancb[chanj]);
      end;
end;

var w:longword;
var h:longword;
var sz:longword;
var fw,fh:longword;
var frametime:single;
var printtime:single;
var scrtime:single;
var delaytime:single=0;

var k_shift,k_ctrl:boolean;
var k_pos:single;

const klen0:single=1.15;
const klen1:single=0.65;
var kbd:array[0..11]of single;
const keyblack:array[0..11]of byte=(0,1,0,1,0,0,1,0,1,0,1,0);
const keychord:array[0..3,0..11]of char=(
('1',' ','2',' ','3','4',' ','5',' ','6',' ','7'),
('C','d','D','e','E','F','g','G','a','A','b','B'),
(' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '),
(' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '));

var kleny0:single=6.5;
var kleny1:single=4.5;

var kbdi,kbdn:byte;

const fhr=0.7;

const maxbnote=$1000;
var bnote:array[0..1,0..maxbnote-1]of pbitmap;
var bnoten:longint=-1;
var bnoten0:longint=-1;
var bnotei:longint;
var bnoteh:longword=0;
var bnoteh0:longword=$1000;
var bnoteb:boolean=false;
var initb:boolean=false;

type tbnotekey=record
x,y,w,h:longint;b:shortint;cbg,cfg:longword;
s:ansistring;sx,sy:longint;sc:longword;
end;
var bnotekey:array[0..$7F]of tbnotekey;
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

function GetKeyChord(k:byte;chord:byte):ansistring;
begin GetKeyChord:=keychord[kchb,(k-chordb[chord]+12) mod 12]end;

function GetKeyChord0(k:byte;chord:byte):byte;
begin GetKeyChord0:=(k-chordb[chord]+12) mod 12;end;

function GetKeyChordC(k:byte;chord:byte):longword;
begin GetKeyChordC:=kbdcc[GetKeyChord0(k,chord)];end;

function GetKeyChord(k:byte):ansistring;
begin GetKeyChord:=GetKeyChord(k,chord);end;

function IsKeynoteBlack(k:byte):byte;
begin IsKeynoteBlack:=keyblack[k mod 12];end;

function GetKeynote(k:byte):single;
begin GetKeynote:=7*(k div 12)+kbd[k mod 12];end;

function GetKeynote0(k:byte):single;
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

procedure FlushBar();
var keyi:byte;
var y0,h0:longword;
var bnotei:longint;
var flushb:boolean=false;
begin
for keyi:=0 to $7F do
  with bnotekey[keyi] do
  begin
  if h>0 then
    begin
    flushb:=true;
    bnotei:=(y+h)div bnoteh0;
    y0:=bnoteh0-(y+h-bnotei*bnoteh0);
    h0:=h;
    while h0>(bnoteh0-y0) do
      begin
      Bar(bnote[b,bnotei],x,y0-1,w,bnoteh0-y0+2,cfg,cbg);
      h0:=h0-(bnoteh0-y0);
      y0:=0;
      bnotei:=bnotei-1;
      end;
    if bnotei>=0 then Bar(bnote[b,bnotei],x,y0-1,w,h0+1,cfg,cbg);
    bnotei:=(sy+fh+2)div bnoteh0;
    y0:=bnoteh0-(sy+fh+2-bnotei*bnoteh0);
    if kchb<=1 then DrawTextXY(bnote[b,bnotei],s,sx,y0+1,sc);
    if y0+fh>=bnoteh0 then
      if bnotei>1 then
        if kchb<=1 then DrawTextXY(bnote[b,bnotei-1],s,sx,y0-bnoteh0+1,sc);
    h:=0;
    end;
  end;
if fb then if flushb then FlushFNote();
end;

procedure DrawBNote(ni:longword;b:shortint);
var x,y,w,h:longint;
var key:byte;
begin
if fb then begin fni0:=ni;ni:=0;notemap[ni]:=GetFNote(fni0);end;
key:=notemap[ni].note;
x:=GetKeynoteX(notemap[ni].note);
w:=GetKeynoteX0(notemap[ni].note)-GetKeynoteX(notemap[ni].note);
y:=trunc((notemap[ni].note0)*mult*GetWidth()/mult0)+round(GetKeynoteW0()*kleny0);
h:=max(round(fh*fhr),max(3,trunc((notemap[ni].note1-notemap[ni].note0)*mult*GetWidth()/mult0)));
if ((h+y)<>bnotekeyn) then FlushBar();
bnotekeyn:=(h+y);
if(h>=bnotekey[key].h)then
  begin
  bnotekey[key].x:=x;
  bnotekey[key].y:=y;
  bnotekey[key].w:=w;
  bnotekey[key].h:=h;
  bnotekey[key].b:=b;
  if kbdcb=0 then
    bnotekey[key].cbg:=GetKeyChordC(notemap[ni].note,notemap[ni].chord)
  else
    bnotekey[key].cbg:=GetKeynoteC(notemap[ni].note,notemap[ni].notec);
  bnotekey[key].cfg:=MixColor(bnotekey[key].cbg,black,3/4);
  bnotekey[key].s:=GetKeyChord(notemap[ni].note,notemap[ni].chord);
  bnotekey[key].sx:=x+(w-fw)div 2;
  bnotekey[key].sy:=min(y+round((h-fh)*fhr),y);
  bnotekey[key].sc:=black;
  end;
end;

procedure _Bar(x,y,w,h:longint;cfg,cbg:longword);
begin Bar(x,GetHeight()-y-h,w,h,cfg,cbg);end;

procedure _Line(b:pbitmap;x,y,w,h:longint;c:longword);
begin Line(b,x,bnoteh-y-h,w,h,c);end;

procedure _Line(x,y,w,h:longint;c:longword);
begin Line(x,GetHeight()-y-h,w,h,c);end;

procedure _DrawTextXY(s:ansistring;x,y:longint;c:longword);
begin DrawTextXY(s,x,GetHeight()-y-fh-2,c);end;

procedure SetDrawFont(sz:single);
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

procedure DrawMessureLine(t:single;ms:longword;tempo:longword;c:longword);
var w0,y:longint;
var bpm:single;
begin
w0:=GetKeynoteW0();
y:=trunc((t-printtime)*mult*GetWidth()/mult0)+round(w0*kleny0);
if (y>=round(w0*kleny0)) and (y<GetHeight()) then _line(0,y,GetWidth(),0,c);
if (y+fh>=round(w0*kleny0)) and (y<GetHeight()) then
  begin
  _DrawTextXY(i2s(ms),0,y,c);
  if tempo>0 then bpm:=60000000/tempo*spd0 else bpm:=0;
  _DrawTextXY(r2s(bpm),GetWidth()-fw*length(r2s(bpm)),y,c);
  end;
end;

procedure DrawChordLine(t:single;ch:byte;c:longword);
var w0,y:longint;
begin
w0:=GetKeynoteW0();
y:=trunc((t-printtime)*mult*GetWidth()/mult0)+round(w0*kleny0);
if (y>=round(w0*kleny0)) and (y<GetHeight()) then _line(0,y,GetWidth(),0,c);
if (y+fh>=round(w0*kleny0)) and (y<GetHeight()) then _DrawTextXY(chords[ch],0,y-fh-4,c);
end;

procedure DrawMessureLineAll();
begin
eventmj:=0;
while (eventmj<eventmn-1) and (eventm[eventmj].ticktime<printtime) do
  eventmj:=eventmj+1;
eventmk:=eventmj;
while (eventmk<eventmn-1) and (eventm[eventmk].ticktime<printtime+scrtime) do
  eventmk:=eventmk+1;
if eventmn>0 then
  for eventmj:=0 to eventmk do
    begin
    if eventm[eventmj].msg and $FFFF=$5AFF then DrawMessureLine(eventm[eventmj].ticktime,eventm[eventmj].curtick div tpq,eventm[eventmj].tempo,gray0);
    if eventm[eventmj].msg and $FFFF=$5BFF then DrawMessureLine(eventm[eventmj].ticktime,eventm[eventmj].curtick div tpq,eventm[eventmj].tempo,gray1);
    if eventm[eventmj].msg and $FFFF=$59FF then DrawChordLine(eventm[eventmj].ticktime,eventm[eventmj].chord,gray2);
    end;
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

procedure DrawKeyboard();
var kbdi:byte;
var x,w,w0:longint;
var kbd0i,kbd1i:byte;
begin
EnterCriticalSection(cs3);
kbd0i:=kbd0;
kbd1i:=kbd1;
if IsKeynoteBlack(kbd0i)=1 then kbd0i:=max($00,kbd0i-1);
if IsKeynoteBlack(kbd1i)=1 then kbd1i:=min($7F,kbd1i+1);
for kbdi:=kbd0i to kbd1i do
  begin
  x:=GetKeynoteX(kbdi);
  w:=GetKeynoteX0(kbdi)-GetKeynoteX(kbdi);
  w0:=GetKeynoteW0();
  if IsKeynoteBlack(kbdi)=0 then
    begin
    if kbdc[kbdi]=-1 then
      begin
      _Bar(x,0,w,round(w0*kleny0),black,white);
      if kchb<=1 then _DrawTextXY(GetKeyChord(kbdi),x+(w-fw)div 2,4,MixColor(white,black,1/2));
      end
    else
      begin
      _Bar(x,0,w,round(w0*kleny0),black,kbdc[kbdi]);
      if kchb<=1 then _DrawTextXY(GetKeyChord(kbdi),x+(w-fw)div 2,0,black);
      end;
    end;
  end;
for kbdi:=kbd0i to kbd1i do
  begin
  x:=GetKeynoteX(kbdi);
  w:=GetKeynoteX0(kbdi)-GetKeynoteX(kbdi);
  w0:=GetKeynoteW0();
  if IsKeynoteBlack(kbdi)=1 then
    begin
    if kbdc[kbdi]=-1 then
      begin
      _Bar(x,round(w0*(kleny0-kleny1)),w,round(w0*kleny1),black,black);
      _DrawTextXY(GetKeyChord(kbdi),x+(w-fw)div 2,round(w0*(kleny0-kleny1))+4,MixColor(black,white,1/2));
      end
    else
      begin
      _Bar(x,round(w0*(kleny0-kleny1)),w,round(w0*kleny1),black,kbdc[kbdi]);
      _DrawTextXY(GetKeyChord(kbdi),x+(w-fw)div 2,round(w0*(kleny0-kleny1)),black);
      end;
    end;
  end;
LeaveCriticalSection(cs3);
end;

procedure InitBNote0(force:boolean);
begin
if notemapn-1>=0 then
  bnoteh:=round(finaltime*mult*GetWidth()/mult0)+GetHeight();
bnoten0:=bnoteh div bnoteh0;
for bnotei:=bnoten0+1 to bnoten do
  begin
  ReleaseBMP(bnote[0,bnotei]);
  ReleaseBMP(bnote[1,bnotei]);
  end;
for bnotei:=0 to min(bnoten0,bnoten) do
  begin
  if force or (bnote[0,bnotei]^.width<>GetWidth()) then
    begin
    ReleaseBMP(bnote[0,bnotei]);
    bnote[0,bnotei]:=CreateBMP(GetWidth(),bnoteh0,black1);
    end
  else
    begin
    Clear(bnote[0,bnotei]);
    end;
  if force or (bnote[1,bnotei]^.width<>GetWidth()) then
    begin
    ReleaseBMP(bnote[1,bnotei]);
    bnote[1,bnotei]:=CreateBMP(GetWidth(),bnoteh0,black1);
    end
  else
    begin
    Clear(bnote[1,bnotei]);
    end;
  end;
for bnotei:=bnoten+1 to bnoten0 do
  begin
  bnote[0,bnotei]:=CreateBMP(GetWidth(),bnoteh0,black1);
  bnote[1,bnotei]:=CreateBMP(GetWidth(),bnoteh0,black1);
  end;
SetDrawFont();
for bnotei:=0 to bnoten0 do
  begin
  SetFont(bnote[0,bnotei]);
  SetFont(bnote[1,bnotei]);
  end;
bnoten:=bnoten0;
end;

procedure InitBNote(force:boolean);
var pauseb0:boolean;
begin
EnterCriticalSection(cs4);
pauseb0:=pauseb;
if pauseb0=false then PauseMidi();
InitBnote0(force);
InitFNoteDraw(0,notemapn-1);
if fb then FlushFNote();
scrtime:=(GetHeight()-round(GetKeynoteW0()*kleny0))/(mult*GetWidth()/mult0);
delaytime:=scrtime;
if not(force) then
begin
for fni:=0 to notemapn-1 do
  begin
  if notemapn>0 then if fni and $FFF=0 then begin drawr:=fni/notemapn;DrawTitle();end;
  if fb then begin notemapi:=0;notemap[notemapi]:=GetFNote(fni);end else notemapi:=fni;
  if(notemap[notemapi].note1-notemap[notemapi].note0>delaytime)then
    if(IsKeynoteBlack(notemap[notemapi].note)=0)then
      DrawBNote(notemapi,0)
    else
      DrawBNote(notemapi,1);
  end;
FlushBar();
drawr:=0;
end;
notemapa:=0;
notemapb:=0;
GetDrawTime();
initb:=true;
if pauseb0=false then PauseMidi();
LeaveCriticalSection(cs4);
end;

procedure DrawBNoteAll();
begin
EnterCriticalSection(cs1);
if initb=false then InitBNote(false);
notemapa:=notemapn div 2;
notemapx:=(notemapa+1) div 2;
repeat
if notemapx=0 then break;
if GetFNote(notemapa).note0>=printtime-delaytime then notemapa:=max(0,notemapa-notemapx) else notemapa:=min(notemapa+notemapx,notemapn-1);
if notemapx=1 then break;
notemapx:=(notemapx+1) div 2;
until false;
if notemapx>0 then
if GetFNote(notemapa).note0<printtime-delaytime then notemapa:=min(notemapa+1,notemapn);
notemapb:=notemapn div 2;
notemapx:=(notemapb+1) div 2;
repeat
if notemapx=0 then break;
if GetFNote(notemapb).note0>printtime+scrtime then notemapb:=max(0,notemapb-notemapx) else notemapb:=min(notemapb+notemapx,notemapn-1);
if notemapx=1 then break;
notemapx:=(notemapx+1) div 2;
until false;
if notemapx>0 then
if GetFNote(notemapb).note0<=printtime+scrtime then notemapi:=max(0,notemapb-1);
GetFNoteDraw(notemapa,notemapb);
if notemapx>0 then
for notemapi:=notemapa to notemapb do
  if GetFNoteDraw(notemapi)=false then
    if(IsKeynoteBlack(GetFNote(notemapi).note)=0)then
      DrawBNote(notemapi,0)
    else
      DrawBNote(notemapi,1);
if notemapa<=notemapb then SetFNoteDraw(notemapa,notemapb);
FlushBar();
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
  if(IsKeynoteBlack(GetFNote(notemapi).note)=0)then
    DrawBNote(notemapi,0)
  else
    DrawBNote(notemapi,1);
  end;
SetFNoteDraw(0,notemapn-1);
FlushBar();
drawr:=0;
bnoteb:=false;
if pauseb0=false then PauseMidi();
LeaveCriticalSection(cs1);
end;
end;

procedure DrawBNoteBB();
var y,y0,h,h0:longword;
var bnotei:longint;
begin
EnterCriticalSection(cs1);
y:=min(bnoteh,round(printtime*mult*GetWidth()/mult0)+GetHeight());
if y>0 then
  begin
  y0:=bnoteh0-(y mod bnoteh0);
  bnotei:=y div bnoteh0;
  h:=0;
  repeat
  h0:=bnoteh0-y0;
  h0:=min(h0,GetHeight()-h);
  DrawBMP(bnote[0,bnotei],0,y0,GetWidth(),h0,0,h,GetWidth(),h0);
  DrawBMP(bnote[1,bnotei],0,y0,GetWidth(),h0,0,h,GetWidth(),h0);
  bnotei:=bnotei-1;
  h:=h+h0;
  y0:=0;
  until (h=GetHeight()) or (bnotei<0);
  end;
LeaveCriticalSection(cs1);
end;

procedure DrawTime();
begin
if finaltime>0 then
  _Line(trunc(GetMidiTime()/finaltime*GetWidth()),0,0,GetHeight(),white);
DrawTextXY(t2s(GetMidiTime())+'/'+t2s(finaltime),0,0,white);
end;

procedure DrawChord();
begin
if (finaltime>0) then
  _DrawTextXY(chords[chord],0,round(GetKeynoteW0()*kleny0),white);
end;

procedure DrawLoop();
begin _DrawTextXY(loops[loop],GetWidth()-fw,round(GetKeynoteW0()*kleny0),white);end;

procedure DrawBPM();
var bpm:single;
var spds:ansistring='';
begin
if tempo>0 then bpm:=60000000/tempo*spd0 else bpm:=0;
if(bpm>=0)then
  begin
  if round(spd0*100)<>100 then spds:='('+i2s(round(spd0*100))+'%)';
  SetDrawFont(1.5);
  DrawTextXY(r2s(bpm)+' BPM',(GetWidth()-fw*length(r2s(bpm)+' BPM'))div 2,0,white);
  SetDrawFont();
  DrawTextXY(spds,(GetWidth()-fw*length(spds))div 2,round(fh*1.5),white);
  end;
end;

procedure DrawNoteN();
var notes:ansistring='';
var notemapi:longword;
begin
notemapi:=notemapn div 2;
notemapx:=(notemapi+1) div 2;
repeat
if notemapx=0 then break;
if GetFNote(notemapi).note0>=printtime then notemapi:=max(0,notemapi-notemapx) else notemapi:=min(notemapi+notemapx,notemapn-1);
if notemapx=1 then break;
notemapx:=(notemapx+1) div 2;
until false;
if notemapx>0 then
if GetFNote(notemapi).note0<printtime then notemapi:=min(notemapi+1,notemapn);
notes:=i2s(notemapi)+'/'+i2s(notemapn);
DrawTextXY(notes,GetWidth()-fw*length(notes),0,white);
end;

procedure DrawFPS();
var fpss:ansistring='';
begin
fpss:=i2s(GetFPS())+'/'+i2s(framerate);
if abs(GetFPSR-framerate)>1 then
  DrawTextXY(fpss,GetWidth()-fw*length(fpss),fh,white);
end;

procedure DrawReal();
begin
if drawr>0 then
  begin
  Line(0,GetHeight() div 2,GetWidth(),0,black);
  Line(0,GetHeight() div 2,round(drawr*GetWidth()),0,white);
  end;
end;

procedure DrawAll();
begin
SetDrawFont();
Clear();
GetDrawTime();
DrawNoteLine();
DrawMessureLineAll();
DrawBNoteAll0();
DrawBNoteAll();
DrawBNoteBB();
DrawKeyboard();
if kchb<=2 then
  begin
  DrawTime();
  DrawChord();
  DrawBPM();
  DrawNoteN();
  DrawLoop();
  DrawFPS();
  end;
DrawReal();
FreshWin();
end;

procedure DrawTitle();
var stitle:ansistring;
begin
stitle:='';
if (finaltime>0) and (drawr=0) then
  stitle:=stitle+'['+i2s(max(0,trunc(GetMidiTime()*100/finaltime)))+'%]';
stitle:=stitle+ExtractFileName(fnames);
if (finaltime>0) and (drawr=0)then
  stitle:=stitle+'('+chords[chord]+')';
if (finaltime>0) and (drawr=0)then
  stitle:=stitle+'['+i2s(find_current)+'/'+i2s(find_count)+']';
if spd0>0 then if round(spd0*100)<>100 then
  stitle:=stitle+'('+i2s(longword(round(spd0*100)))+'%)';
if mult>0 then if mult<>100 then
  stitle:=stitle+'<'+i2s(mult)+'%>';
if voli>0 then if round(vola[voli]*100)<>100 then
  stitle:=stitle+'['+i2s(longword(round(vola[voli]*100)))+'%]';
if drawr>0 then
  stitle:='['+i2s(trunc(drawr*100))+'%]'+stitle;
SetTitle(stitle);
end;

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
until not(iswin());
end;

procedure ResetMidi();
begin
spd0:=1;
eventi:=0;
pauseb:=false;
InitMidiChanVol($7F);
SetMidiTime(-1);
end;

procedure ResetMidiSoft();
var tmptime:single;
begin
tmptime:=GetMidiTime();
InitMidiChanVol($7F);
SetMidiTime(-1);
SetMidiTime(tmptime);
end;

procedure ResetMidiHard(i:longword);
var n:longword;
begin
n:=midiOutGetNumDevs();
if n>0 then midiOuti:=i mod n else midiOuti:=0;
midiOutClose(midiOut);
midiOutOpen(@midiOut,midiOuti,0,0,0);
ResetMidiSoft();
end;

procedure PlayMidi(fname:ansistring);
begin
if(fileexists(fname))then
  begin
  if pauseb=false then PauseMidi();
  SetMidiTime(-1);
  find_file(fname);
  fnames:=fname;
  EnterCriticalSection(cs2);
  maxevent:=1;
  event:=nil;setlength(event,maxevent);
  event0:=nil;setlength(event0,maxevent);
  LoadMidi(fname);
  PrepareMidi();
  LeaveCriticalSection(cs2);
  EnterCriticalSection(cs1);
  CreateNoteMap();
  ResetMidi();
  initb:=false;
  LeaveCriticalSection(cs1);
  if autofresh=1 then bnoteb:=true;
  savefile();
  while IsNextMsg() do ;
  end;
end;

procedure helpproc();
begin
  if fileexists(fdir+'midiplayer.txt') then
    ShellExecute(0,nil, PChar('notepad.exe'),PChar(fdir+'midiplayer.txt'),nil,1)
  else
    msgbox('Missing help file: '+fdir+'midiplayer.txt','Help file not found!');
end;

procedure DoAct();
begin
if ismsg(WM_USER) then
  begin
  if _ms.lParam=0 then para:=para+chr(_ms.wParam mod $100);
  if _ms.lParam=1 then para:='';
  if _ms.lParam=2 then PlayMidi(para);
  end;
if isDropFile() then
  PlayMidi(GetDropFile());
if (GetSize>0) and (GetSize()<>sz) then
  begin
  sz:=GetSize();
  initb:=false;
  end;
if iskey() then
  begin
  k_shift:=GetKeyState(VK_SHIFT)<0;
  k_ctrl:=GetKeyState(VK_CONTROL)<0;
  if iskey(K_F1) then newthread(@helpproc);
  if iskey(K_F2) then PlayMidi(fnames);
  if iskey(K_F3) then if not(k_shift) then ResetMidiHard(midiOuti) else ResetMidiHard(midiOuti+1);
  if iskey(K_F4) then if not(k_shift) then bnoteb:=true else autofresh:=1-autofresh;
  if iskey(K_F5) then framerate:=max(5,framerate-((framerate-1) div 60+1));
  if iskey(K_F6) then framerate:=min(480,framerate+(framerate div 60+1));
  if iskey(K_F7) or iskey(K_F8) then begin k_pos:=10;if k_ctrl then k_pos:=3;if k_shift then k_pos:=1;end;
  if iskey(K_F7) then begin EnterCriticalSection(cs4);mult:=max(0,mult-round(k_pos));initb:=false;LeaveCriticalSection(cs4);end;
  if iskey(K_F8) then begin EnterCriticalSection(cs4);mult:=min(1000,mult+round(k_pos));initb:=false;LeaveCriticalSection(cs4);end;
  if iskey(K_F9) then begin kbdcb:=(kbdcb+1)mod 3;initb:=false;end;
  if iskey(K_F11) then begin kchb:=(kchb+1) mod 4;initb:=false;end;
  if iskey(K_F12) then loop:=(loop+1) mod 3;
  if iskey(K_RIGHT) or iskey(K_LEFT) then begin k_pos:=1;if k_ctrl then k_pos:=5;if k_shift then k_pos:=30;end;
  if iskey(K_LEFT) then begin SetMidiTime(max(-1,GetMidiTime()-k_pos));InitKbdC();end;
  if iskey(K_RIGHT) then begin SetMidiTime(min(finaltime,GetMidiTime()+k_pos));InitKbdC();end;
  if iskey(K_SPACE) then PauseMidi();
  if iskey(K_ADD) or iskey(K_SUB) or iskey(187) or iskey(189) then begin k_pos:=0.1;if k_ctrl then k_pos:=0.03;if k_shift then k_pos:=0.01;end;
  if iskey(K_ADD) or iskey(187) then begin spd1:=min(16.00,spd0+k_pos);end;
  if iskey(K_SUB) or iskey(189) then begin spd1:=max(0,spd0-k_pos);end;
  if iskey(K_ADD) or iskey(K_SUB) or iskey(187) or iskey(189) then begin firsttime:=firsttime+GetTimeR()*(spd1-spd0);spd0:=spd1;end;
  if iskey(K_UP) then SetMidiVol(min(volamax,voli+1));
  if iskey(K_DOWN) then SetMidiVol(max(1,voli-1));
  if iskey(K_PGUP) then PlayMidi(get_file(find_current-1));
  if iskey(K_PGDN) then PlayMidi(get_file(find_current+1));
  if iskey(K_HOME) then PlayMidi(get_file(1));
  if iskey(K_END) then PlayMidi(get_file(find_count));
  if iskey(K_ESC) then CloseWin();
  end;
if GetMousePosY()<GetHeight()-round(GetKeynoteW0()*kleny0) then
  begin
  if ismouseleft() or (ismousemove() and (_ms.wparam=1)) and (finaltime>0) then
    begin
    SetMidiTime(GetMousePosX()/GetWidth()*finaltime);
    InitKbdC();
    while IsNextMsg() do ;
    end;
  end
else
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
  PauseMidi();
if IsMouseWheel() then
  begin
  if longint(_ms.wParam)>0 then SetMidiVol(min(volamax,voli+1));
  if longint(_ms.wParam)<0 then SetMidiVol(max(1,voli-1));
  end;
end;

Procedure DoCommandLine();
begin
hwm:=FindWindow('DisplayClass',nil);
fdir:=ParamStr(0);
repeat
if length(fdir)>0 then delete(fdir,length(fdir),1);
until (length(fdir)<=1) or (fdir[length(fdir)]='\');
para:=ParamStr(1);
if hwm<>0 then
  if para<>'' then
    begin
    SendMessage(hwm,WM_USER,0,1);
    for parai:=1 to length(para) do
    begin
      SendMessage(hwm,WM_USER,longword(ord(para[parai])),0);
      end;
    SendMessage(hwm,WM_USER,0,2);
    halt;
    end;
if ParamStr(2)<>'' then fb:=false;
if(fileexists(ExtractFileDir(ParamStr(0))+'\FORCE_MEMORY')) then fb:=false;
GetKeyI('fbi',fbi);if fbi>0 then fb:=false;
end;

procedure InitCS();
begin
InitializeCriticalSection(cs1);
InitializeCriticalSection(cs2);
InitializeCriticalSection(cs3);
InitializeCriticalSection(cs4);
InitializeCriticalSection(csfevent0);
end;

procedure InitDraw();
begin
w:=2*GetScrWidth()div 3;
h:=2*GetScrHeight()div 3;
CreateWin(w,h,black1);
_wc.HIcon:=LoadImage(0,'midiplayer.ico',IMAGE_ICON,0,0,LR_LOADFROMFILE);
sendmessage(_hw,WM_SETICON,ICON_SMALL,longint(_wc.HIcon));
SetFontName('Consolas');
InitkbdPos();
InitkbdColor();
InitCS();
NewThread(@DrawProc);
end;

begin
OpenKey();
DoCommandLine();
randomize();rs:=i2hs(longword(random($FFFFFFFF)));
if fb then
  begin
  assign(fevent0,GetTempDir(false)+'fevent0'+rs);DeleteFile(GetTempDir(false)+'fevent0');fillchar(bfevent0_,maxfevent0n*sizeof(tevent),0);fevent0w:=false;rewrite(fevent0);bjfevent0:=-1;
  assign(fevent,GetTempDir(false)+'fevent'+rs);DeleteFile(GetTempDir(false)+'fevent');fillchar(bfevent_,maxfeventn*sizeof(tevent),0);feventw:=false;rewrite(fevent);for bjfeventi:=0 to maxfeventm-1 do bjfevent[bjfeventi]:=-1;
  assign(fnote,GetTempDir(false)+'fnote'+rs);DeleteFile(GetTempDir(false)+'fnote');fillchar(bfnote_,maxfnoten*sizeof(tnotemap),0);fnotew:=true;rewrite(fnote);bjfnote:=-1;
  end;
InitDraw();
SetMidiVol(volamax-2);
loadfile();
ResetMidiHard(midiOuti);
repeat
if isnextmsg then DoAct() else Delay(1);
if GetMidiTime()>finaltime then
  case loop of
    0:begin if pauseb=false then PauseMidi();SetMidiTime(-1);end;
    1:SetMidiTime(-1);
    2:PlayMidi(get_file(find_current+1));
    end;
EnterCriticalSection(csfevent0);
if eventi<eventn then
  begin
  msgbufn:=-$100;
  while GetMidiTime()>GetFEvent0TickTime(eventi) do
    begin
    if fb then begin fi:=eventi;eventi:=0;event0[eventi]:=GetFEvent0(fi);end;
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
            if event0[eventi].msg and $F0=$90 then
              begin
              notei:=(event0[eventi].msg shr 8 and $7F) or ((event0[eventi].track or event0[eventi].msg and $F shl 8) shl 8);
              notech[notei]:=event0[eventi].chord;
              notec[notei]:=event0[eventi].track or event0[eventi].msg and $F shl 8;
              if kbdcb=0 then
                kbdc[notei and $7F]:=GetKeyChordC(notei and $7F,notech[notei])
              else
                kbdc[notei and $7F]:=GetKeynoteC(notei and $7F,notec[notei]);
              end;
            if event0[eventi].msg and $F0=$80 then
              begin
              notei:=(event0[eventi].msg shr 8 and $7F) or ((event0[eventi].track or event0[eventi].msg and $F shl 8) shl 8);
              kbdc[notei and $7F]:=-1;
              end;
            end;
          LeaveCriticalSection(cs3);
          if not((event0[eventi].msg and $F0=$90) and (event0[eventi].msg shr 16 and $F0=0)) then
          if (msgbufn<0) then
            begin
            midiOutShortMsg(midiOut,event0[eventi].msg);
            msgbufn:=msgbufn+1;
            end
          else if msgbufn<maxbuf-1 then
            begin
            msgbuf0:=event0[eventi].msg;
            case msgbuf0 and $F0 shr 4 of
              $8:msgbuf2:=2;
              $9:msgbuf2:=2;
              $A:msgbuf2:=2;
              $B:msgbuf2:=2;
              $C:msgbuf2:=1;
              $D:msgbuf2:=1;
              $E:msgbuf2:=2;
              else msgbuf2:=-1;
              end;
            for msgbuf1:=0 to msgbuf2 do
              begin
              msgbuf[msgbufn]:=msgbuf0 and $FF;
              msgbuf0:=msgbuf0 shr 8;
              msgbufn:=msgbufn+1;
              end
            end
          end
        end
      end
    else
      if event0[eventi].tempo>0 then
        tempo:=event0[eventi].tempo;
    chord:=event0[eventi].chord;
    if fb then eventi:=fi;
    eventi:=eventi+1;
    if eventi>=eventn then break;
    end;
  end;
LeaveCriticalSection(csfevent0);
if msgbufn>=0 then
  begin
  with msghdr do
    begin
    lpData:=@msgbuf;
    dwBufferLength:=msgbufn;
    dwFlags:=0;
    end;
  midiOutPrepareHeader(midiOut,@msghdr,sizeof(msghdr));
  midiOutLongMsg(midiOut,@msghdr,sizeof(msghdr));
  midiOutUnPrepareHeader(midiOut,@msghdr,sizeof(msghdr));
  end;
until not(iswin());
if fb then
  begin
  close(fevent0);DeleteFile(GetTempDir(false)+'fevent0'+rs);
  close(fevent);DeleteFile(GetTempDir(false)+'fevent'+rs);
  close(fnote);DeleteFile(GetTempDir(false)+'fnote'+rs);
  end;
midiOutClose(midiOut);
savefile();
CloseKey();
end.
