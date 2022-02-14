program videoencode;
uses
videooutput,
display;

var bb:pbitbuf;

procedure DrawVideo();
var x1,y1,x2,y2,c:longword;
begin
clear();
x1:=random(_w shr 2);
y1:=random(_h shr 2);
x2:=random(_w shr 1);
y2:=random(_h shr 1);
c:=random(white);
bar(x1,y1,x2-x1,y2-y1,c);
drawtextxy(i2s(_mscnti),0,0,black,white);
freshwin();
end;

begin
CreateWin(400,400);
bb:=CreateBB(GetWin());
EncodeVideo('T:\1.mp4',25,4);
repeat
DrawVideo();
GetBB(bb);
EncodeFrame(bb);
until not(iswin()) or (_mscnti=100);
ReleaseVideo();
ReleaseBB(bb);
end.
