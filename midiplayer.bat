del *.zip
del *.ppu
del *.o
del *.or
del *.a
del *.exe
del midiplayer.exe
del midiplayer.zip
windres -i midiplayer.rc -o midiplayer.res
fpc -WG midiplayer.pas -omidiplayer32.exe -Os
ppcrossx64 -WG midiplayer.pas -omidiplayer64.exe -Os
start midiplayer64.exe
if not exist midiplayer64.exe pause
if not exist midiplayer64.exe exit
mkdir midiplayer
copy midiplayer32.exe midiplayer\midiplayer32.exe
copy midiplayer64.exe midiplayer\midiplayer64.exe
copy midiplayer.ico midiplayer\midiplayer.ico
copy midiplayer.txt midiplayer\midiplayer.txt
copy FORCE_MEMORY midiplayer\FORCE_MEMORY
copy LICENSE midiplayer\LICENSE
copy README.md midiplayer\README.md
::copy midiplayer.reg midiplayer\midiplayer.reg
xcopy ..\sample\* sample\* /s /e /y /r
xcopy ..\sample2\* sample2\* /s /e /y /r
xcopy ..\sample3\* sample3\* /s /e /y /r
xcopy sample\* midiplayer\sample\* /s /e /y /r
::xcopy sample2\* midiplayer\sample2\* /s /e /y /r
::xcopy sample3\* midiplayer\sample3\* /s /e /y /r
::mkdir midiplayer\source
::copy midiplayer.pas midiplayer\source\midiplayer.pas
::copy fevent.inc midiplayer\source\fevent.inc
::copy fevent0.inc midiplayer\source\fevent0.inc
::copy fnote.inc midiplayer\source\fnote.inc
::copy display.pp midiplayer\source\display.pp
::copy mmsystem.pp midiplayer\source\mmsystem.pp
::copy midiplayer.rc midiplayer\source\midiplayer.rc
::copy midiplayer.bat midiplayer\source\midiplayer.bat
::copy midiplayer.ico midiplayer\source\midiplayer.ico
::copy midiplayer.png midiplayer\source\midiplayer.png
::copy midiplayer.txt midiplayer\source\midiplayer.txt
::copy midiplayer.reg midiplayer\source\midiplayer.reg
zip -q -r midiplayer3.zip midiplayer
rmdir midiplayer /s /q
del *.obj
del *.ppu
del *.o
del *.or
del *.a