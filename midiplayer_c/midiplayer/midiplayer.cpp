#define _CRT_SECURE_NO_WARNINGS
#ifndef _CRT_SECURE_NO_WARNINGS
#define __STDC_LIB_EXT1__
#endif
#include "disp.h"
#include "mmsystem.h"
#include <Shlwapi.h>
unsigned long length(mystring s)
{
	return s.len;
}
HKEY regkey;
void openkey()
{
	RegCreateKeyEx(HKEY_CURRENT_USER, "SoftWare\\ax_midi_player", 0, NULL, 0, KEY_ALL_ACCESS, NULL, &regkey, NULL);
}
void closekey()
{
	RegCloseKey(regkey);
}
void getkeys(const char* kname, const char* &s)
{
	unsigned long regtype = REG_SZ;
	static char ca[0x100];
	unsigned long size = 0x100;
	if (RegQueryValueEx(regkey, kname, NULL, &regtype, (LPBYTE)&ca, &size) == ERROR_SUCCESS)
		s = &ca[0];
}
void getkeyi(const char* kname, unsigned long &i)
{
	unsigned long regtype = REG_DWORD;
	unsigned char ca[3 + 1];
	unsigned long size = 4;
	if (RegQueryValueEx(regkey, kname, NULL, &regtype, (LPBYTE)&ca, &size) == ERROR_SUCCESS)
	{
		i = ca[3] << 24 | ca[2] << 16 | ca[1] << 8 | ca[0];
	}
}
void setkeys(const char* kname, const char* s)
{
	RegSetValueEx(regkey, kname, 0, REG_SZ, (LPBYTE)s, length(s));
}
void setkeyi(const char* kname, unsigned long i)
{
	RegSetValueEx(regkey, kname, 0, REG_DWORD, (LPBYTE)&i, sizeof(DWORD));
}
mystring fnames("midiplayer by ax_pokl");
unsigned long framerate = 120;
unsigned long loop = 1;
unsigned long midipos;
unsigned long voli;
unsigned long kbdcb = 1;
unsigned long kchb = 0;
mystring para("");
unsigned long parai;
mystring fdir("");
HWND hwm;
void playmidi(const char* fname);
void setmiditime(double settime);
double getmiditime();
bool fileexists(const char * filename) {
	return PathFileExists(filename);
}
void savefile()
{
	setkeys("fnames", fnames);
	setkeyi("framerate", framerate);
	setkeyi("midipos", long(round((getmiditime() + 1) * 1000)));
	setkeyi("voli", voli);
	setkeyi("loop", loop);
	setkeyi("kbdcb", kbdcb);
	setkeyi("kchb", kchb);
}
void loadfile()
{
	const char* fnamesb;
	getkeys("fnames", fnamesb);
	fnames = fnamesb;
	getkeyi("framerate", framerate);
	getkeyi("midipos", midipos);
	getkeyi("voli", voli);
	getkeyi("loop", loop);
	getkeyi("kbdcb", kbdcb);
	getkeyi("kchb", kchb);
	if ((para.len != 0) && (para != fnames))
	{
		fnames = para;
		midipos = 0;
	}
	if (fileexists(fnames))
	{
		playmidi(fnames);
		setmiditime(midipos / 1000 - 1);
	}
}
const unsigned long find_max = 0x10000;
WIN32_FIND_DATA find_info;
HANDLE hFile;
unsigned long find_count;
unsigned long find_current;
mystring find_result[find_max + 1];
void find_file(const char* s)
{
	const char* dir;
	find_current = 0;
	find_result[0] = "";
	do
	{
		find_current = find_current + 1;
		if (find_current > find_count)break;
	} while (strcmp(find_result[find_current].s, s) != 0);
	if (find_current > find_count)
	{
		find_count = 0;
		char sdir[256];
#ifdef __STDC_LIB_EXT1__
		strcpy_s(&sdir[0], 0x100, s);
#else
		strcpy(&sdir[0], s);
#endif
		PathRemoveFileSpec(sdir);
		//dir=PathRemoveFileSpec(s);
		dir = (mystring)sdir + "\\";
		hFile = FindFirstFile((mystring)dir + "*", &find_info);
		if (hFile != INVALID_HANDLE_VALUE)
		{
			if ((strcmp(find_info.cFileName, ".") != 0) && (strcmp(find_info.cFileName, "..") != 0))
			{
				find_count = find_count + 1;
				find_result[find_count] = (mystring)dir + find_info.cFileName;
				if (strcmp(find_result[find_count].s, s) == 0) find_current = find_count;
			}
			while (FindNextFile(hFile, &find_info))
			{
				if ((strcmp(find_info.cFileName, ".") != 0) && (strcmp(find_info.cFileName, "..") != 0))
				{
					find_count = find_count + 1;
					find_result[find_count] = (mystring)dir + find_info.cFileName;
					if (strcmp(find_result[find_count].s, s) == 0) find_current = find_count;
				}
			}
		}
	}
}
const char* get_file(unsigned long n)
{
	const char* get_file_r;
	if (n < 1) n = n + find_count;
	if (n > find_count) n = n - find_count;
	find_current = n;
	get_file_r = find_result[find_current];
	return(get_file_r);
}
CRITICAL_SECTION cs1;
CRITICAL_SECTION cs2;
struct tevent
{
	unsigned long track;
	unsigned long curtick;
	unsigned long msg;
	unsigned long tempo;
	unsigned long chord;
	double ticktime;
};
double ticktime;
const unsigned long maxevent = 0x1000000;
tevent event[maxevent - 1 + 1];
long eventi;
unsigned long eventn = 0;
tevent event0[maxevent - 1 + 1];
unsigned long eventj;
long eventk;
const unsigned long maxtrack = 0x100;
const unsigned long maxchan = 0x1000;
unsigned long track0[maxtrack - 1 + 1];
unsigned long track1[maxtrack - 1 + 1];
long tracki;
unsigned long trackn;
unsigned long trackj;
unsigned long chancn[maxchan - 1 + 1];
unsigned long chancc[maxchan - 1 + 1];
unsigned long chancw[maxchan - 1 + 1];
unsigned long chancb[maxchan - 1 + 1];
unsigned long chani;
unsigned long chanj;
const unsigned long chanc0[12] = {
	0x55, 0xaa, 0xff, 0x2a, 0x7f, 0xd4, 0x15, 0x6a, 0xbf, 0x3f, 0x94, 0xe9
}
;
unsigned char chorda[2][15] = { {
		0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e
	}
	,{
		0x10, 0x11, 0x12, 0x13, 0x14,0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e
	}
}
;
unsigned char chordb[32] = {
	11, 6, 1, 8, 3, 10, 5, 0, 7, 2, 9, 4, 11, 6, 1, 0, 8, 3, 10, 5, 0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 0
}
;
const char* chords[32] = {
	"Cb", "Gb", "Db", "Ab","Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#", "",
	"ab", "eb", "bb", "f", "c", "g", "d", "a", "e", "b", "f#", "c#","g#", "d#", "a#", ""
}
;
char chord0, chord1;
char chordtmp = -1;
unsigned char sig0, sig1;
unsigned long sig;
const char loops[3] = {
	'N', 'S', 'A'
}
;
unsigned long len0, head;
unsigned long fpos, flen;
unsigned short dvs;
long len;
unsigned long tick, curtick, tpq;
unsigned long tempo = 500000;
double fps;
unsigned char stat0, stat, hex0, hex1, data0, data1;
unsigned long lens;
unsigned char meta;
unsigned long msg;
double finaltime;
unsigned long finaltick;
unsigned char chord_ = 7;
unsigned char getb0;
bool getbb0;
void getb(unsigned char b)
{
	getb0 = b;
	getbb0 = true;
	len = len + 1;
	fpos = fpos - 1;
}
unsigned char get1()
{
	unsigned char get1_r;
	if (fpos < flen)
	{
		if (getbb0)get1_r = getb0; else get1_r = getbyte();
		getbb0 = false;
		len = len - 1;
		fpos = fpos + 1;
	}
	else
		get1_r = 0;
	return get1_r;
}
unsigned short get2()
{
	unsigned short get2_r;
	get2_r = get1() << 8 | get1();
	return get2_r;
}
unsigned long get3()
{
	unsigned long get3_r;
	get3_r = get2() << 8 | get1();
	return get3_r;
}
unsigned long get4()
{
	unsigned long get4_r;
	get4_r = get3() << 8 | get1();
	return get4_r;
}
unsigned long get0()
{
	unsigned long l = 0;
	unsigned char b;
	char n = 0;
	unsigned long get0_r;
	do
	{
		b = get1();
		l = (l << 7) | (b & 0x7f);
		n = n + 8;
	} while (!((b & 0x80) == 0));
	get0_r = l;
	return get0_r;
}
void swapc(unsigned long &a, unsigned long &b)
{
	unsigned long c;
	c = a;
	a = b;
	b = c;
}
unsigned long mixcolor0(long a, long b, double m)
{
	unsigned long cmix = 0;
	unsigned long mixcolor_r;
	mixcolor(a, b, cmix, m);
	mixcolor_r = cmix;
	return mixcolor_r;
}
mystring i2s(long i, unsigned long l, const  char* c)
{
	const char* i2s_r;
	i2s_r = i2s(i);
	while (length(i2s_r) < l)
		i2s_r = (mystring)c + (mystring)i2s_r;
	return (mystring)i2s_r;
}
mystring t2s(double r)
{
	unsigned long h, m, s, ss;
	const char* t2s_r = "";
	if (r < 0) r = 0;
	ss = (long)trunc(r * 1000);
	s = ss / 1000;
	ss = ss % 1000;
	m = s / 60;
	s = s % 60;
	h = m / 60;
	m = m % 60;
	t2s_r = (mystring)i2s(m) + ":" + i2s(s, 2, "0") + "." + i2s(ss / 100);
	if (h > 0) t2s_r = (mystring)i2s(h) + ":" + i2s(m, 2, "0") + ":" + i2s(s, 2, "0") + "." + i2s(ss / 100);
	return t2s_r;
}
mystring r2s(double bpm)
{
	long r0, r1;
	const char* s = "";
	const char* r2s_r = "";
	r0 = long(round(bpm * 10)) / 10;
	r1 = long(round(bpm * 10)) % 10;
	s = i2s(r0);
	if (r1 > 0) s = (mystring)s + (mystring)"." + (mystring)i2s(r1);
	r2s_r = s;
	return r2s_r;
}
void addevent(unsigned long tr, unsigned long cu, unsigned long ms, unsigned long tm, unsigned long ch)
{
	event[eventi].track = tr;
	event[eventi].curtick = cu;
	event[eventi].msg = ms;
	event[eventi].tempo = tm;
	event[eventi].chord = ch;
	if (finaltick < cu) finaltick = cu;
	eventi = eventi + 1;
}
void loadmidi(mystring fname)
{
	openfile(fname);
	fpos = 0;
	flen = getfilelen();
	len0 = getfilelen();
	head = get4();
	if (head == 0x52494646)
	{
		get4();
		get4();
		get4();
		len0 = getbyte();
	}
	while ((head != 0x4d546864) && (getfilepos() < len0))
		head = get4();
	chord_ = 7;
	dvs = 0;
	if (getfilepos() < len0)
	{
		get4();
		get2();
		get2();
		dvs = get2();
		tpq = 0;
		if ((dvs & 0x8000) == 0) tpq = dvs & 0x7fff;
		fps = 0;
		if ((dvs & 0x8000) == 1) fps = (dvs & 0x00ff) / (-((dvs & 0x7fff) >> 8));
	}
	eventi = 0;
	tracki = 0;
	finaltick = 0;
	while (getfilepos() < len0)
	{
		curtick = 0;
		head = 0;
		while ((head != 0x4d54726b) && (getfilepos() < len0)) head = get4();
		if (getfilepos() >= len0) break;
		len = get4();
		while (len > 0)
		{
			tick = get0();
			curtick = curtick + tick;
			stat0 = get1();
			if (stat0 >= 0x80) stat = stat0; else getb(stat0);
			hex0 = stat / 16;
			hex1 = stat % 16;
			data0 = 0;
			data1 = 0;
			switch (hex0)
			{
			case 0x8:
			{
				data0 = get1();
				data1 = get1();
				break;
			}
			case 0x9:
			{
				data0 = get1();
				data1 = get1();
				break;
			}
			case 0xa:
			{
				data0 = get1();
				data1 = get1();
				break;
			}
			case 0xb:
			{
				data0 = get1();
				data1 = get1();
				break;
			}
			case 0xc:
			{
				data0 = get1();
				break;
			}
			case 0xd:
			{
				data0 = get1();
				break;
			}
			case 0xe:
			{
				data0 = get1();
				data1 = get1();
				break;
			}
			case 0xf:
			{
				if (hex1 == 0xf) meta = get1(); else meta = 0xff;
				lens = get0();
				if (meta == 0x51)
				{
					tempo = get3();
					addevent(tracki, curtick, meta << 8 | stat, tempo, 0);
				}
				else if (meta == 0x59)
				{
					chord0 = 0;
					chord1 = 0;
					if (lens > 0)
					{
						chord0 = char(get1());
						lens = lens - 1;
					}
					if (lens > 0)
					{
						chord1 = char(get1());
						lens = lens - 1;
					}
					while (lens > 0)
					{
						get1();
						lens = lens - 1;
					}
					if (chord1 != 0) chord1 = 1;
					chord_ = chorda[chord1][chord0 + 7];
					addevent(tracki, curtick, meta << 8 | stat, 0, chord_);
				}
				else if (meta == 0x58)
				{
					sig0 = 0;
					sig1 = 0;
					if (lens > 0)
					{
						sig0 = char(get1());
						lens = lens - 1;
					}
					if (lens > 0)
					{
						sig1 = char(get1());
						lens = lens - 1;
					}
					while (lens > 0)
					{
						get1();
						lens = lens - 1;
					}
					addevent(tracki, curtick, sig1 << 24 | sig0 << 16 | meta << 8 | stat, 0, 0);
				}
				else if (meta == 0x2f)
					len = 0; else
					while (lens > 0)
					{
						get1();
						lens = lens - 1;
					}
				break;
			}
			}
			if (hex0 < 0xf)
			{
				msg = data1 << 16 | data0 << 8 | stat;
				addevent(tracki, curtick, msg, 0, 0);
			}
		}
		track1[tracki] = eventi;
		tracki = tracki + 1;
	}
	closefile();
}
void preparemidi()
{
	trackn = tracki;
	if (tpq > 0)
	{
		curtick = 0;
		do
		{
			addevent(trackn, curtick, 0x5aff, 0, 0);
			curtick = curtick + tpq;
		} while (!(curtick > finaltick));
		track1[trackn] = eventi;
		trackn = trackn + 1;
	}
	eventn = eventi;
	track0[0] = 0;
	for (tracki = 1; tracki <= long(trackn - 1); tracki++)
		track0[tracki] = track1[tracki - 1];
	eventj = 0;
	while ((eventj < eventn))
	{
		curtick = 0xffffffff;
		for (tracki = 0; tracki <= long(trackn - 1); tracki++)
			if (track0[tracki] < track1[tracki])
				if (event[track0[tracki]].curtick < curtick)
				{
					trackj = tracki;
					curtick = event[track0[tracki]].curtick;
				}
		event0[eventj] = event[track0[trackj]];
		track0[trackj] = track0[trackj] + 1;
		eventj = eventj + 1;
	}
	tempo = 5000000;
	finaltime = 0;
	curtick = 0;
	sig0 = 1;
	sig = 1;
	chordtmp = -1;
	for (eventi = 0; eventi <= long(eventn - 1); eventi++)
	{
		if ((event0[eventi].msg & 0xffff) == 0x58ff)
		{
			sig0 = event0[eventi].msg >> 16 & 0xff;
			sig1 = event0[eventi].msg >> 24 & 0xff;
			sig = 1;
			while (sig1 > 0)
			{
				sig = sig * 2;
				sig1 = sig1 - 1;
			}
		}
		while (curtick < event0[eventi].curtick)
			curtick = curtick + (long)((double)tpq * (double)sig0 * 4.0 / (double)sig);
		if (eventi == 0) tick = event0[eventi].curtick; else tick = event0[eventi].curtick - event0[eventi - 1].curtick;
		if (eventi == 0) event0[eventi].ticktime = 0; else event0[eventi].ticktime = event0[eventi - 1].ticktime;
		if (tpq > 0) event0[eventi].ticktime = event0[eventi].ticktime + (double)tick / (double)tpq * ((double)tempo / (double)1000000);
		if (fps > 0) event0[eventi].ticktime = event0[eventi].ticktime + (double)tick / (double)fps;
		if (event0[eventi].tempo > 0) tempo = event0[eventi].tempo;
		if (event0[eventi].msg == 0x5aff) event0[eventi].tempo = tempo;
		if (event0[eventi].msg == 0x5aff) if (curtick == event0[eventi].curtick) event0[eventi].msg = 0x5bff;
		if ((event0[eventi].msg & 0xffff) == 0x59ff) chord_ = (unsigned char)event0[eventi].chord;
		else event0[eventi].chord = chord_;
		if ((event0[eventi].msg & 0xffff) == 0x59ff) if (chordtmp == -1) chordtmp = chord_;
		finaltime = max(finaltime, event0[eventi].ticktime + 1);
	}
}
HMIDIOUT midiout;
double firsttime;
bool pauseb;
double pausetime;
double spd0, spd1;
const unsigned long volamax = 16;
const double vola[volamax] = {
	0, 0.01, 0.02, 0.03, 0.04, 0.06, 0.08, 0.12, 0.16, 0.25, 0.35, 0.5, 0.7, 1, 1.41, 2
}
;
unsigned char volchana[0xf + 1];
unsigned char volchani;
void initmidichanvol(unsigned char volchan)
{
	for (volchani = 0; volchani <= 0xf; volchani++) volchana[volchani] = volchan;
}
void setmidichanvol(unsigned char chan, unsigned char volchan)
{
	volchana[chan] = volchan;
	midiOutShortMsg(midiout, 0x000007b0 | chan | min(0x7f, long(trunc(volchan * vola[voli - 1]))) << 16);
}
void setmidivol(char v)
{
	voli = v;
	for (volchani = 0; volchani <= 0xf; volchani++) setmidichanvol(volchani, volchana[volchani]);
}
double getmiditime()
{
	double getmiditime_r;
	if (pauseb) getmiditime_r = pausetime; else getmiditime_r = gettimer() * spd0 - firsttime;
	return getmiditime_r;
}
void setmiditime(double settime)
{
	unsigned char chani;
	unsigned long tempo0;
	if (settime <= 0) midiOutReset(midiout);
	for (chani = 0; chani <= 0xf; chani++) midiOutShortMsg(midiout, 0x00007bb0 | chani);
	firsttime = gettimer() * spd0 - settime;
	eventj = eventn;
	eventk = long(eventn - 1);
	while (eventk >= 0)
	{
		if (event0[eventk].ticktime >= settime) eventj = eventk;
		eventk = eventk - 1;
	}
	for (eventk = eventi; long(eventk) <= min(long(eventj), long(eventn - 1)); eventk++)
		if ((event0[eventk].msg & 0xf0) != 0x90)
		{
			if ((event0[eventk].msg & 0xf0) >> 4 < 0xf) if (((event0[eventk].msg & 0xf0) >> 4 == 0xb) && ((event0[eventk].msg >> 8 & 0xff) == 0x07)) setmidichanvol(event0[eventk].msg & 0xf, event0[eventk].msg >> 16 & 0xff); else midiOutShortMsg(midiout, event0[eventk].msg);
		}
	tempo0 = 500000;
	for (eventk = long(eventn - 1); eventk >= 1; eventk--)
		if (((event0[eventk].msg & 0xffff) == 0x51ff)) tempo0 = event0[eventk].tempo;
	for (eventk = 1; long(eventk) <= min(long(eventj), long(eventn - 1)); eventk++)
		if (((event0[eventk].msg & 0xffff) == 0x51ff)) tempo0 = event0[eventk].tempo;
	tempo = tempo0;
	eventi = eventj;
	if (pauseb) pausetime = settime;
	if (voli > 0) setmidivol(char(voli));
	if (settime <= 0) if (chordtmp != -1) chord_ = chordtmp;
}
void pausemidi()
{
	if (pauseb == false) pausetime = getmiditime();
	setmiditime(pausetime);
	pauseb = !(pauseb);
}
double note0[0x80];
double note1[0x80];
unsigned long notec[0x80];
unsigned char notech[0x80];
struct tnotemap
{
	unsigned char note;
	double note0;
	double note1;
	unsigned long notec;
	unsigned char chord;
};
const unsigned long maxnotemap = maxevent;
tnotemap notemap[maxnotemap + 1];
long notemapi;
unsigned long notemapn;
const unsigned long black0 = 0x0f0f0f;
const unsigned long black1 = 0x0f0f0f;
const unsigned long gray0 = 0x1f1f1f;
const unsigned long gray1 = 0x3f3f3f;
const unsigned long gray2 = 0x9f9f9f;
const unsigned long kbd0n = 21;
const unsigned long kbd1n = 21 + 87;
unsigned char kbd0 = kbd0n;
unsigned char kbd1 = kbd1n;
void addnotemap(unsigned char notei)
{
	notemap[notemapi].note = notei;
	notemap[notemapi].note0 = note0[notei];
	notemap[notemapi].note1 = note1[notei];
	notemap[notemapi].notec = notec[notei];
	notemap[notemapi].chord = notech[notei];
	chancn[notec[notei]] = chancn[notec[notei]] + 1;
	notemapi = notemapi + 1;
}
void createnotemap()
{
	unsigned char notei;
	long ei;
	for (chani = 0; chani <= long(maxchan - 1); chani++) chancn[chani] = 0;
	for (chani = 0; chani <= long(maxchan - 1); chani++) chancc[chani] = chani;
	for (chani = 0; chani <= long(maxchan - 1); chani++) chancw[chani] = hsn2rgb(chanc0[chani % 12] | 0x9fff00);
	for (chani = 0; chani <= long(maxchan - 1); chani++) chancb[chani] = mixcolor0(chancw[chani], black0, 3.0 / 4.0);
	notemapi = 0;
	for (notei = 0; notei <= 0x7f; notei++)
	{
		note0[notei] = -1;
		note1[notei] = 0;
	}
	kbd0 = kbd0n;
	kbd1 = kbd1n;
	for (ei = 0; ei <= long(eventn - 1); ei++)
		if ((event0[ei].msg & 0xf) != 0x9)
		{
			if ((event0[ei].msg & 0xf0) == 0x90)
				if ((event0[ei].msg >> 16 & 0x00ff) == 0) event0[ei].msg = event0[ei].msg & 0xffffff8f;
			if ((event0[ei].msg & 0xf0) == 0x90)
			{
				notech[notei] = (unsigned char)event0[ei].chord;
				notei = event0[ei].msg >> 8 & 0x7f;
				kbd0 = min(notei, kbd0);
				kbd1 = max(notei, kbd1);
				notec[notei] = event0[ei].track | ((event0[ei].msg & 0xf) << 8);
				if (note0[notei] >= note1[notei])
				{
					note1[notei] = event0[ei].ticktime;
					addnotemap(notei);
				}
				note0[notei] = event0[ei].ticktime;
			}
			if ((event0[ei].msg & 0xf0) == 0x80)
			{
				notech[notei] = (unsigned char)event0[ei].chord;
				notei = event0[ei].msg >> 8 & 0x7f;
				note1[notei] = event0[ei].ticktime;
				addnotemap(notei);
			}
		}
	for (notei = 0; notei <= 0x7f; notei++)
		if (note0[notei] > note1[notei])
		{
			note1[notei] = finaltime;
			addnotemap(notei);
		}
	notemapn = notemapi;
	for (chani = 0; chani <= long(maxchan - 1); chani++)
		for (chanj = 0; chanj <= long(maxchan - 1); chanj++)
			if (chancn[chani] > chancn[chanj])
			{
				swapc(chancn[chani], chancn[chanj]);
				swapc(chancc[chani], chancc[chanj]);
			}
	for (chani = 0; chani <= long(maxchan - 1); chani++)
		for (chanj = 0; chanj <= long(maxchan - 1); chanj++)
			if (chancc[chani] < chancc[chanj])
			{
				swapc(chancn[chani], chancn[chanj]);
				swapc(chancc[chani], chancc[chanj]);
				swapc(chancw[chani], chancw[chanj]);
				swapc(chancb[chani], chancb[chanj]);
			}
}
unsigned long w;
unsigned long h;
unsigned long fw, fh;
double frametime;
double printtime;
const unsigned long mult0 = 600;
unsigned long mult;
bool k_shift0;
bool k_ctrl0;
double k_pos;
const double klen0 = 1.15;
const double klen1 = 0.65;
double kbd[12];
const unsigned char keyblack[12] = { 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0 };
const char* keychord[2][12] = { {
		"1", " ", "2", " ", "3", "4", " ", "5", " ", "6", " ", "7"
	},{
		"C", "d", "D", "e", "E", "F", "g", "G", "A", "A", "b", "B"
	}
};
double kleny0 = 6.5;
double kleny1 = 4.5;
unsigned long kbdc[0x80];
unsigned long kbdcc[12];
unsigned char kbdci;
unsigned char kbdi, kbdn;
const double fhr = 0.7;
void initkbdpos()
{
	kbd[0] = 0;
	kbd[1] = 1 + (klen0 - 3 * klen1) / 2;
	kbd[2] = 1;
	kbd[3] = 2 - (klen0 - klen1) / 2;
	kbd[4] = 2;
	kbd[5] = 3;
	kbd[6] = 5 - (2 * klen0 + klen1) / 2;
	kbd[7] = 4;
	kbd[8] = 5 - (klen1) / 2;
	kbd[9] = 5;
	kbd[10] = 5 - (-2 * klen0 + klen1) / 2;
	kbd[11] = 6;
}
void initkbdcolor()
{
	for (kbdi = 0; kbdi <= 11; kbdi++) kbdcc[kbdi] = hsn2rgb(0x9fff00 | long(round((kbdi * 5 + 7) % 12 * 0xff / 12)));
}
void _bar(long x, long y, long w, long h, unsigned long cfg, unsigned long cbg)
{
	bar(x, getheight() - y - h, w, h, cfg, cbg);
}
void _line(long x, long y, long w, long h, unsigned long c)
{
	line(x, getheight() - y - h, w, h, c);
}
void _drawtextxy(const char* s, long x, long y, unsigned long c)
{
	drawtextxy(s, x, getheight() - y - fh - 2, c);
}
const char* getkeychord(unsigned char k, unsigned long chord)
{
	const char* getkeychord_r;
	getkeychord_r = keychord[kchb][(k - chordb[chord] + 12) % 12];
	return getkeychord_r;
}
unsigned char getkeychord0(unsigned char k, unsigned long chord)
{
	unsigned char getkeychord0_r;
	getkeychord0_r = (k - chordb[chord] + 12) % 12;
	return getkeychord0_r;
}
unsigned long getkeychordc(unsigned char k, unsigned long chord)
{
	unsigned long getkeychordc_r;
	getkeychordc_r = kbdcc[getkeychord0(k, chord)];
	return getkeychordc_r;
}
const char* getkeychord(unsigned char k)
{
	const char* getkeychord_r;
	getkeychord_r = getkeychord(k, chord_);
	return getkeychord_r;
}
unsigned char iskeynoteblack(unsigned char k)
{
	unsigned char iskeynoteblack_r;
	iskeynoteblack_r = keyblack[k % 12];
	return iskeynoteblack_r;
}
double getkeynote(unsigned char k)
{
	double getkeynote_r;
	getkeynote_r = 7 * (k / 12) + kbd[k % 12];
	return getkeynote_r;
}
double getkeynote0(unsigned char k)
{
	double getkeynote0_r;
	if ((iskeynoteblack(k) == 0)) getkeynote0_r = getkeynote(k) + 1; else getkeynote0_r = getkeynote(k) + klen1;
	return getkeynote0_r;
}
long getkeynotex(unsigned char k)
{
	long getkeynotex_r;
	getkeynotex_r = (long)round((getkeynote(k) - getkeynote(kbd0)) * getwidth() / (getkeynote0(kbd1) - getkeynote(kbd0)));
	return getkeynotex_r;
}
long getkeynotex0(unsigned char k)
{
	long getkeynotex0_r;
	getkeynotex0_r = (long)round((getkeynote0(k) - getkeynote(kbd0)) *getwidth() / (getkeynote0(kbd1) - getkeynote(kbd0)));
	return getkeynotex0_r;
}
unsigned long getkeynotew0()
{
	unsigned long getkeynotew0_r;
	getkeynotew0_r = (long)round(getwidth() / (getkeynote(kbd1 + 1) - getkeynote(kbd0)));
	return getkeynotew0_r;
}
unsigned long getkeynotew1()
{
	unsigned long getkeynotew1_r;
	getkeynotew1_r = (long)round(getwidth() / (getkeynote(kbd1 + 1) - getkeynote(kbd0)) *klen1);
	return getkeynotew1_r;
}
unsigned long getkeynotew(unsigned char k)
{
	unsigned long getkeynotew_r;
	if ((iskeynoteblack(k) == 1)) getkeynotew_r = getkeynotew1(); else getkeynotew_r = getkeynotew0();
	return getkeynotew_r;
}
unsigned long getkeynotec(unsigned char k, unsigned short chan)
{
	unsigned long getkeynotec_r;
	if ((iskeynoteblack(k) == 1)) getkeynotec_r = chancb[chan]; else getkeynotec_r = chancw[chan];
	return getkeynotec_r;
}
void setdrawfont(double sz)
{
	fw = max(1, (long)round((getkeynotew1() - 2) * sz));
	fh = max(1, (long)round(fw * 2.2));
	setfontsize(fw, fh);
	setfont();
}
void setdrawfont()
{
	setdrawfont(1);
}
void getdrawtime()
{
	printtime = getmiditime();
}
void drawmessureline(double t, unsigned long ms, unsigned long tempo, unsigned long c)
{
	long w0, y;
	w0 = getkeynotew0();
	y = (long)trunc((t - printtime) * mult * getwidth() / mult0) + (long)round(w0 * kleny0);
	if ((y >= (long)round(w0 * kleny0)) && (y < (long)getheight())) _line(0, y, getwidth(), 0, c);
	if ((y + (long)fh >= (long)round(w0 * kleny0)) && (y < (long)getheight()))
	{
		_drawtextxy(i2s(ms), 0, y, c);
		_drawtextxy(r2s(60000000 / tempo * spd0), getwidth() - fw * length(r2s(60000000 / tempo * spd0)), y, c);
	}
}
void drawchordline(double t, unsigned char ch, unsigned long c)
{
	long w0, y;
	w0 = getkeynotew0();
	y = (long)trunc((t - printtime) * mult * getwidth() / mult0) + (long)round(w0 * kleny0);
	if ((y >= (long)round(w0 * kleny0)) && (y < (long)getheight())) _line(0, y, getwidth(), 0, c);
	if ((y + (long)fh >= (long)round(w0 * kleny0)) && (y < (long)getheight())) _drawtextxy(chords[ch], 0, y - fh - 4, c);
}
void drawmessurelineall()
{
	long ei;
	EnterCriticalSection(&cs2);
	for (ei = 1; ei <= long(eventn - 1); ei++)
	{
		if (event0[ei].msg == 0x5aff) drawmessureline(event0[ei].ticktime, event0[ei].curtick / tpq, event0[ei].tempo, gray0);
		if (event0[ei].msg == 0x5bff) drawmessureline(event0[ei].ticktime, event0[ei].curtick / tpq, event0[ei].tempo, gray1);
	}
	for (ei = 1; ei <= long(eventn - 1); ei++) if (event0[ei].msg == 0x59ff)
		drawchordline(event0[ei].ticktime, (unsigned char)event0[ei].chord, gray2);
	LeaveCriticalSection(&cs2);
}
void drawnoteline()
{
	unsigned char kbd;
	unsigned long x;
	for (kbd = kbd0; kbd <= kbd1; kbd++)
	{
		x = getkeynotex(kbd);
		if ((kbd) % 12 == 0) _line(x, 0, 0, getheight(), gray1);
		if ((kbd) % 12 == 5) _line(x, 0, 0, getheight(), gray0);
	}
}
void drawkeyboard()
{
	unsigned char kbd;
	long x, w, w0;
	unsigned char kbd0i, kbd1i;
	kbd0i = kbd0;
	kbd1i = kbd1;
	if (iskeynoteblack(kbd0i) == 1) kbd0i = max(0x00, kbd0i - 1);
	if (iskeynoteblack(kbd1i) == 1) kbd1i = min(0x7f, kbd1i + 1);
	for (kbd = kbd0i; kbd <= kbd1i; kbd++)
	{
		x = getkeynotex(kbd);
		w = getkeynotex0(kbd) - getkeynotex(kbd);
		w0 = getkeynotew0();
		if (iskeynoteblack(kbd) == 0)
		{
			_bar(x, 0, w, (long)round(w0 * kleny0), black, kbdc[kbd]);
			if (kbdc[kbd] == white)
				_drawtextxy(getkeychord(kbd), x + (w - fw) / 2, 4, mixcolor0(white, black, 1.0 / 2.0));
			else
				_drawtextxy(getkeychord(kbd), x + (w - fw) / 2, 0, black);
		}
	}
	for (kbd = kbd0i; kbd <= kbd1i; kbd++)
	{
		x = getkeynotex(kbd);
		w = getkeynotex0(kbd) - getkeynotex(kbd);
		w0 = getkeynotew0();
		if (iskeynoteblack(kbd) == 1)
		{
			_bar(x, (long)round(w0 * (kleny0 - kleny1)), w, (long)round(w0 * kleny1), black, kbdc[kbd]);
			if (kbdc[kbd] == black)
				_drawtextxy(getkeychord(kbd), x + (w - fw) / 2, (long)round(w0 * (kleny0 - kleny1)) + 4, mixcolor0(black, white, 1.0 / 2.0));
			else
				_drawtextxy(getkeychord(kbd), x + (w - fw) / 2, (long)round(w0 * (kleny0 - kleny1)), black);
		}
	}
}
void drawnote(unsigned long notemapi)
{
	long x, y, w, w0, h;
	x = getkeynotex(notemap[notemapi].note);
	w = getkeynotex0(notemap[notemapi].note) - getkeynotex(notemap[notemapi].note);
	w0 = getkeynotew0();
	y = (long)trunc((notemap[notemapi].note0 - printtime) * mult * getwidth() / mult0) + (long)round(w0 * kleny0);
	h = (long)trunc((notemap[notemapi].note1 - notemap[notemapi].note0) * mult * getwidth() / mult0);
	h = max(3, h);
	if ((y < (long)round(w0 * kleny0)) && ((y + h) > (long)round(w0 * kleny0)))
	{
		if (kbdcb == 1)
			kbdc[notemap[notemapi].note] = getkeychordc(notemap[notemapi].note, notemap[notemapi].chord);
		else
			kbdc[notemap[notemapi].note] = getkeynotec(notemap[notemapi].note, (unsigned short)notemap[notemapi].notec);
	}
	h = max((long)round(fh * fhr), h);
	if ((y < (long)getheight()) && (y + h > (long)round(w0 * kleny0)))
	{
		if (kbdcb == 1)
			_bar(x, y, w, h, black0, getkeychordc(notemap[notemapi].note, notemap[notemapi].chord));
		else
			_bar(x, y, w, h, black0, getkeynotec(notemap[notemapi].note, (unsigned short)notemap[notemapi].notec));
		_drawtextxy(getkeychord(notemap[notemapi].note, notemap[notemapi].chord), x + (w - fw) / 2, min(y + (long)round((h - double(fh)) * fhr), y), black);
	}
}
void drawnoteall()
{
	EnterCriticalSection(&cs1);
	for (kbdci = 0x00; kbdci <= 0x7f; kbdci++) if (iskeynoteblack(kbdci) == 1) kbdc[kbdci] = black; else kbdc[kbdci] = white;
	for (notemapi = 0; notemapi <= long(notemapn - 1); notemapi++) if ((iskeynoteblack(notemap[notemapi].note) == 0)) drawnote(notemapi);
	for (notemapi = 0; notemapi <= long(notemapn - 1); notemapi++) if ((iskeynoteblack(notemap[notemapi].note) == 1)) drawnote(notemapi);
	LeaveCriticalSection(&cs1);
}
void drawtime()
{
	if (finaltime > 0) _line((long)trunc(getmiditime() / finaltime * getwidth()), 0, 0, getheight(), white);
	drawtextxy((mystring)t2s(getmiditime()) + (mystring)"/" + (mystring)t2s(finaltime), 0, 0, white);
}
void drawchord()
{
	if ((finaltime > 0)) _drawtextxy(chords[chord_], 0, (long)round(getkeynotew0() * kleny0), white);
}
void drawloop()
{
	_drawtextxy(&loops[loop], getwidth() - fw, (long)round(getkeynotew0() * kleny0), white);
}
void drawbpm()
{
	double bpm;
	const char* spds = "";
	bpm = 60000000 / tempo * spd0;
	if ((bpm > 0))
	{
		if (round(spd0 * 100) != 100) spds = (mystring)"(" + i2s(long(round(spd0 * 100))) + "%)";
		setdrawfont(1.5);
		drawtextxy((mystring)r2s(bpm) + " BPM", (getwidth() - fw * length((mystring)r2s(bpm) + "  BPM")) / 2, 0, white);
		setdrawfont();
		drawtextxy(spds, (getwidth() - fw * length(spds)) / 2, (long)round(fh * 1.5), white);
	}
}
void drawfps()
{
	const char* fpss = "";
	fpss = i2s(getfps()) + "/" + i2s(framerate);
	if (abs((long)(getfpsr() - framerate)) > 1) drawtextxy(fpss, getwidth() - fw * length(fpss), 0, white);
}
void drawload()
{
	if (flen > 0) if (fpos < flen) _line(0, getheight() / 2, (long)round(fpos / flen * getwidth()), 0, white);
}
void drawall()
{
	setdrawfont();
	clear();
	getdrawtime();
	drawnoteline();
	drawmessurelineall();
	drawnoteall();
	drawkeyboard();
	drawtime();
	drawchord();
	drawbpm();
	drawloop();
	drawfps();
	drawload();
	freshwin();
}
void drawtitle()
{
	mystring stitle("");
	if ((finaltime > 0)) stitle = stitle + "[" + i2s(max(0, (long)trunc(getmiditime() * 100 / finaltime))) + "%]";
	stitle = stitle + PathFindFileName(fnames);
	if ((finaltime > 0)) stitle = stitle + "(" + chords[chord_] + ")";
	if ((finaltime > 0)) stitle = stitle + "[" + i2s(find_current) + "/" + i2s(find_count) + "]";
	if (spd0 > 0) if (round(spd0 * 100) != 100) stitle = stitle + "(" + i2s((unsigned long)(round(spd0 * 100))) + "%)";
	if (mult > 0) if (mult != 100) stitle = stitle + "<" + i2s(mult) + "%>";
	if (voli > 0) if (round(vola[voli - 1] * 100) != 100) stitle = stitle + "[" + i2s((unsigned long)(round(vola[voli - 1] * 100))) + "%]";
	settitle(stitle);
}
void drawproc()
{
	do
	{
		if (gettimer() > frametime + 1 / framerate)
		{
			while (gettimer() > frametime + 1 / framerate) frametime = double(frametime) + 1.0 / double(framerate);
			if (!(IsIconic((HWND)gethwnd()))) drawall();
			drawtitle();
		}
		else
			delay(1);
	} while (!(!(iswin())));
}
void resetmidi()
{
	mult = 100;
	spd0 = 1;
	eventi = 0;
	pauseb = false;
	initmidichanvol(0x7f);
	setmiditime(-1);
}
void resetmidisoft()
{
	double tmptime;
	tmptime = getmiditime();
	initmidichanvol(0x7f);
	setmiditime(-1);
	setmiditime(tmptime);
}
void resetmidihard()
{
	midiOutClose(midiout);
	midiOutOpen(&midiout, 0, 0, 0, 0);
	resetmidisoft();
}
void playmidi(const char* fname)
{
	if ((fileexists(fname)))
	{
		find_file(fname);
		fnames = fname;
		loadmidi(fname);
		EnterCriticalSection(&cs2);
		preparemidi();
		LeaveCriticalSection(&cs2);
		EnterCriticalSection(&cs1);
		createnotemap();
		LeaveCriticalSection(&cs1);
		resetmidi();
		savefile();
	}
}
void helpproc()
{
	if (fileexists(mystring(fdir) + "\\midiplayer.txt"))
		WinExec(mystring("notepad.exe ") + fdir + "midiplayer.txt", SW_SHOW);
	else
		msgbox(mystring("missing help file: ") + fdir + "midiplayer.txt", "help file!found!");
}
void doact()
{
	if (ismsg(WM_USER))
	{
		char c[2];
		if ((getmsg(getnextmsg()) & 0xFFFFFFFF) == 0)
		{
			c[0] = (char)((getmsg(getnextmsg()) >> 32) % 0x100);
			c[1] = (char)0;
			para = para + &c[0];
		}
		if ((getmsg(getnextmsg()) & 0xFFFFFFFF) == 1)
			para = "";
		if ((getmsg(getnextmsg()) & 0xFFFFFFFF) == 2)
			playmidi(para);
	}
	if (isdropfile())
		playmidi(getdropfile());
	if (iskey())
	{
		if (iskey(k_f1)) newthread((void*)&helpproc);
		if (iskey(k_f2)) resetmidisoft();
		if (iskey(k_f3)) resetmidihard();
		if (iskey(k_f5)) framerate = max(10, framerate - ((framerate - 1) / 60 + 1));
		if (iskey(k_f6)) framerate = min(360, framerate + (framerate / 60 + 1));
		if (iskey(k_f7)) mult = min(400, mult + 10);
		if (iskey(k_f8)) mult = max(10, mult - 10);
		if (iskey(k_f9)) kbdcb = 1 - kbdcb;
		if (iskey(k_f11)) kchb = 1 - kchb;
		if (iskey(k_f12)) loop = (loop + 1) % 3;
		k_shift0 = GetKeyState(VK_SHIFT) < 0;
		k_ctrl0 = GetKeyState(VK_CONTROL) < 0;
		if (iskey(k_right) || iskey(k_left))
		{
			k_pos = 1;
			if (k_ctrl0) k_pos = 5;
			if (k_shift0) k_pos = 30;
		}
		if (iskey(k_left)) setmiditime(max(-1, getmiditime() - k_pos));
		if (iskey(k_right)) setmiditime(min(finaltime, getmiditime() + k_pos));
		if (iskey(k_space)) pausemidi();
		if (iskey(k_add) || iskey(k_sub))
		{
			k_pos = 0.1;
			if (k_ctrl0) k_pos = 0.03;
			if (k_shift0) k_pos = 0.01;
		}
		if (iskey(k_add) || iskey(187))
		{
			spd1 = min(4.00, spd0 + k_pos);
		}
		if (iskey(k_sub) || iskey(189))
		{
			spd1 = max(0.10, spd0 - k_pos);
		}
		if (iskey(k_add) || iskey(k_sub) || iskey(187) || iskey(189))
		{
			firsttime = firsttime + gettimer() * (spd1 - spd0);
			spd0 = spd1;
		}
		if (iskey(k_up)) setmidivol((char)min(volamax, voli + 1));
		if (iskey(k_down)) setmidivol((char)max(1, voli - 1));
		if (iskey(k_pgup)) playmidi(get_file(find_current - 1));
		if (iskey(k_pgdn)) playmidi(get_file(find_current + 1));
		if (iskey(k_home)) playmidi(get_file(1));
		if (iskey(k_end)) playmidi(get_file(find_count));
		if (iskey(k_esc)) closewin();
	}
	if (getmouseposy() < getheight() - round(getkeynotew0() * kleny0))
	{
		if (ismouseleft() || (ismousemove() && (getmsg(getnextmsg()) >> 32) == 1) && (finaltime > 0))
			setmiditime(double(getmouseposx()) / double(getwidth()) * double(finaltime));
	}
	else
	{
		if (ismsg(WM_LBUTTONDOWN))
		{
			for (kbdi = 0x00; kbdi <= 0x7f; kbdi++) if ((iskeynoteblack(kbdi) == 0)) if ((getmouseposx() > getkeynotex(kbdi))) kbdn = kbdi;
			for (kbdi = 0x00; kbdi <= 0x7f; kbdi++) if ((iskeynoteblack(kbdi) == 1)) if (getmouseposy() < getheight() - round(getkeynotew0() * (kleny0 - kleny1)))
				if ((getmouseposx() > getkeynotex(kbdi)) && (getmouseposx() < getkeynotex0(kbdi))) kbdn = kbdi;
			midiOutShortMsg(midiout, 0x7f0090 | kbdn << 8);
		}
		if (ismsg(WM_LBUTTONUP)) midiOutShortMsg(midiout, 0x000080 | kbdn << 8);
	}
	if (ismouseright()) pausemidi();
	if (ismousewheel())
	{
		if ((getmsg(getnextmsg()) >> 32) > 0) setmidivol((char)min(volamax, voli + 1));
		if ((getmsg(getnextmsg()) >> 32) < 0) setmidivol((char)max(1, voli - 1));
	}
}
void commandline(char* argv[])
{
	hwm = FindWindow("DisplayClass", NULL);
	fdir = argv[0];
	char sdir[256];
#ifdef __STDC_LIB_EXT1__
	strcpy_s(&sdir[0], 0x100, fdir.s);
#else
	strcpy(&sdir[0], fdir.s);
#endif
	PathRemoveFileSpec(sdir);
	fdir = (mystring)sdir + "\\";
	if (argv[1] != NULL)	para = argv[1];
	if (hwm != 0)
		if (para.len != 0)
		{
			SendMessage(hwm, WM_USER, 0, 1);
			for (parai = 0; parai < length(para); parai++)
			{
				SendMessage(hwm, WM_USER, (unsigned long)(char(para.s[parai])), 0);
			}
			SendMessage(hwm, WM_USER, 0, 2);
			exit(0);
		}
}
int main(int argc, char* argv[])
{
	InitializeCriticalSection(&cs1);
	InitializeCriticalSection(&cs2);
	openkey();
	commandline(argv);
	w = 2 * getscrwidth() / 3;
	h = 2 * getscrheight() / 3;
	createwin(w, h, black1);
	HANDLE icon;
	icon = LoadImage(0, "midiplayer.ico", IMAGE_ICON, 0, 0, LR_LOADFROMFILE);
	SendMessage((HWND)gethwnd(), WM_SETICON, ICON_SMALL, long(icon));
	setfontname("consolas");
	initkbdpos();
	initkbdcolor();
	newthread((void*)&drawproc);
	setmidivol(volamax - 2);
	resetmidihard();
	loadfile();
	do
	{
		if (isnextmsg())doact(); else delay(1);
		if (getmiditime() > finaltime)
			switch (loop)
			{
			case 0:
			{
				pausemidi();
				setmiditime(-1);
				break;
			}
			case 1:
			{
				setmiditime(-1);
				break;
			}
			case 2:
			{
				playmidi(get_file(find_current + 1));
				break;
			}
			}
		if (eventi < (long)eventn)
		{
			while (getmiditime() > event0[eventi].ticktime)
			{
				if ((event0[eventi].msg & 0xf0) >> 4 < 0xf)
					if (((event0[eventi].msg & 0xf0) >> 4 == 0xb) & ((event0[eventi].msg >> 8 & 0xff) == 0x07))
						setmidichanvol(event0[eventi].msg & 0xf, event0[eventi].msg >> 16 & 0xff);
					else
						midiOutShortMsg(midiout, event0[eventi].msg); else if (((event0[eventi].msg & 0xffff) == 0x51ff)) tempo = event0[eventi].tempo;
				chord_ = (unsigned char)event0[eventi].chord;
				eventi = eventi + 1;
				if (eventi >= (long)eventn) break;
			}
		}
	} while (!(!(iswin())));
	midiOutClose(midiout);
	savefile();
	closekey();
	return 0;
}