var regkey:HKEY;

procedure OpenReg();
begin
RegCreateKeyEx(HKEY_CURRENT_USER,
PChar('SoftWare\ax_midi_player'),
0,nil,0,KEY_ALL_ACCESS,nil,regkey,nil);
end;

procedure CloseReg();
begin
RegCloseKey(regkey);
end;

procedure GetKeySW(kname:ansistring;var s:unicodestring);
var regtype:longword=REG_SZ;
var ca:array[0..$100*2-1]of byte;
var size:longword=$100*2;
begin
if RegQueryValueExW(regkey,PWChar(unicodestring(kname)),nil,@regtype,@ca,@size)=ERROR_SUCCESS then
  s:=copy(UnicodeString(pwchar(@ca)),0,length(unicodestring(pwchar(@ca))));
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

procedure SetKeySW(kname:ansistring;s:unicodestring);
begin
RegSetValueExW(regkey,PWChar(UnicodeString(kname)),0,REG_SZ,PWChar(s),length(s)*2);
end;

procedure SetKeyS(kname:ansistring;s:ansistring);
begin
RegSetValueEx(regkey,PChar(kname),0,REG_SZ,PChar(s),length(PChar(s)));
end;

procedure SetKeyI(kname:ansistring;i:longword);
begin
RegSetValueEx(regkey,PChar(kname),0,REG_DWORD,@i,sizeof(DWORD));
end;
var midipos:longword;
var voli:longword;
var spd1:longword;
var kchord0:longword;
var kkey0:longword;
var fnames:unicodestring;
var midiouti:longword;
var msgbufb0:longword;
var msgbufb1:longword;
var autofresh:longword;
var mult:longword;
var kbdcb:longword;
var kchb:longword;
var kchb2:longword;
var kmessure:longword;
var loop:longword;
var fbi:longword;
var tempdir:ansistring;
var msgbufn0:longword;
var msgvol0:longword;
var maxkbdc:longword;
var framerate:longword;
var helpb:longword;
var chancolor:ansistring;
{$ifdef video}
var vname:ansistring;
var vrate:longword;
var vquality:longword;
{$endif}

procedure ResetReg();
begin
midipos:=0;
voli:=14;
spd1:=100;
kchord0:=0;
kkey0:=128;
fnames:='midiplayer by ax_pokl';
midiouti:=0;
msgbufb0:=0;
msgbufb1:=0;
autofresh:=1;
mult:=100;
kbdcb:=0;
kchb:=0;
kchb2:=0;
kmessure:=0;
loop:=1;
fbi:=0;
msgbufn0:=128;
msgvol0:=3;
maxkbdc:=$40;
framerate:=120;
helpb:=0;
chancolor:='85,170,255,42,127,212,21,63,106,148,191,233,10,31,52,74,95,116,137,159,180,201,222,244';
{$ifdef video}
vname:='midiplayer.mkv';
vrate:=30;
vquality:=4;
{$endif}
end;

procedure SaveReg();
begin
OpenReg();
SetKeyI('midipos',midipos);
SetKeyI('voli',voli);
SetKeyI('spd1',spd1);
SetKeyI('kchord0',kchord0);
SetKeyI('kkey0',kkey0);
SetKeySW('fnames',fnames);
SetKeyI('midiouti',midiouti);
SetKeyI('msgbufb0',msgbufb0);
SetKeyI('msgbufb1',msgbufb1);
SetKeyI('autofresh',autofresh);
SetKeyI('mult',mult);
SetKeyI('kbdcb',kbdcb);
SetKeyI('kchb',kchb);
SetKeyI('kchb2',kchb2);
SetKeyI('kmessure',kmessure);
SetKeyI('loop',loop);
SetKeyI('fbi',fbi);
SetKeyS('tempdir',tempdir);
SetKeyI('msgbufn0',msgbufn0);
SetKeyI('msgvol0',msgvol0);
SetKeyI('maxkbdc',maxkbdc);
SetKeyI('framerate',framerate);
SetKeyI('helpb',helpb);
SetKeyS('chancolor',chancolor);
{$ifdef video}
SetKeyS('vname',vname);
SetKeyI('vrate',vrate);
SetKeyI('vquality',vquality);
{$endif}
CloseReg();
end;

procedure LoadReg();
begin
OpenReg();
GetKeyI('midipos',midipos);
GetKeyI('voli',voli);
GetKeyI('spd1',spd1);
GetKeyI('kchord0',kchord0);
GetKeyI('kkey0',kkey0);
GetKeySW('fnames',fnames);
GetKeyI('midiouti',midiouti);
GetKeyI('msgbufb0',msgbufb0);
GetKeyI('msgbufb1',msgbufb1);
GetKeyI('autofresh',autofresh);
GetKeyI('kbdcb',kbdcb);
GetKeyI('kchb',kchb);
GetKeyI('kchb2',kchb2);
GetKeyI('mult',mult);
GetKeyI('kmessure',kmessure);
GetKeyI('loop',loop);
GetKeyI('fbi',fbi);
GetKeyS('tempdir',tempdir);
GetKeyI('msgbufn0',msgbufn0);
GetKeyI('msgvol0',msgvol0);
GetKeyI('maxkbdc',maxkbdc);
GetKeyI('framerate',framerate);
GetKeyI('helpb',helpb);
GetKeyS('chancolor',chancolor);
{$ifdef video}
GetKeyS('vname',vname);
GetKeyI('vrate',vrate);
GetKeyI('vquality',vquality);
{$endif}
CloseReg();
end;
