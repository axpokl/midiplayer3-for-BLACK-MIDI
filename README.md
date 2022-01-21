Free Pascal midiplayer3 for Black MIDI by ax_pokl
=============

Release and Source Code
-------------
* Latest version: http://www.axpokl.com/midiplayer3.zip
* Latest version(with video record): http://www.axpokl.com/midiplayer3_video.zip
* Source code: https://github.com/axpokl/midiplayer3-for-BLACK-MIDI

How to Play
-------------
* Drag and drop files into the window to play
* Command line: midiplayer.exe filename.mid
* Support MIDI(.mid) and RMID(.rmi) file

Mouse Control
-------------
* MLeft                 Seek/Keyboard
* MRight                Pause
* MWheel                Volume

Key Control
-------------

**Play**
* Space                 Pause
* Left/Right            Seek                    midipos          0
* Up/Down               Volumn                  voli             100%(14)       0%-200%(1-16)
* +/-                   Speed                   spd              100%           0%-1600%
* [/]                   Chord                   kchord0
* ;/'                   Pitch                   kkey0            127            0-255

**File**
* PgUp/PgDn             Prev/Next
* Home/End              First/Last
* F                     Reload MIDI File        fnames

**Device**
* H                     Reset MIDI Device
* S                     Switch MIDI Device      midiouti         0
* Ctrl + S              Switch Long Msg/Stream  msgbufb1
* Shift + S             Ignore Same Notes       msgbufb0

**Display**
* D                     Draw All Notes
* A                     Draw All Notes Auto     autorefresh      1              0=Off,1=On
* ,/.                   Set Note Length         mult             100%           0%-1000%
* C                     Set Note Color          kbdcb            0              0=Chord,1=Track(Black Key),2=Track
* T                     Set Note Text           kchb             0              0=Number,1=Letter,2=Blank
* I                     Set Information Text    kchb2            0              0=All,1=No Track,2=No Msg,3=Key,4=None
* L                     Set Messure/Chord Line  kmessure         0              0=Minor,1=All,2=Major,3=Chord,4=None
* M                     Set Loop Mode           loop             1              0=None,1=Single,2=All

**Optimization**
* F2                    Switch Memory or File   fbi              0              0-1
* F3/F4                 Set Short Event Buffer  msgbufn0         128            1-16777216
* F5/F6                 Set Min Event Volume    msgvol0          2              0-127
* F7/F8                 Set Max Key buffer      maxkbdc          64             1-65536
* F11/F12               Set Max Frame Rate      framerate        120            5-480

**Others**
* F1                    Help                    helpb            0              0=On,1=Off
* R                     Reset All Setting
* V                     Record Video            vname/vrate/vquality

Start with Configuration
-------------
* There are 3 ways to start midiplayer3 with configuration with priority of below order:
1. Add a parameter after the command line with the format of: `-<key> <value>`  
  `midiplayer3.exe filename.mid -spd1 200`
2. Add a line under the file `.\midiplayer.ini` with the format of: `<key>=<value>`  
  `spd1=200`
3. Add a registry under with a type of `REG_DWORD` or `REG_SZ`: `HKCU\SOFTWARE\ax_midi_player`  
  `REG ADD HKCU\SOFTWARE\ax_midi_player /v spd1 /t REG_DWORD /d 200 /f`

Memory or File
-------------
* midiplayer3 needs to load MIDI file information in to memory before playing
* If the memory is not enough in the system, we can force it to save the information in file
* midiplayer3 creates 3 temporary files in %temp% folder to store the information
* You can switch between memory and file by pressing F2, or add a key called fbi

MIDI software synthesizer and MIDI Long Message
-------------
* It is recommended to use VirtualMIDISynth or OmniMIDI as MIDI output device
* The Synthesizer need to supports midiOutLongMsg Windows API function for long MIDI event as MIDI output
* The Microsoft GS Wavetable Synth or other MIDI output device may not support long MIDI event
* If your output device does not support long MIDI event, please increase the short MIDI event buffer by pressing F3
* You can also reduce the short MIDI event buffer to have better MIDI output performance by pressing F4

Channel Color
-------------
* You can change the Track/Channel color by add a key called chancolor
* It is a string value, consisting of numbers and separated by commas:  
  `chancolor=85,170,255,42,127,212,21,63,106,148,191,233,10,31,52,74,95,116,137,159,180,201,222,244`
* Each number represent a color which has a Hue value from 0-255. E.g. 0=Red, 85=Green and 170=Blue
* The Track/Channel will sort by it's note count, then use the color in order
* The color will repeat if there is less color in the file defined than Track/Channel number

Record Video
-------------
* You must use the video version of midiplayer3.exe with all the necessary DLL files to record video
* You can record video by pressing V, midiplayer3 will reset all notes before record
* midiplayer3 support mkv format
* You can change the output video name, framerate and quality by add keys:  
  `vname=midiplayer.mkv`  
  `vrate=30`  
  `vquality=4`


ax_pokl 特制 Free Pascal 黑乐谱MIDI播放器 midiplayer3
=============

最新版本和源代码
-------------
* 最新版本: http://www.axpokl.com/midiplayer3.zip
* 最新版本（含视频录制）: http://www.axpokl.com/midiplayer3_video.zip
* 源代码: https://github.com/axpokl/midiplayer3-for-BLACK-MIDI

如何播放
-------------
* 将文件拖放到窗口中播放
* 命令行：midiplayer.exe 文件名.mid
* 支持 MIDI(.mid) 和 RMID(.rmi) 文件

鼠标控制
-------------
* 鼠标左键              定位/钢琴键盘
* 鼠标右键              暂停
* 鼠标滑轮              音量

按键控制
-------------

**播放**
* 空格                  暂停
* 左/右                 定位                    midipos          0
* 上/下                 音量                    voli             100%(14)       0%-200%(1-16)
* +/-                   速度                    spd              100%           0%-1600%
* [/]                   和弦                    kchord0
* ;/'                   音调                    kkey0            127            0-255

**文件**
* PgUp/PgDn             上一个/下一个
* Home/End              第一个/最后一个
* F                     重新加载 MIDI 文件      fnames

**设备**
* H                     重置 MIDI 设备
* S                     切换 MIDI 设备          midiouti        0
* Ctrl + S              切换长消息/流           msgbufb1
* Shift + S             忽略相同的注释          msgbufb0

**显示**
* D                     画出所有音符
* A                     自动画出所有音符        autorefresh      1              0=关,1=开
* ,/.                   设置音符长度            mult             100%           0%-1000%
* C                     设置音符颜色            kbdcb            0              0=Chord,1=Track(Black Key),2=Track
* T                     设置注释文本            kchb             0              0=数字,1=字母,2=空白
* I                     设置信息文本            kchb2            0              0=All,1=No Track,2=No Msg,3=Key,4=None
* L                     设置小结/调式线         kmessure         0              0=Minor,1=All,2=Major,3=Chord,4=None
* M                     设置循环模式            loop             1              0=None,1=Single,2=All

**优化**
* F2                    切换内存或文件          fbi              0              0-1
* F3/F4                 设置短事件缓冲区        msgbufn0         128            1-16777216
* F5/F6                 设置最小事件音量        msgvol0          2              0-127
* F7/F8                 设置最大密钥缓冲区      maxkbdc          64             1-65536
* F11/F12               设置最大帧率帧率        framerate        120            5-480

**其他**
* F1                    帮助                    helpb            0              0=开,1=关
* R                     重置所有设置
* V                     录制视频                vname/vrate/vquality 

使用配置启动
-------------
* 有 3 种方法来启动 midiplayer3，配置优先级如下：
1. 在命令行后添加参数，格式为：`-<key> <value>`  
  `midiplayer3.exe filename.mid -spd1 200`
2. 在`.\midiplayer.ini`文件下添加一行，格式为：`<key>=<value>`  
  `spd1=200`
3. 在类型为 `REG_DWORD` 或 `REG_SZ` 下添加注册表：`HKCU\SOFTWARE\ax_midi_player`  
  `REG ADD HKCU\SOFTWARE\ax_midi_player /v spd1 /t REG_DWORD /d 200 /f `

内存或文件
-------------
* midiplayer3 播放前需要将 MIDI 文件信息加载到内存中
* 如果系统内存不够，我们可以强制将信息保存在文件中。
* midiplayer3 在 %temp% 文件夹中创建 3 个临时文件来存储信息
* 可以按F2在内存和文件之间切换，或者添加一个叫fbi的键

MIDI软件合成器与MIDI长消息输出
-------------
* 推荐使用 VirtualMIDISynth 或 OmniMIDI 作为 MIDI 输出设备
* 合成器需要支持 midiOutLongMsg Windows API 函数，用于将长 MIDI 事件作为 MIDI 输出
* Microsoft GS Wavetable Synth 或其他 MIDI 输出设备可能不支持长 MIDI 事件
* 如果您的输出设备不支持长 MIDI 事件，请按 F3 增加短 MIDI 事件缓冲区
* 您还可以通过按 F4 减少短 MIDI 事件缓冲区以获得更好的 MIDI 输出性能

声道颜色
-------------
* 您可以通过添加一个名为 chancolor 的键来更改音轨/声道颜色
* 它是一个字符串值，由数字组成并以逗号分隔：
  `chancolor=85,170,255,42,127,212,21,63,106,148,191,233,10,31,52,74,95,116,137,159,180,201,222,244`
* 每个数字代表一种颜色，其色调值介于 0-255 之间。 例如。 0=红色，85=绿色，170=蓝色
* 音轨/声道将按其音符数排序，然后按顺序使用颜色
* 如果文件中定义的颜色少于音轨/声道编号，颜色将重复 


录制视频
-------------
* 您必须使用 midiplayer3.exe 的视频版本以及所有必要的 DLL 文件来录制视频
* 可以按V录制视频，midiplayer3会在录制前重置所有音符
* midiplayer3 支持 mkv 格式
* 您可以通过添加以下键来更改输出视频名称、帧速率和质量：  
  `vname=midiplayer.mkv`  
  `vrate=30`  
  `vquality=4`
