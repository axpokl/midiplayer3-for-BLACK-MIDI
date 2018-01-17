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
* L/R	Seek	(Default=1s,Ctrl=5s,Shift=30s)
* Space	Pause
* UP/DN	Volumn	[0%-200%]
* +/-	Speed	[0%-1600%](Default=10%,Ctrl=3%,Shift=1%)
* [/]	Chord	
* Shift+[/]	Pitch

File Control
-------------
* PGUP/PGDN	Prev/Next
* Home/End	First/Last

Other Functions
-------------
* F1	Help
* F2	Reset File
* Ctrl+F2	Reset All
* F3	Reset Hardware
* F4	Reset Bar 
* Ctrl+F4	Auto Reset Bar
* F5/F6	Set FPS [5-480](Default=120)
* Ctrl+F5/F6	Set short MIDI event buffer
* F7/F8	Set Bar Size	[0%-1000%](Default=10%,Ctrl=3%,Shift=1%)
* F9	Set Bar Color	[0=Chord,1=Track/Channel(With Black Key),2=Track/Channel]
* F11	Set Key Number	[0=Number,1=Chord,2=Blank]
* Ctrl+F11	On/Off Information Text
* Shift+F1	On/Off Messure/Chord line
* F12	Set Loop Mode [S=Single,A=All,N=None]

Reset or Uninstall the midiplayer3
-------------
* Run this Command to reset midiplayer3: REG DELETE HKCU\Software\ax_midi_player /f
* You can also delete the registry key HKCU\Software\ax midi player by regedit.exe manually
* If you are able to run midiplayer3, you can also press Ctrl+F2 to reset all the settings

Memory instead of File
-------------
* There are 3 ways to force midiplayer3 use memory
* 1: Set 2nd command line parameter to -M
* 2: Run Command: REG ADD HKCU\Software\ax_midi_player /v fbi /t REG_DWORD /d 1 /f
* 3: Create File "FORCE_MEMORY"
* Otherwise midiplayer3 creates 3 temporary files in %temp% to store the information

MIDI software synthesizer
-------------
* It is recommended to use VirtualMIDISynth as MIDI output device: https://coolsoft.altervista.org/en/virtualmidisynth
* VirtualMIDISynth supports midiOutLongMsg Windows API function for long MIDI event as MIDI output
* The Microsoft GS Wavetable Synth or other MIDI output device may not support long MIDI event
* If your output device does not support long MIDI event, please increase the short MIDI event buffer by pressing Ctrl+F6
* You can also reduce the short MIDI event buffer to have better MIDI output performance by pressing Ctrl+F5