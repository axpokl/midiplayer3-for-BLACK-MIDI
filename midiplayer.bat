@echo off

cd /d "%~dp0"

echo ------ Clean Up ------

del *.zip
del *.ppu
del *.o
del *.or
del *.a
del *.exe
del *.mkv
del midiplayer.exe
del midiplayer.zip


echo ------ Complie Res ------
windres -i midiplayer.rc -o midiplayer.res

echo ------ Complie 32------
fpc midiplayer.pas -omidiplayer32.exe -gl -Crtoi -WG
fpc midiplayer.pas -omidiplayer32_video.exe -gl -Crtoi -WG -dVideo

echo ------ Complie 64------
ppcrossx64 midiplayer.pas -omidiplayer64.exe -Os -WG
ppcrossx64 midiplayer.pas -omidiplayer64_video.exe -Os -WG -dVideo
::ppcrossx64 midiplayer.pas -omidiplayer64_D3D.exe -Os -WG -dD3D

echo ------ Run ------

start midiplayer64.exe
if not exist midiplayer64.exe pause
if not exist midiplayer64.exe exit

echo ------ Zip ------

mkdir midiplayer3
copy midiplayer.txt midiplayer3\midiplayer.txt
copy README.md midiplayer3\README.md
copy LICENSE midiplayer3\LICENSE
copy midiplayer32.exe midiplayer3\midiplayer32.exe
copy midiplayer64.exe midiplayer3\midiplayer64.exe
xcopy sample\* midiplayer3\sample\ /y /r
zip -q -r midiplayer3.zip midiplayer3
rmdir midiplayer3 /s /q

echo ------ Zip Video ------

mkdir midiplayer3_video
mkdir midiplayer3_video\32
mkdir midiplayer3_video\64
xcopy midiplayer3\* midiplayer3_video\32 /s /y /r
xcopy midiplayer3\* midiplayer3_video\64 /s /y /r
xcopy sample\* midiplayer3_video\sample\ /y /r
copy midiplayer32_video.exe midiplayer3_video\32\midiplayer32_video.exe
copy midiplayer64_video.exe midiplayer3_video\64\midiplayer64_video.exe
xcopy 32\*.dll midiplayer3_video\32\
xcopy 64\*.dll midiplayer3_video\64\
mkdir midiplayer3_video\source
xcopy *.inc midiplayer3_video\source\ /y /r
xcopy *.pas midiplayer3_video\source\ /y /r
xcopy *.pp midiplayer3_video\source\ /y /r
xcopy *.rc midiplayer3_video\source\ /y /r
xcopy *.bat midiplayer3_video\source\ /y /r
xcopy *.ico midiplayer3_video\source\ /y /r
xcopy *.png midiplayer3_video\source\ /y /r
xcopy *.txt midiplayer3_video\source\ /y /r
zip -q -r midiplayer3_video.zip midiplayer3_video
rmdir midiplayer3_video /s /q

echo ------ Clean Backup ------

del *.obj
del *.ppu
del *.o
del *.or
del *.a