del *.ppu
del *.o
del *.or
del *.a
del midiplayer.exe
del midiplayer.zip
windres -i midiplayer.rc -o midiplayer.res
fpc -WG midiplayer.pas -omidiplayer.exe -Os
start midiplayer.exe
if not exist midiplayer.exe pause
if not exist midiplayer.exe exit
mkdir midiplayer
copy midiplayer.exe midiplayer\midiplayer.exe
copy midiplayer.ico midiplayer\midiplayer.ico
copy midiplayer.txt midiplayer\midiplayer.txt
xcopy sample\* midiplayer\sample\* /s /e /y /r
mkdir midiplayer\source
copy midiplayer.pas midiplayer\source\midiplayer.pas
copy display.pp midiplayer\source\display.pp
copy mmsystem.pp midiplayer\source\mmsystem.pp
copy midiplayer.rc midiplayer\source\midiplayer.rc
copy midiplayer.bat midiplayer\source\midiplayer.bat
copy midiplayer.ico midiplayer\source\midiplayer.ico
copy midiplayer.png midiplayer\source\midiplayer.png
copy midiplayer.txt midiplayer\source\midiplayer.txt
windres -i midiplayer.rc -o midiplayer_c\midiplayer\midiplayer.o
g++ -o midiplayer\midiplayer_c.exe midiplayer_c\midiplayer\midiplayer.cpp midiplayer_c\midiplayer\WinMM.Lib midiplayer_c\midiplayer\ShLwApi.Lib midiplayer_c\midiplayer\disp.lib midiplayer_c\midiplayer\midiplayer.o -static -mwindows -Os
del midiplayer_c\midiplayer\midiplayer.o
copy midiplayer_c\midiplayer\disp.dll midiplayer\disp.dll
xcopy midiplayer_c\* midiplayer\source\midiplayer_c\* /s /e /y /r
zip -q -r midiplayer.zip midiplayer
rmdir midiplayer /s /q
del *.res
del *.ppu
del *.o
del *.or
del *.a