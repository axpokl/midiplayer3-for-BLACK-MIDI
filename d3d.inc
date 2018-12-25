const D3DCUSTOMVTX=D3DFVF_XYZRHW or D3DFVF_DIFFUSE;

var d3d:IDirect3D9;
var d3ddev:IDirect3DDevice9;
var d3db:pbitmap;
var d3dfont:ID3DXFONT;

const maxbar=$10000;

type TVertex=record x,y,z,a:single;c:longword;end;
const maxvtx=$10;
const maxvtxbuf=$10000;
var vtx:array[0..1,0..maxvtx-1,0..maxbar*6-1]of TVertex;
var vtxn:array[0..1,0..maxbnote-1]of longword;
var vtxj0:array[0..1,0..maxvtx-1] of longint;
var vtxj1:array[0..1,0..maxvtxbuf-1] of longint;
var vtxb0:longint;
var vtxb1:array[0..1]of longint;

type TD3dText=record s:ansistring;x,y:longint;c:longword;end;
const maxd3dtext=$10;
const maxd3dtextbuf=$10000;
var d3dtext:array[0..1,0..maxd3dtext-1,0..maxbar-1]of TD3dText;
var d3dtextn:array[0..1,0..maxbnote-1]of longword;
var d3dtextj0:array[0..1,0..maxd3dtext-1] of longint;
var d3dtextj1:array[0..1,0..maxd3dtextbuf-1] of longint;
var d3dtextb0:longint;
var d3dtextb1:array[0..1]of longint;

procedure InitD3D();
begin d3d:=Direct3DCreate9(D3D_SDK_VERSION);end;

procedure SetD3DFont();
begin
D3DXCreateFont(
  d3ddev,_fh,_fw,_fwg,1,LONGBOOL(_flt),_fcs,
  OUT_DEFAULT_PRECIS,DEFAULT_QUALITY,DEFAULT_PITCH or FF_DONTCARE,
  as2pc(_ffn),d3dfont);
end;

procedure CreateD3D(w,h:longword);
var d3dpp:TD3DPresentParameters;
begin
ZeroMemory(@d3dpp,sizeof(d3dpp));
with d3dpp do
  begin
  BackBufferWidth:=w;
  BackBufferHeight:=h;
  BackBufferFormat:=D3DFMT_X8R8G8B8;
  SwapEffect:=D3DSWAPEFFECT_DISCARD;
  hDeviceWindow:=GetHwnd();
  Windowed:=true;
  Flags:=D3DPRESENTFLAG_LOCKABLE_BACKBUFFER;
  end;
d3d.CreateDevice(
  D3DADAPTER_DEFAULT,
  D3DDEVTYPE_HAL,
  GetHwnd(),
  D3DCREATE_HARDWARE_VERTEXPROCESSING,
  @d3dpp,
  d3ddev
  );
SetD3DFont();
end;

procedure CreateD3DBMP(w,h:longword);
begin
ReleaseBMP(d3db);
d3db:=CreateBMP(w,h,black0);
end;

procedure DrawD3D(b:pbitmap);
var d3dsur:IDirect3DSurface9;
var d3ddc:HDC;
begin
d3ddev.GetBackBuffer(0,0,D3DBACKBUFFER_TYPE_MONO,d3dsur);
d3dsur.GetDC(d3ddc);
ReleaseDC(d3db^.handle,d3db^.dc);
DeleteObject(d3db^.dc);
d3db^.dc:=d3ddc;
SelectObject(d3db^.dc,d3db^.handle);
DrawBMP(d3db,b);
d3dsur.ReleaseDC(d3ddc);
end;

procedure FreshD3DVertex(bi,vtxb0:longint);
var p:pointer;
var vtxbuf:IDirect3DVertexBuffer9;
var bj:longint;
begin
bj:=vtxj0[bi,vtxb0];
with d3ddev do
  begin
  CreateVertexBuffer(vtxn[bi,bj]*6*Sizeof(TVertex),0,D3DCUSTOMVTX,D3DPOOL_MANAGED,vtxbuf,nil);
  vtxbuf.Lock(0,vtxn[bi,bj]*6*Sizeof(TVertex),p,0);
  CopyMemory(p,@vtx[bi,vtxb0],vtxn[bi,bj]*6*Sizeof(TVertex));
  vtxbuf.Unlock();
  Clear(0,nil,D3DCLEAR_TARGET,black0,1,0);
  BeginScene();
  SetFVF(D3DCUSTOMVTX);
  SetStreamSource(0,vtxbuf,0,Sizeof(TVertex));
  DrawPrimitive(D3DPT_TRIANGLELIST,0,vtxn[bi,bj] shl 1);
  vtxn[bi,bj]:=0;
  EndScene();
//Present(nil,nil,0,nil);
  end;
FreshBMP(bi,bj);
DrawD3D(bnote[bi,bnotej1[bi,bj]]);
end;

procedure SetVertex(bi,bj:longint);
begin
if vtxj0[bi,vtxj1[bi,bj]]<>bj then
  begin
  vtxb1[bi]:=(vtxb1[bi]+1) and (maxvtx-1);
  vtxb0:=vtxb1[bi];
  if vtxn[bi,vtxj0[bi,vtxb0]]>0 then
    FreshD3DVertex(bi,vtxb0);
  vtxj0[bi,vtxb0]:=bj;
  vtxj1[bi,bj]:=vtxb0;
  end
else
  vtxb0:=vtxj1[bi,bj];
end;

procedure AddBar(bi,bj:longint;bx,by,bw,bh:single;bc:longword);
begin
SetVertex(bi,bj);
bw:=bx+bw;
bh:=by+bh;
bc:=(bc and $0000FF) shl 16 or (bc and $00FF00) or (bc and $FF0000) shr 16;
with vtx[bi,vtxb0,vtxn[bi,bj]*6+0] do begin x:=bx;y:=by;z:=0;c:=bc;a:=1;end;
with vtx[bi,vtxb0,vtxn[bi,bj]*6+1] do begin x:=bw;y:=by;z:=0;c:=bc;a:=1;end;
with vtx[bi,vtxb0,vtxn[bi,bj]*6+2] do begin x:=bx;y:=bh;z:=0;c:=bc;a:=1;end;
with vtx[bi,vtxb0,vtxn[bi,bj]*6+3] do begin x:=bx;y:=bh;z:=0;c:=bc;a:=1;end;
with vtx[bi,vtxb0,vtxn[bi,bj]*6+4] do begin x:=bw;y:=by;z:=0;c:=bc;a:=1;end;
with vtx[bi,vtxb0,vtxn[bi,bj]*6+5] do begin x:=bw;y:=bh;z:=0;c:=bc;a:=1;end;
vtxn[bi,bj]:=vtxn[bi,bj]+1;
if vtxn[bi,bj]>=maxbar then FreshD3DVertex(bi,vtxb0);
end;

procedure AddBar(bi,bj:longint;bx,by,bw,bh:single;bcfg,bcbg:longword);
begin
AddBar(bi,bj,bx,by,bw,bh,bcfg);
AddBar(bi,bj,bx+1,by+1,bw-2,bh-2,bcbg);
end;

procedure FreshD3DText(bi,d3dtextb0:longint);
var bj:longint;
var d3dtexti:longword;
var rt:TRect;
begin
bj:=d3dtextj0[bi,d3dtextb0];
with d3ddev do
  begin
  Clear(0,nil,D3DCLEAR_TARGET,black0,1,0);
  BeginScene();
  for d3dtexti:=0 to d3dtextn[bi,bj]-1 do
    with d3dtext[bi,d3dtextb0,d3dtexti] do
      begin
      rt.left:=x;
      rt.top:=y;
      rt.right:=x+GetStringWidth(s);
      rt.bottom:=y+GetStringHeight(s);
      d3dfont.DrawTextA(nil,as2pc(s),length(s),@rt,DT_SINGLELINE or DT_CENTER or DT_VCENTER,$FF000000 or c);
      end;
  d3dtextn[bi,bj]:=0;
  EndScene();
//Present(nil,nil,0,nil);
  end;
FreshBMP(bi,bj);
DrawD3D(bnote[bi,bnotej1[bi,bj]]);
end;

procedure SetD3DText(bi,bj:longint);
begin
if d3dtextj0[bi,d3dtextj1[bi,bj]]<>bj then
  begin
  d3dtextb1[bi]:=(d3dtextb1[bi]+1) and (maxd3dtext-1);
  d3dtextb0:=d3dtextb1[bi];
  if d3dtextn[bi,d3dtextj0[bi,d3dtextb0]]>0 then
    FreshD3DText(bi,d3dtextb0);
  d3dtextj0[bi,d3dtextb0]:=bj;
  d3dtextj1[bi,bj]:=d3dtextb0;
  end
else
  d3dtextb0:=d3dtextj1[bi,bj];
end;

procedure AddDrawTextXY(bi,bj:longint;bs:ansistring;bx,by:longint;bc:longword);
begin
SetD3DText(bi,bj);
bc:=(bc and $0000FF) shl 16 or (bc and $00FF00) or (bc and $FF0000) shr 16;
with d3dtext[bi,d3dtextb0,d3dtextn[bi,bj]] do begin s:=bs;x:=bx;y:=by;c:=bc;end;
d3dtextn[bi,bj]:=d3dtextn[bi,bj]+1;
if d3dtextn[bi,bj]>=maxbar then FreshD3DText(bi,d3dtextb0);
end;

procedure FreshD3DVertexAll();
var bi:shortint;
//var bj:longint;
begin
for bi:=0 to 1 do
  for vtxb0:=0 to maxvtx-1 do
    if vtxn[bi,vtxj0[bi,vtxb0]]>0 then
      FreshD3DVertex(bi,vtxb0);
end;

procedure FreshD3DTextAll();
var bi:shortint;
//var bj:longint;
begin
for bi:=0 to 1 do
  for d3dtextb0:=0 to maxd3dtext-1 do
    if d3dtextn[bi,d3dtextj0[bi,d3dtextb0]]>0 then
      FreshD3DText(bi,d3dtextb0);
end;

procedure FreshD3DAll();
begin
FreshD3DVertexAll();
FreshD3DTextAll();
end;
