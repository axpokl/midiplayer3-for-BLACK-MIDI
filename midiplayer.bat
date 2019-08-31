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
fpc midiplayer.pas -omidiplayer32_video.exe -gl -Crtoi -WG -dVideo
ppcrossx64 midiplayer.pas -omidiplayer64.exe -Os -WG
ppcrossx64 midiplayer.pas -omidiplayer64_video.exe -Os -WG -dVideo
ppcrossx64 midiplayer.pas -omidiplayer64_D3D.exe -Os -WG -dD3D
start midiplayer64.exe
if not exist midiplayer64.exe pause
if not exist midiplayer64.exe exit
mkdir midiplayer3
copy midiplayer.ico midiplayer3\midiplayer.ico
copy midiplayer.txt midiplayer3\midiplayer.txt
copy FORCE_MEMORY midiplayer3\FORCE_MEMORY
copy CHANNEL_COLOR midiplayer3\CHANNEL_COLOR
copy RECORD_VIDEO midiplayer3\RECORD_VIDEO
copy README.md midiplayer3\README.md
copy LICENSE midiplayer3\LICENSE
mkdir midiplayer3_video
mkdir midiplayer3_video\32
mkdir midiplayer3_video\64
xcopy midiplayer3\* midiplayer3_video\32 /s /y /r
xcopy midiplayer3\* midiplayer3_video\64 /s /y /r
copy midiplayer32.exe midiplayer3\midiplayer32.exe
copy midiplayer64.exe midiplayer3\midiplayer64.exe
del midiplayer3\RECORD_VIDEO
xcopy sample\* midiplayer3\sample\ /y /r
xcopy sample\* midiplayer3_video\sample\ /y /r
zip -q -r midiplayer3.zip midiplayer3
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
rmdir midiplayer3 /s /q
rmdir midiplayer3_video /s /q
del *.obj
del *.ppu
del *.o
del *.or
del *.a