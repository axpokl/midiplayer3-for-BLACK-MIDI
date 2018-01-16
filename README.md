Free Pascal midiplayer3 for Black MIDI by ax_pokl
=============

How to Play
-------------
* Drag file to play
* Support command line	[midiplayer.exe filename.mid [-M]]
* Support MIDI(.mid) and RMID(.rmi) file

Mouse Control
-------------
* MLeft	Seek/Keyboard
* MRight	Pause
* MWheel	Volume

Key Control
-------------
* L/R	Seek	[Default=1s,Ctrl=5s,Shift=30s]
* Space	Pause
* UP/DN	Volumn	[0%-200%]
* +/-	Speed	[0%-1600%][Default=10%,Ctrl=3%,Shift=1%]
* [/]	Chord	[Shift=Pitch]

File Control
-------------
* PGUP	Next
* PGDN	Prev
* Home	First
* End	Last

Other Functions
-------------
* F1	Help
* F2	File Reset
* F3	Hardware Reset [Ctrl=Change MIDI output device]
* F4	Bar Reset [Ctrl=Auto Reset]
* F5/F6	FPS [5-480(Default=120)]
* F7/F8	Bar Size	[0%-1000%][Default=10%,Ctrl=3%,Shift=1%]
* F9	Bar Color	[0=Chord,1=Track/Channel(Black),2=Track/Channel]
* F11	Key Number	[0=Number,1=Chord,2=Blank][Ctrl=Text On/Off]
* F12	Loop Mode [S=Single,A=All,N=None]

Memory instead of File
-------------
* There are 3 ways to force use memory
* 1: Set 2nd command line parameter to -M
* 2: Run Command: REG ADD HKCU\Software\ax_midi_player /v fbi /t REG_DWORD /d 1 /f
* 3: Create File "FORCE_MEMORY"

MIDI software synthesizer
-------------
* It is recommended to use the VirtualMIDISynth as driver device for MIDI output
* VirtualMIDISynth supports midiOutLongMsg function as MIDI output
* The Microsoft GS Wavetable Synth or other MIDI output device may not support long MIDI event
* Website: https://coolsoft.altervista.org/en/virtualmidisynth
* If your MIDI output device does not support long MIDI event, please run following command:
* REG ADD HKCU\Software\ax_midi_player /v msgbufn0 /t REG_DWORD /d 2147483647 /f