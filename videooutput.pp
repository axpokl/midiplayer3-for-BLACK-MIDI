unit videooutput;

interface

uses
libavcodec,
libavformat,
libavformat_avio,
libavutil_frame,
libavutil_mem,
libavutil_pixfmt,
libavutil_rational,
libavutil_mathematics,
display;

procedure EncodeVideo(fname:pchar;framerate:longword;quality:double);
procedure WriteFrame(vf:PAVFrame);
procedure EncodeFrame(bb:pbitbuf);
procedure ReleaseVideo();

implementation

var ofmt:PAVOutputFormat;
var fmt:PAVFormatContext;
var cdc:PAVCodec;
var pkt:TAVPacket;
var stream:PAVStream;
var ctx:PAVCodecContext;

var vfb:longint;
var vfyuv:PAVFrame;
var vbufyuv:pointer;
var vbufyuvl:longword;

var idx:longint;

var i,j:longword;
var r,g,b,u,v,y:byte;
var z:longword;

procedure EncodeVideo(fname:pchar;framerate:longword;quality:double);
begin
ofmt:=av_guess_format(nil,fname,nil);
if(ofmt=nil)then ofmt:=av_guess_format('mpeg',nil,nil);
ofmt^.video_codec:=AV_CODEC_ID_H264;
fmt:=avformat_alloc_context();
fmt^.oformat:=ofmt;
fmt^.video_codec_id:=ofmt^.video_codec;
//avformat_alloc_output_context2(@fmt,ofmt,nil,fname);
cdc:=avcodec_find_encoder(ofmt^.video_codec);
ctx:=avcodec_alloc_context3(cdc);
ctx^.codec_id:=ofmt^.video_codec;
ctx^.gop_size:=framerate;
ctx^.bit_rate:=round(_w*_h*quality);
ctx^.width:=_w;
ctx^.height:=_h;
ctx^.pix_fmt:=AV_PIX_FMT_YUV420P;
ctx^.time_base:=av_make_q(1,framerate);
ctx^.framerate:=av_make_q(framerate,1);
ctx^.max_b_frames:=1;
if (ofmt^.flags and AVFMT_GLOBALHEADER)>0 then
  begin
  ctx^.flags:=ctx^.flags or AV_CODEC_FLAG_GLOBAL_HEADER;
  ctx^.extradata:=av_malloc(1024);
  ctx^.extradata_size:=0;
  end;
stream:=avformat_new_stream(fmt,cdc);
stream^.codec:=ctx;
stream^.time_base:=ctx^.time_base;
avcodec_parameters_to_context(ctx,stream^.codecpar);
//stream^.codecpar^.codec_id:=ofmt^.video_codec;
//stream^.codecpar^.width:=ctx^.width;
//stream^.codecpar^.height:=ctx^.height;
av_dump_format(fmt,0,fname,1);
avcodec_open2(ctx,cdc,nil);
avio_open2(@(fmt^.pb),fname,AVIO_FLAG_WRITE,nil,nil);
avformat_write_header(fmt,nil);
end;

procedure WriteFrame(vf:PAVFrame);
begin
av_init_packet(@pkt);
pkt.data:=vbufyuv;
pkt.size:=vbufyuvl;
pkt.stream_index:=fmt^.streams[0]^.index;
pkt.flags:=pkt.flags or AV_PKT_FLAG_KEY;
avcodec_encode_video2(ctx,@pkt,vf,@vfb);
if (vfb<>0) then
  begin
  ctx^.coded_frame^.pts:=idx;
  pkt.pts:=av_rescale_q(idx,ctx^.time_base,fmt^.streams[0]^.time_base);
  pkt.dts:=pkt.pts;
  //av_interleaved_write_frame(fmt,@pkt);
  av_write_frame(fmt,@pkt);
  end;
idx:=idx+1;
av_free_packet(@pkt);
end;

procedure EncodeFrame(bb:pbitbuf);
begin
vfyuv:=av_frame_alloc();
vbufyuvl:=avpicture_get_size(ctx^.pix_fmt,ctx^.width,ctx^.height);
vbufyuv:=av_malloc(vbufyuvl);
avpicture_fill(PAVPicture(vfyuv),vbufyuv,AV_PIX_FMT_YUV420P,ctx^.width,ctx^.height);
vfyuv^.width :=ctx^.width;
vfyuv^.height:=ctx^.height;
vfyuv^.format:=longint(ctx^.pix_fmt);
vfyuv^.data[0]:=vbufyuv;
vfyuv^.data[1]:=vfyuv^.data[0]+_w*_h;
vfyuv^.data[2]:=vfyuv^.data[1]+_w*_h shr 2;
vfyuv^.linesize[0]:=_w;
vfyuv^.linesize[1]:=_w shr 1;
vfyuv^.linesize[2]:=_w shr 1;
for j:=0 to _h-1 do
  for i:=0 to _w-1 do
    begin
    with bb^ do
      begin
      z:=min(bb^.len,max(0,((_w+1)*3)shr 2*4*(_h-(j+1))+i*3));
      b:=pbyte(buf+z)^;
      g:=pbyte(buf+z+1)^;
      r:=pbyte(buf+z+2)^;
      end;
    y:=trunc(+(0.257*r)+(0.504*g)+(0.098*b)+16);
    v:=trunc(+(0.439*r)-(0.368*g)-(0.071*b)+128);
    u:=trunc(-(0.148*r)-(0.291*g)+(0.439*b)+128);
    vfyuv^.data[0][j*vfyuv^.linesize[0]+i]:=y;
    vfyuv^.data[1][j shr 1*vfyuv^.linesize[1]+i shr 1]:=u;
    vfyuv^.data[2][j shr 1*vfyuv^.linesize[2]+i shr 1]:=v;
    end;
vfyuv^.pts:=idx;
WriteFrame(vfyuv);
av_free(vbufyuv);
av_free(vfyuv);
end;

procedure ReleaseVideo();
begin
vfb:=1;
while(vfb<>0)do
  begin
  vbufyuv:=av_malloc(vbufyuvl);
  WriteFrame(nil);
  av_free(vbufyuv);
  end;
av_write_trailer(fmt);
avio_close(fmt^.pb);
avcodec_close(ctx);
av_free(ctx);
av_packet_free(@pkt);
avformat_free_context(fmt);
end;

begin
av_register_all();
avcodec_register_all();
end.
