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
var rs:ansistring;
var framerate:longword=120;
var loop:longword=1;
var midipos:longword;
var voli:longword;
var kbdcb:longword=0;
var kchb:longword=0;
var para:ansistring;
var parai:longword;
var fdir:ansistring;
var hwm:longword;
const mult0=400;
var mult:longword=100;
var autofresh:longword=0;
var midiOuti:longword=0;
var msgbufn0:longword=$100;

procedure PlayMidi(fname:ansistring);forward;

procedure SetMidiTime(settime:single);forward;

function GetMidiTime():single;forward;

procedure savefile();
begin
SetKeyS('fnames',fnames);
SetKeyI('framerate',framerate);
SetKeyI('midipos',round((GetMidiTime()+1)*1000));
SetKeyI('voli',voli);
SetKeyI('loop',loop);
SetKeyI('kbdcb',kbdcb);
SetKeyI('kchb',kchb);
SetKeyI('mult',mult);
SetKeyI('autofresh',autofresh);
SetKeyI('midiouti',midiouti);
SetKeyI('framerate',framerate);
SetKeyI('msgbufn0',msgbufn0);
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
GetKeyI('mult',mult);
GetKeyI('autofresh',autofresh);
GetKeyI('midiouti',midiouti);
GetKeyI('framerate',framerate);
GetKeyI('msgbufn0',msgbufn0);
if (para<>'') and (para<>fnames) then begin fnames:=para;midipos:=0;end;
if fileexists(fnames) then begin PlayMidi(fnames);SetMidiTime(midipos/1000-1);end;
end;
