Free Pascal midiplayer3 for Black MIDI by ax_pokl
=============

Release and Source Code
-------------
* Latest version: http://www.axpokl.com/midiplayer3.zip
* Source code: https://github.com/axpokl/midiplayer3-for-BLACK-MIDI

How to Play
-------------
* Drag and drop files into the window to play
* Command line: midiplayer.exe filename.mid [-M]
* Support MIDI(.mid) and RMID(.rmi) file

Mouse Control
-------------
* MLeft                	Seek/Keyboard
* MRight               	Pause
* MWheel               	Volume

Key Control
-------------
* L/R                  	Seek                   	[Default=1s,Ctrl=5s,Shift=30s]
* Space                	Pause
* UP/DN                	Volumn                 	[0%-200%]
* +/-                  	Speed                  	[0%-1600%][Default=10%,Ctrl=3%,Shift=1%]
* [/]                  	Chord
* Shift+[/]            	音高
* PGUP/PGDN            	Prev/Next
* Home/End             	First/Last
* F1                   	Help
* F2                   	Reset File
* Ctrl+F2              	Reset All
* F3                   	Reset Hardware
* Ctrl+F3              	Switch MIDI Device/Synthesizer
* Shift+F3             	Switch Long Message or Stream
* Ctrl+Shift+F3        	On/Off ignore same notes
* F4                   	Reset Bar 
* Ctrl+F4              	Auto Reset Bar
* Shift+F4             	Record Video
* F5/F6                	Set FPS                	[5-480][Default=120]
* Ctrl+F5/F6           	Set short MIDI event buffer
* ShiftF5/F6           	Set minimum MIDI event volume
* Ctrl+Shift+F5/F6     	Set max note buffer
* F7/F8                	Set Bar Size           	[0%-1000%][Default=10%,Ctrl=3%,Shift=1%]
* Ctrl+Shift+F7/F8     	Set keyboard note buffer
* F9                   	Set Bar Color          	[0=Chord,1=Track/Channel(With Black Key),2=Track/Channel]
* F11                  	Set Key Text           	[0=Number,1=Note,2=Blank]
* Ctrl+F11             	Set Information Text
* Shift+F11            	Set Messure/Chord line
* F12                  	Set Loop Mode          	[S=Single,A=All,N=None]

Reset or Uninstall the midiplayer3
-------------
* Run this Command to reset midiplayer3: REG DELETE HKCU\Software\ax_midi_player /f
* You can also delete the registry key HKCU\Software\ax_midi_player by regedit.exe manually
* If you are able to run midiplayer3, you can also press Ctrl+F2 to reset all the settings

Memory instead of File
-------------
* Midiplayer3 needs to load MIDI file information before playing. There are 3 ways to force midiplayer3 use memory
* 1: Set 2nd command line parameter to -M
* 2: Run Command: REG ADD HKCU\Software\ax_midi_player /v fbi /t REG_DWORD /d 1 /f
* 3: Create File "FORCE_MEMORY"
* Otherwise midiplayer3 creates 3 temporary files in %temp% folder to store the information

MIDI software synthesizer and MIDI Long Message
-------------
* It is recommended to use VirtualMIDISynth or OmniMIDI as MIDI output device
* The Synthesizer need to supports midiOutLongMsg Windows API function for long MIDI event as MIDI output
* The Microsoft GS Wavetable Synth or other MIDI output device may not support long MIDI event
* If your output device does not support long MIDI event, please increase the short MIDI event buffer by pressing Ctrl+F6
* You can also reduce the short MIDI event buffer to have better MIDI output performance by pressing Ctrl+F5

Change Channel Color
-------------
* You can change the Track/Channel color by changing the content of file "CHANNEL_COLOR"
* Each line represent a color which has a Hue value from 0-255. E.g. 0=Red, 85=Green and 170=Blue.
* The Track/Channel will sort by it's note count, then use the color in order
* The color will repeat if there is less color in the file defined than Track/Channel number

Record Video
-------------
* You will need to create file "RECORD_VIDEO" and changing the content it before record
* Three lines need to write: the complete path of the output file, frame rate and video quality
* You can record video by pressing Shift+F4, midiplayer3 will reset bar before record


ax_pokl 特制 Free Pascal 黑乐谱MIDI播放器 midiplayer3
=============

最新版本和源代码
-------------
* 最新版本: http://www.axpokl.com/midiplayer3.zip
* 源代码: https://github.com/axpokl/midiplayer3-for-BLACK-MIDI

如何播放
-------------
* 将文件拖拽到窗口内播放
* 命令行播放：midiplayer.exe filename.mid [-M]
* 支持MIDI(.mid)和RMID(.rmi)文件

鼠标控制
-------------
* 鼠标左键             	定位/钢琴键盘
* 鼠标右键             	暂停
* 鼠标滑轮             	音量

键盘控制
-------------
* 左/右                	定位                   	[默认=1秒,Ctrl=5秒,Shift=30秒]
* 空格                 	暂停
* 上/下                	音量                   	[0%-200%]
* +/-                  	速度                   	[0%-1600%][默认=10%,Ctrl=3%,Shift=1%]
* [/]                  	和弦
* Shift+[/]            	音高
* PGUP/PGDN            	前一曲/后一曲
* Home/End             	第一曲/最后一曲
* F1                   	帮助
* F2                   	重置文件播放
* Ctrl+F2              	恢复初始设置
* F3                   	硬件重置
* Ctrl+F3              	切换MIDI设备/合成器
* Shift+F3             	切换MIDI长消息或流输出
* Ctrl+Shift+F3        	开/关忽略相同音符
* F4                   	重新渲染滑条
* Ctrl+F4              	自动重新渲染滑条
* Shift+F4             	录制视频
* F5/F6                	设置FPS                	[5-480][默认=120]
* Ctrl+F5/F6           	设置短MIDI事件缓冲区
* ShiftF5/F6           	设置最小MIDI事件音量
* Ctrl+Shift+F5/F6     	设置最大音符缓冲区
* F7/F8                	设置滑条大小           	[0%-1000%][默认=10%,Ctrl=3%,Shift=1%]
* Ctrl+Shift+F7/F8     	设置钢琴键盘音符缓冲区
* F9                   	设置滑条颜色           	[0=和弦,1=音轨/声道(有黑键),2=音轨/声道]
* F11                  	设置音符文字           	[0=数字,1=音名,2=无]
* Ctrl+F11             	设置信息文字
* Shift+F11            	设置小节/和弦线
* F12                  	设置循环模式           	[S=单曲循环,A=全部循环,N=不循环]

如何重置或卸载midiplayer3
-------------
* 运行此命令以重置midiplayer3：REG DELETE HKCU\Software\ax_midi_player / f
* 您也可以通过regedit.exe手动删除注册表项HKCU\Software\ax_midi_player
* 如果您能够运行midiplayer3，您也可以按Ctrl+F2重置所有设置

使用内存而非文件
-------------
* midiplayer3在播放之前需要加载MIDI文件信息。有3种方法可以强制midiplayer3使用内存
* 1：将第二个命令行参数设置为-M
* 2：运行命令：REG ADD HKCU\Software\ax_midi_player /v fbi /t REG_DWORD /d 1 /f
* 3：创建文件“FORCE_MEMORY”
* 否则midiplayer3会在%temp%文件夹中创建3个临时文件来存储信息

MIDI软件合成器与MIDI长消息输出
-------------
* 建议使用VirtualMIDISynth或OmniMIDI作为MIDI输出设备
* 合成器需要支持midiOutLongMsg Windows API函数作为MIDI输出的长MIDI事件
* Microsoft GS Wavetable Synth或其他MIDI输出设备可能不支持长MIDI事件
* 如果您的输出设备不支持长MIDI事件，请按Ctrl+F6增加短MIDI事件缓冲区
* 您还可以通过按Ctrl+F5缩短短MIDI事件缓冲区以获得更好的MIDI输出性能

更改声道颜色
-------------
* 您可以通过更改文件“CHANNEL_COLOR”的内容来更改音轨/声道颜色
* 每一行代表一种颜色，其色调值为0-255。 例如：0 =红色，85 =绿色，170 =蓝色
* 音轨/声道将按其音符计数排序，然后按顺序使用颜色
* 如果文件中定义的颜色少于音轨/频道编号，则颜色将重复

录制视频
-------------
* 您需要创建文件“RECORD_VIDEO”并在录制之前更改其内容
* 需要写入三行数据：输出文件的完整路径，帧率和视频质量
* 您可以按Shift+F4录制视频，midiplayer3将在录制前重置滑条
