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

var rs:ansistring;
var fnames:ansistring;
var framerate:longword;
var loop:longword;
var midipos:longword;
var voli:longword;
var kbdcb:longword;
var kchb:longword=0;
var kchb2:longword=0;
var para:ansistring;
var parai:longword;
var fdir:ansistring;
var hwm:longword;
const mult0=600;
var mult:longword;
var autofresh:longword;
var midiOuti:longword;
var msgbufn0:longword;
var kchord0:longword;
var kkey0:longint;
var kmessure:longword;
var msgvol0:longword;

procedure PlayMidi(fname:ansistring);forward;

procedure SetMidiTime(settime:single);forward;

function GetMidiTime():single;forward;

procedure resetfile();
begin
fnames:='midiplayer by ax_pokl';
framerate:=120;
midipos:=0;
voli:=0;
loop:=1;
kbdcb:=0;
kchb:=0;
kchb2:=0;
mult:=100;
autofresh:=0;
midiouti:=0;
msgbufn0:=32;
kchord0:=0;
kkey0:=0;
kmessure:=0;
msgvol0:=2;
end;

procedure savefile();
begin
SetKeyS('fnames',fnames);
SetKeyI('framerate',framerate);
SetKeyI('midipos',round((GetMidiTime()+1)*1000));
SetKeyI('voli',voli);
SetKeyI('loop',loop);
SetKeyI('kbdcb',kbdcb);
SetKeyI('kchb',kchb);
SetKeyI('kchb2',kchb2);
SetKeyI('mult',mult);
SetKeyI('autofresh',autofresh);
SetKeyI('midiouti',midiouti);
SetKeyI('framerate',framerate);
SetKeyI('msgbufn0',msgbufn0);
SetKeyI('kmessure',kmessure);
SetKeyI('msgvol0',msgvol0);
end;

procedure loadfile();
begin
resetfile();
GetKeyS('fnames',fnames);
GetKeyI('framerate',framerate);
GetKeyI('midipos',midipos);
GetKeyI('voli',voli);
GetKeyI('loop',loop);
GetKeyI('kbdcb',kbdcb);
GetKeyI('kchb',kchb);
GetKeyI('kchb2',kchb2);
GetKeyI('mult',mult);
GetKeyI('autofresh',autofresh);
GetKeyI('midiouti',midiouti);
GetKeyI('framerate',framerate);
GetKeyI('msgbufn0',msgbufn0);
GetKeyI('kmessure',kmessure);
GetKeyI('msgvol0',msgvol0);
if (para<>'') and (para<>fnames) then begin fnames:=para;midipos:=0;end;
if fileexists(fnames) then begin PlayMidi(fnames);SetMidiTime(midipos/1000-1);end;
end;
