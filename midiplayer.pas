{$R midiplayer.res}
//{$APPTYPE GUI}
program midiplayer;
uses Windows,MMSystem,Display,Sysutils;

var regkey:HKEY;

procedure OpenKey();
begin
RegCreateKeyEx(HKEY_CURRENT_USER,
PChar('SoftWare\ax_midi_player'),
0,nil,0,KEY_ALL_ACCESS,nil,regkey,nil);
end;

procedure CloseKey();
begin
RegCloseKey(regkey);
end;

procedure GetKeyS(kname:ansistring;var s:ansistring);
var regtype:longword=REG_SZ;
var ca:array[0..$100-1]of byte;
var size:longword=$100;
begin
if RegQueryValueEx(regkey,PChar(kname),nil,@regtype,@ca,@size)=ERROR_SUCCESS then
  s:=PChar(@ca);
end;

procedure GetKeyI(kname:ansistring;var i:longword);
var regtype:longword=REG_DWORD;
var ca:array[0..3] of byte;
var size:longword=4;
begin
if RegQueryValueEx(regkey,PChar(kname),nil,@regtype,@ca,@size)=ERROR_SUCCESS then
  i:=ca[3] shl 24 or ca[2] shl 16 or ca[1] shl 8 or ca[0]
end;

procedure SetKeyS(kname:ansistring;s:ansistring);
begin
RegSetValueEx(regkey,PChar(kname),0,REG_SZ,PChar(s),length(PChar(s)));
end;

procedure SetKeyI(kname:ansistring;i:longword);
begin
RegSetValueEx(regkey,PChar(kname),0,REG_DWORD,@i,sizeof(DWORD));
end;

var fnames:ansistring='midiplayer by ax_pokl';
var framerate:longword=120;
var loop:longword=1;
var midipos:longword;
var voli:longword;
var kbdcb:longword=1;
var kchb:longword=0;
var para:ansistring;
var parai:longword;
var fdir:ansistring;
var hwm:longword;

procedure PlayMidi(fname:ansistring);forward;

procedure SetMidiTime(settime:double);forward;

function GetMidiTime():double;forward;

procedure savefile();
begin
SetKeyS('fnames',fnames);
SetKeyI('framerate',framerate);
SetKeyI('midipos',round((GetMidiTime()+1)*1000));
SetKeyI('voli',voli);
SetKeyI('loop',loop);
SetKeyI('kbdcb',kbdcb);
SetKeyI('kchb',kchb);
end;

procedure loadfile();
begin
GetKeyS('fnames',fnames);
GetKeyI('framerate',framerate);
GetKeyI('midipos',midipos);
GetKeyI('voli',voli);
GetKeyI('loop',loop);
GetKeyI('kbdcb',kbdcb);
GetKeyI('kchb',kchb);
if (para<>'') and (para<>fnames) then begin fnames:=para;midipos:=0;end;
if fileexists(fnames) then begin PlayMidi(fnames);SetMidiTime(midipos/1000-1);end;
end;

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

var cs1:TRTLCriticalSection;
var cs2:TRTLCriticalSection;

type tevent=record track,curtick,msg,tempo,chord:longword;ticktime:double;end;
const maxevent=$1000000;
var event:array[0..maxevent-1]of tevent;
var eventi:longint;
var eventn:longword=0;
//var event0:array of tevent;
var event0:array[0..maxevent-1]of tevent;
var eventj:longword;
var eventk:longint;

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
const chanc0:array[0..11]of longword=($55,$AA,$FF,$2A,$7F,$D4,$15,$6A,$BF,$3F,$94,$E9);

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

var len0,head:longword;
var fpos,flen:longword;
var dvs:word;
var len:longint;
var tick,curtick,tpq:longword;
var tempo:longword=500000;
var fps:double;
var stat0,stat,hex0,hex1,data0,data1:byte;
var lens:longword;
var meta:byte;
var msg:longword;
var finaltime:double;
var finaltick:longword;
var chord:byte=7;

var getb0:byte;
var getbb:boolean;
procedure GetB(b:byte);begin getb0:=b;getbb:=true;
len:=len+1;fpos:=fpos-1;end;
function Get1():byte;begin if fpos<flen then
begin if getbb then Get1:=getb0 else Get1:=GetByte();getbb:=false;
len:=len-1;fpos:=fpos+1;end else Get1:=0;end;
function Get2():Word;begin Get2:=Get1() shl 8 or Get1();end;
function Get3():longword;begin Get3:=Get2() shl 8 or Get1();end;
function Get4():longword;begin Get4:=Get3() shl 8 or Get1();end;
function Get0():longword;var l:longword=0;b:byte;n:shortint=0;
begin repeat b:=Get1();l:=(l shl 7) or (b and $7F);
n:=n+8;until (b and $80)=0;Get0:=l;end;
procedure swapc(var a,b:longword);var c:longword;begin c:=a;a:=b;b:=c;end;
function MixColor(a,b:longword;m:double):longword;var cmix:longword;
begin display.MixColor(a,b,cmix,m);MixColor:=cmix;end;
function t2s(r:double):ansistring;var h,m,s,ss:longword;
begin
if r<0 then r:=0;
ss:=trunc(r*1000);s:=ss div 1000;ss:=ss mod 1000;m:=s div 60;s:=s mod 60;h:=m div 60;m:=m mod 60;
t2s:=i2s(m)+':'+i2s(s,2,'0')+'.'+i2s(ss div 100);if h>0 then t2s:=i2s(h)+':'+i2s(m,2,'0')+':'+i2s(s,2,'0')+'.'+i2s(ss div 100);
end;
function r2s(bpm:double):ansistring;var r0,r1:longint;var s:ansistring='';
begin r0:=round(bpm*10) div 10;r1:=round(bpm*10) mod 10;s:=i2s(r0);if r1>0 then s:=s+'.'+i2s(r1);r2s:=s;end;

procedure AddEvent(tr,cu,ms,tm,ch:longword);
begin
with event[eventi] do
  begin
  track:=tr;
  curtick:=cu;
  msg:=ms;
  tempo:=tm;
  chord:=ch;
  end;
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
while GetFilePos<len0 do
  begin
  curtick:=0;
  head:=0;
  while (head<>$4D54726B) and (GetFilePos<len0) do head:=Get4();
  if GetFilePos>=len0 then break;
  len:=Get4();
  while len>0 do
    begin
//  writeln(i2hs(getfilepos()),#9);
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
//writeln(eventi,#9,tracki,#9,curtick,#9,meta,#9,tempo,#9,Data1,#9,Data0);
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
           addEvent(tracki,curtick,meta shl 8 or Stat,0,chord);
//writeln(eventi,#9,tracki,#9,curtick,#9,meta,#9,tempo,#9,Data1,#9,Data0,#9,event[eventi].chord);
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
//writeln(eventi,#9,tracki,#9,curtick,#9,msg,#9,0,#9,Data1,#9,Data0,#9,tick);
        addevent(tracki,curtick,msg,0,0);
        end;
    end;
  track1[tracki]:=eventi;
  tracki:=tracki+1;
  end;
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
eventn:=eventi;
track0[0]:=0;
for tracki:=1 to trackn-1 do track0[tracki]:=track1[tracki-1];
//setlength(event0,0);
//setlength(event0,eventn);
eventj:=0;
while (eventj<eventn) do
  begin
  curtick:=$FFFFFFFF;
  for tracki:=0 to trackn-1 do
    if track0[tracki]<track1[tracki] then
      if event[track0[tracki]].curtick<curtick then
        begin
        trackj:=tracki;
        curtick:=event[track0[tracki]].curtick;
        end;
  event0[eventj]:=event[track0[trackj]];
  track0[trackj]:=track0[trackj]+1;
  eventj:=eventj+1;
  end;
tempo:=5000000;
finaltime:=0;
curtick:=0;
sig0:=1;sig:=1;
chordtmp:=-1;
for eventi:=0 to eventn-1 do
  begin
  if event0[eventi].msg and $FFFF=$58FF then
    begin
    sig0:=event0[eventi].msg shr 16 and $FF;
    sig1:=event0[eventi].msg shr 24 and $FF;
    sig:=1;while sig1>0 do begin sig:=sig*2;sig1:=sig1-1;end;
    end;
  while curtick<event0[eventi].curtick do curtick:=curtick+tpq*sig0*4 div sig;
  if eventi=0 then tick:=event0[eventi].curtick else tick:=event0[eventi].curtick-event0[eventi-1].curtick;
  if eventi=0 then event0[eventi].ticktime:=0 else event0[eventi].ticktime:=event0[eventi-1].ticktime;
  if tpq>0 then event0[eventi].ticktime:=event0[eventi].ticktime+tick/tpq*(tempo/1000000);
  if fps>0 then event0[eventi].ticktime:=event0[eventi].ticktime+tick/fps;
  if event0[eventi].tempo>0 then tempo:=event0[eventi].tempo;
  if event0[eventi].msg=$5AFF then event0[eventi].tempo:=tempo;
  if event0[eventi].msg=$5AFF then if curtick=event0[eventi].curtick then event0[eventi].msg:=$5BFF;
  if event0[eventi].msg and $FFFF=$59FF then chord:=event0[eventi].chord else event0[eventi].chord:=chord;
  if event0[eventi].msg and $FFFF=$59FF then if chordtmp=-1 then chordtmp:=chord;
  finaltime:=max(finaltime,event0[eventi].ticktime+1);
  end;
end;

var midiOut:longword;
var firsttime:double;
var pauseb:boolean;
var pausetime:double;
var spd0,spd1:double;

const volamax=16;
const vola:array[1..volamax]of double=
(0,0.01,0.02,0.03,0.04,0.06,0.08,0.12,0.16,0.25,0.35,0.5,0.7,1,1.41,2);
var volchana:array[0..$F]of byte;
var volchani:byte;

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

function GetMidiTime():double;
begin
if pauseb then GetMidiTime:=pausetime
else GetMidiTime:=GetTimeR()*spd0-firsttime;
end;

procedure SetMidiTime(settime:double);
var chani:byte;
var tempo0:longword;
begin
if settime<=0 then midiOutReset(midiOut);
for chani:=0 to $F do midiOutShortMsg(midiOut,$00007BB0 or chani);
firsttime:=GetTimeR()*spd0-settime;
eventj:=eventn;
eventk:=eventn-1;
while eventk>=0 do
  begin
  if event0[eventk].ticktime>=settime then eventj:=eventk;
  eventk:=eventk-1;
  end;
for eventk:=eventi to min(eventj,eventn-1) do
  if event0[eventk].msg and $F0<>$90 then
    begin
    if event0[eventk].msg and $F0 shr 4<$F then
      if(event0[eventk].msg and $F0 shr 4=$B)
      and(event0[eventk].msg shr 8 and $FF=$07)then
        SetMidiChanVol(event0[eventk].msg and $F,event0[eventk].msg shr 16 and $FF)
      else
        midiOutShortMsg(midiOut,event0[eventk].msg)
    end;
tempo0:=500000;
for eventk:=eventn-1 downto 1 do
  if(event0[eventk].msg and $FFFF=$51FF)then
    tempo0:=event0[eventk].tempo;
for eventk:=1 to min(eventj,eventn-1) do
  if(event0[eventk].msg and $FFFF=$51FF)then
    tempo0:=event0[eventk].tempo;
tempo:=tempo0;
eventi:=eventj;
if pauseb then pausetime:=settime;
if voli>0 then SetMidiVol(voli);
if settime<=0 then if chordtmp<>-1 then chord:=chordtmp;
end;

procedure PauseMidi();
begin
if pauseb=false then pausetime:=GetMidiTime();
SetMidiTime(pausetime);
pauseb:=not(pauseb);
end;

var note0:array[$00..$7F]of double;
var note1:array[$00..$7F]of double;
var notec:array[$00..$7F]of longword;
var notech:array[$00..$7F]of byte;

type tnotemap=record note:byte;note0,note1:double;notec:longword;chord:byte;end;

const maxnotemap=maxevent;
var notemap:array[0..maxnotemap]of tnotemap;
var notemapi:longint;
var notemapn:longword;

const black0=$0F0F0F;
const black1=$0F0F0F;
const gray0=$1F1F1F;
const gray1=$3F3F3F;
const gray2=$9F9F9F;

const kbd0n=21;
const kbd1n=21+87;
var kbd0:byte=kbd0n;
var kbd1:byte=kbd1n;

procedure AddNoteMap(notei:byte);
begin
notemap[notemapi].note:=notei;
notemap[notemapi].note0:=note0[notei];
notemap[notemapi].note1:=note1[notei];
notemap[notemapi].notec:=notec[notei];
notemap[notemapi].chord:=notech[notei];
chancn[notec[notei]]:=chancn[notec[notei]]+1;
notemapi:=notemapi+1;
end;

procedure CreateNoteMap();
var notei:byte;
var ei:longint;
begin
for chani:=0 to maxchan-1 do chancn[chani]:=0;
for chani:=0 to maxchan-1 do chancc[chani]:=chani;
for chani:=0 to maxchan-1 do chancw[chani]:=HSN2RGB(chanc0[chani mod 12]or $9FFF00);
for chani:=0 to maxchan-1 do chancb[chani]:=MixColor(chancw[chani],black0,3/4);
notemapi:=0;
for notei:=0 to $7F do
  begin
  note0[notei]:=-1;
  note1[notei]:=0;
  end;
kbd0:=kbd0n;
kbd1:=kbd1n;
for ei:=0 to eventn-1 do
if event0[ei].msg and $F<>$9 then
  begin
  if event0[ei].msg and $F0=$90 then
    if event0[ei].msg shr 16 and $00FF=0 then
      event0[ei].msg:=event0[ei].msg and $FFFFFF8F;
  if event0[ei].msg and $F0=$90 then
    begin
    notech[notei]:=event0[ei].chord;
    notei:=event0[ei].msg shr 8 and $7F;
    kbd0:=min(notei,kbd0);
    kbd1:=max(notei,kbd1);
    notec[notei]:=event0[ei].track or event0[ei].msg and $F shl 8;
    if note0[notei]>=note1[notei] then
      begin
      note1[notei]:=event0[ei].ticktime;
      AddNoteMap(notei);
      end;
    note0[notei]:=event0[ei].ticktime;
    end;
  if event0[ei].msg and $F0=$80 then
    begin
    notech[notei]:=event0[ei].chord;
    notei:=event0[ei].msg shr 8 and $7F;
    note1[notei]:=event0[ei].ticktime;
    AddNoteMap(notei);
    end;
  end;
for notei:=0 to $7F do
  if note0[notei]>note1[notei] then
    begin
    note1[notei]:=finaltime;
    AddNoteMap(notei);
    end;
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
var fw,fh:longword;
var frametime:double;
var printtime:double;

const mult0=600;
var mult:longword;

var k_shift,k_ctrl:boolean;
var k_pos:double;

const klen0:double=1.15;
const klen1:double=0.65;
var kbd:array[0..11]of double;
const keyblack:array[0..11]of byte=(0,1,0,1,0,0,1,0,1,0,1,0);
const keychord:array[0..1,0..11]of char=(
('1',' ','2',' ','3','4',' ','5',' ','6',' ','7'),
('C','d','D','e','E','F','g','G','a','A','b','B'));

var kleny0:double=6.5;
var kleny1:double=4.5;
var kbdc:array[$00..$7F]of longword;
var kbdcc:array[0..11]of longword;
var kbdci:byte;

var kbdi,kbdn:byte;

const fhr=0.7;

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

procedure _Bar(x,y,w,h:longint;cfg,cbg:longword);
begin Bar(x,GetHeight()-y-h,w,h,cfg,cbg);end;

procedure _Line(x,y,w,h:longint;c:longword);
begin Line(x,GetHeight()-y-h,w,h,c);end;

procedure _DrawTextXY(s:ansistring;x,y:longint;c:longword);
begin DrawTextXY(s,x,GetHeight()-y-fh-2,c);end;

function GetKeyChord(k:byte;chord:longword):ansistring;
begin GetKeyChord:=keychord[kchb,(k-chordb[chord]+12) mod 12]end;

function GetKeyChord0(k:byte;chord:longword):byte;
begin GetKeyChord0:=(k-chordb[chord]+12) mod 12;end;

function GetKeyChordC(k:byte;chord:longword):longword;
begin GetKeyChordC:=kbdcc[GetKeyChord0(k,chord)];end;

function GetKeyChord(k:byte):ansistring;
begin GetKeyChord:=GetKeyChord(k,chord);end;

function IsKeynoteBlack(k:byte):byte;
begin IsKeynoteBlack:=keyblack[k mod 12];end;

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
begin if(IsKeynoteBlack(k)=1)then GetKeynoteC:=chancb[chan] else GetKeynoteC:=chancw[chan];end;

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

procedure DrawMessureLine(t:double;ms:longword;tempo:longword;c:longword);
var w0,y:longint;
begin
w0:=GetKeynoteW0();
y:=trunc((t-printtime)*mult*GetWidth()/mult0)+round(w0*kleny0);
if (y>=round(w0*kleny0)) and (y<GetHeight()) then _line(0,y,GetWidth(),0,c);
if (y+fh>=round(w0*kleny0)) and (y<GetHeight()) then
  begin
  _DrawTextXY(i2s(ms),0,y,c);
  _DrawTextXY(r2s(60000000/tempo*spd0),GetWidth()-fw*length(r2s(60000000/tempo*spd0)),y,c);
  end;
end;

procedure DrawChordLine(t:double;ch:byte;c:longword);
var w0,y:longint;
begin
w0:=GetKeynoteW0();
y:=trunc((t-printtime)*mult*GetWidth()/mult0)+round(w0*kleny0);
if (y>=round(w0*kleny0)) and (y<GetHeight()) then _line(0,y,GetWidth(),0,c);
if (y+fh>=round(w0*kleny0)) and (y<GetHeight()) then _DrawTextXY(chords[ch],0,y-fh-4,c);
end;

procedure DrawMessureLineAll();
var ei:longint;
begin
EnterCriticalSection(cs2);
for ei:=1 to eventn-1 do
  begin
  if event0[ei].msg=$5AFF then DrawMessureLine(event0[ei].ticktime,event0[ei].curtick div tpq,event0[ei].tempo,gray0);
  if event0[ei].msg=$5BFF then DrawMessureLine(event0[ei].ticktime,event0[ei].curtick div tpq,event0[ei].tempo,gray1);
  end;
for ei:=1 to eventn-1 do
  if event0[ei].msg=$59FF then DrawChordLine(event0[ei].ticktime,event0[ei].chord,gray2);
LeaveCriticalSection(cs2);
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
var kbd:byte;
var x,w,w0:longint;
var kbd0i,kbd1i:byte;
begin
kbd0i:=kbd0;
kbd1i:=kbd1;
if IsKeynoteBlack(kbd0i)=1 then kbd0i:=max($00,kbd0i-1);
if IsKeynoteBlack(kbd1i)=1 then kbd1i:=min($7F,kbd1i+1);
for kbd:=kbd0i to kbd1i do
  begin
  x:=GetKeynoteX(kbd);
  w:=GetKeynoteX0(kbd)-GetKeynoteX(kbd);
  w0:=GetKeynoteW0();
  if IsKeynoteBlack(kbd)=0 then
    begin
    _Bar(x,0,w,round(w0*kleny0),black,kbdc[kbd]);
    if kbdc[kbd]=white then
      _DrawTextXY(GetKeyChord(kbd),x+(w-fw)div 2,4,MixColor(white,black,1/2))
    else
      _DrawTextXY(GetKeyChord(kbd),x+(w-fw)div 2,0,black)
    end;
  end;
for kbd:=kbd0i to kbd1i do
  begin
  x:=GetKeynoteX(kbd);
  w:=GetKeynoteX0(kbd)-GetKeynoteX(kbd);
  w0:=GetKeynoteW0();
  if IsKeynoteBlack(kbd)=1 then
    begin
    _Bar(x,round(w0*(kleny0-kleny1)),w,round(w0*kleny1),black,kbdc[kbd]);
    if kbdc[kbd]=black then
      _DrawTextXY(GetKeyChord(kbd),x+(w-fw)div 2,round(w0*(kleny0-kleny1))+4,MixColor(black,white,1/2))
    else
      _DrawTextXY(GetKeyChord(kbd),x+(w-fw)div 2,round(w0*(kleny0-kleny1)),black);
    end;
  end;
end;

procedure DrawNote(notemapi:longword);
var x,y,w,w0:longint;
begin
x:=GetKeynoteX(notemap[notemapi].note);
w:=GetKeynoteX0(notemap[notemapi].note)-GetKeynoteX(notemap[notemapi].note);
w0:=GetKeynoteW0();
y:=trunc((notemap[notemapi].note0-printtime)*mult*GetWidth()/mult0)+round(w0*kleny0);
h:=trunc((notemap[notemapi].note1-notemap[notemapi].note0)*mult*GetWidth()/mult0);
h:=max(3,h);
if (y<round(w0*kleny0)) and (y+h>round(w0*kleny0)) then
  begin
  if kbdcb=1 then
    kbdc[notemap[notemapi].note]:=GetKeyChordC(notemap[notemapi].note,notemap[notemapi].chord)
  else
    kbdc[notemap[notemapi].note]:=GetKeynoteC(notemap[notemapi].note,notemap[notemapi].notec);
  end;
h:=max(round(fh*fhr),h);
if (y<GetHeight()) and (y+h>round(w0*kleny0)) then
  begin
  if kbdcb=1 then
    _Bar(x,y,w,h,black0,GetKeyChordC(notemap[notemapi].note,notemap[notemapi].chord))
  else
    _Bar(x,y,w,h,black0,GetKeynoteC(notemap[notemapi].note,notemap[notemapi].notec));
  _DrawTextXY(GetKeyChord(notemap[notemapi].note,notemap[notemapi].chord),x+(w-fw)div 2,min(y+round((h-fh)*fhr),y),black);
  end;
end;

procedure DrawNoteAll();
begin
EnterCriticalSection(cs1);
for kbdci:=$00 to $7F do
  if IsKeynoteBlack(kbdci)=1 then
    kbdc[kbdci]:=black
  else
    kbdc[kbdci]:=white;
for notemapi:=0 to notemapn-1 do
  if(IsKeynoteBlack(notemap[notemapi].note)=0)then
    DrawNote(notemapi);
for notemapi:=0 to notemapn-1 do
  if(IsKeynoteBlack(notemap[notemapi].note)=1)then
    DrawNote(notemapi);
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
var bpm:double;
var spds:ansistring='';
begin
bpm:=60000000/tempo*spd0;
if(bpm>0)then
  begin
  if round(spd0*100)<>100 then spds:='('+i2s(round(spd0*100))+'%)';
  SetDrawFont(1.5);
  DrawTextXY(r2s(bpm)+' BPM',(GetWidth()-fw*length(r2s(bpm)+' BPM'))div 2,0,white);
  SetDrawFont();
  DrawTextXY(spds,(GetWidth()-fw*length(spds))div 2,round(fh*1.5),white);
  end;
end;

procedure DrawFPS();
var fpss:ansistring='';
begin
fpss:=i2s(GetFPS())+'/'+i2s(framerate);
if abs(GetFPSR-framerate)>1 then
  DrawTextXY(fpss,GetWidth()-fw*length(fpss),0,white);
end;

procedure DrawLoad();
begin
if flen>0 then if fpos<flen then
  _Line(0,GetHeight() div 2,round(fpos/flen*GetWidth()),0,white);
end;

procedure DrawAll();
begin
SetDrawFont();
Clear();
GetDrawTime();
DrawNoteLine();
DrawMessureLineAll();
DrawNoteAll();
DrawKeyboard();
DrawTime();
DrawChord();
DrawBPM();
DrawLoop();
DrawFPS();
DrawLoad();
FreshWin();
end;

procedure DrawTitle();
var stitle:ansistring;
begin
stitle:='';
if (finaltime>0) then
  stitle:=stitle+'['+i2s(max(0,trunc(GetMidiTime()*100/finaltime)))+'%]';
stitle:=stitle+ExtractFileName(fnames);
if (finaltime>0) then
  stitle:=stitle+'('+chords[chord]+')';
if (finaltime>0) then
  stitle:=stitle+'['+i2s(find_current)+'/'+i2s(find_count)+']';
if spd0>0 then if round(spd0*100)<>100 then
  stitle:=stitle+'('+i2s(longword(round(spd0*100)))+'%)';
if mult>0 then if mult<>100 then
  stitle:=stitle+'<'+i2s(mult)+'%>';
if voli>0 then if round(vola[voli]*100)<>100 then
  stitle:=stitle+'['+i2s(longword(round(vola[voli]*100)))+'%]';
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
mult:=100;
spd0:=1;
eventi:=0;
pauseb:=false;
InitMidiChanVol($7F);
SetMidiTime(-1);
end;

procedure ResetMidiSoft();
var tmptime:double;
begin
tmptime:=GetMidiTime();
InitMidiChanVol($7F);
SetMidiTime(-1);
SetMidiTime(tmptime);
end;

procedure ResetMidiHard();
begin
midiOutClose(midiOut);
midiOutOpen(@midiOut,0,0,0,0);
ResetMidiSoft();
end;

procedure PlayMidi(fname:ansistring);
begin
//writeln(fname);
if(fileexists(fname))then
  begin
  find_file(fname);
  fnames:=fname;
  LoadMidi(fname);
  EnterCriticalSection(cs2);PrepareMidi();LeaveCriticalSection(cs2);
  EnterCriticalSection(cs1);CreateNoteMap();LeaveCriticalSection(cs1);
  ResetMidi();
  savefile();
  end;
end;

procedure helpproc();
begin
  if fileexists(fdir+'midiplayer.txt') then
    WinExec(PChar('notepad.exe '+fdir+'midiplayer.txt'),SW_SHOW)
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
if iskey() then
  begin
  if iskey(K_F1) then newthread(@helpproc);
  if iskey(K_F2) then ResetMidiSoft();
  if iskey(K_F3) then ResetMidiHard();
  if iskey(K_F5) then framerate:=max(10,framerate-((framerate-1) div 60+1));
  if iskey(K_F6) then framerate:=min(360,framerate+(framerate div 60+1));
  if iskey(K_F7) then mult:=min(400,mult+10);
  if iskey(K_F8) then mult:=max(10,mult-10);
  if iskey(K_F9) then kbdcb:=1-kbdcb;
  if iskey(K_F11) then kchb:=1-kchb;
  if iskey(K_F12) then loop:=(loop+1) mod 3;
  k_shift:=GetKeyState(VK_SHIFT)<0;
  k_ctrl:=GetKeyState(VK_CONTROL)<0;
  if iskey(K_RIGHT) or iskey(K_LEFT) then
    begin k_pos:=1;if k_ctrl then k_pos:=5;if k_shift then k_pos:=30;end;
  if iskey(K_LEFT) then SetMidiTime(max(-1,GetMidiTime()-k_pos));
  if iskey(K_RIGHT) then SetMidiTime(min(finaltime,GetMidiTime()+k_pos));
  if iskey(K_SPACE) then PauseMidi();
  if iskey(K_ADD) or iskey(K_SUB) then
    begin k_pos:=0.1;if k_ctrl then k_pos:=0.03;if k_shift then k_pos:=0.01;end;
  if iskey(K_ADD) or iskey(187) then begin spd1:=min(4.00,spd0+k_pos);end;
  if iskey(K_SUB) or iskey(189) then begin spd1:=max(0.10,spd0-k_pos);end;
  if iskey(K_ADD) or iskey(K_SUB) or iskey(187) or iskey(189) then
    begin firsttime:=firsttime+GetTimeR()*(spd1-spd0);spd0:=spd1;end;
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
    SetMidiTime(GetMousePosX()/GetWidth()*finaltime);
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
  if _ms.wParam>0 then SetMidiVol(min(volamax,voli+1));
  if _ms.wParam<0 then SetMidiVol(max(1,voli-1));
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
end;

begin
InitializeCriticalSection(cs1);
InitializeCriticalSection(cs2);
OpenKey();
DoCommandLine();
w:=2*GetScrWidth()div 3;
h:=2*GetScrHeight()div 3;
CreateWin(w,h,black1);
_wc.HIcon:=LoadImage(0,'midiplayer.ico',IMAGE_ICON,0,0,LR_LOADFROMFILE);
sendmessage(_hw,WM_SETICON,ICON_SMALL,longint(_wc.HIcon));
SetFontName('Consolas');
InitkbdPos();
InitkbdColor();
NewThread(@DrawProc);
SetMidiVol(volamax-2);
ResetMidiHard();
loadfile();
repeat
if isnextmsg then DoAct() else Delay(1);
if GetMidiTime()>finaltime then
  case loop of
    0:begin PauseMidi;SetMidiTime(-1);end;
    1:SetMidiTime(-1);
    2:PlayMidi(get_file(find_current+1));
    end;
if eventi<eventn then
  begin
  while GetMidiTime()>event0[eventi].ticktime do
    begin
//    with event0[eventi] do writeln(eventi,#9,track,#9,curtick,#9,ticktime:0:10,#9,msg,#9,tempo,#9,msg and $F0 shr 4);
    if event0[eventi].msg and $F0 shr 4<$F then
      if(event0[eventi].msg and $F0 shr 4=$B)
      and(event0[eventi].msg shr 8 and $FF=$07)then
        SetMidiChanVol(event0[eventi].msg and $F,event0[eventi].msg shr 16 and $FF)
      else
        midiOutShortMsg(midiOut,event0[eventi].msg)
    else
      if(event0[eventi].msg and $FFFF=$51FF)then tempo:=event0[eventi].tempo;
    chord:=event0[eventi].chord;
    eventi:=eventi+1;
    if eventi>=eventn then break;
    end;
  end;
until not(iswin());
midiOutClose(midiOut);
savefile();
CloseKey();
end.
