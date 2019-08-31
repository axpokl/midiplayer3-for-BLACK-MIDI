cd /d "%~dp0"
del *.zip
del *.ppu
del *.o
del *.or
del *.a
del *.exe
del midiplayer.exe
del midiplayer.zip
windres -i midiplayer.rc -o midiplayer.res
fpc midiplayer.pas -omidiplayer32.exe -gl -Crtoi -WG
ppcrossx64 midiplayer.pas -omidiplayer64.exe -Os -WG
ppcrossx64 midiplayer.pas -omidiplayer64_video.exe -Os -WG -dVideo
ppcrossx64 midiplayer.pas -omidiplayer64_D3D.exe -Os -WG -dD3D
start midiplayer64.exe
if not exist midiplayer64.exe pause
if not exist midiplayer64.exe exit
mkdir midiplayer3
copy midiplayer32.exe midiplayer3\midiplayer32.exe
copy midiplayer64.exe midiplayer3\midiplayer64.exe
copy midiplayer.ico midiplayer3\midiplayer.ico
copy midiplayer.txt midiplayer3\midiplayer.txt
copy FORCE_MEMORY midiplayer3\FORCE_MEMORY
copy CHANNEL_COLOR midiplayer3\CHANNEL_COLOR
copy RECORD_VIDEO midiplayer3\RECORD_VIDEO
copy README.md midiplayer3\README.md
copy LICENSE midiplayer3\LICENSE
xcopy sample\* midiplayer3\sample\ /y /r
mkdir midiplayer3\source
xcopy *.inc midiplayer3\source\ /y /r
xcopy *.pas midiplayer3\source\ /y /r
xcopy *.pp midiplayer3\source\ /y /r
xcopy *.rc midiplayer3\source\ /y /r
xcopy *.bat midiplayer3\source\ /y /r
xcopy *.ico midiplayer3\source\ /y /r
xcopy *.png midiplayer3\source\ /y /r
xcopy *.txt midiplayer3\source\ /y /r
mkdir midiplayer3_video
xcopy midiplayer3\* midiplayer3_video /s /y /r
copy midiplayer64_video.exe midiplayer3_video\midiplayer64_video.exe
xcopy *.dll midiplayer3_video\
zip -q -r midiplayer3.zip midiplayer3
zip -q -r midiplayer3_video.zip midiplayer3_video
rmdir midiplayer3 /s /q
rmdir midiplayer3_video /s /q
del *.obj
del *.ppu
del *.o
del *.or
del *.a