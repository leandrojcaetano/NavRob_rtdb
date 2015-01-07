unit Robots;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, RoCConsts,
  Graphics, Controls, Forms, Dialogs, Tatic,
  Math, Types, dynmatrix, Main, Roles;

const

   RobotDrawingVertex: array[0..13] of TPos=(
      (x:-0.21; y:0.065), (x:0.1; y:0.24), (x:0.21; y:0.175),
      (x:0.21; y:0.125),  (x:0.26; y:0.125), (x:0.26; y:0.1), (x:0.21; y:0.1),
      (x:0.21; y:-0.1),  (x:0.26; y:-0.1), (x:0.26; y:-0.125), (x:0.21; y:-0.125),
      (x:0.21; y:-0.175), (x:0.1; y:-0.24), (x:-0.21; y:-0.065));

type
  TRobotStatus = record
    active: boolean;
    default_role: TRole;
    start_role: integer;
    manual_control: boolean;
    v1: integer;
    v2: integer;
  end;


var
  RobotStatus: array[0..MaxRobots-1] of TRobotStatus;

procedure PropagateXYTeta(var RS: TRobotstate);
procedure PropagateXYTetaOthers(var RS: TRobotstate);
procedure RobotStateDoublesToMatrix(var Robot: TRobotState);
procedure RobotStateMatrixToDoubles(var Robot: TRobotState);

procedure SaturateRobotXY(var RS: TRobotstate);
procedure DrawRobotText(var RS: TRobotState; extraColor: Tcolor; CNV: TCanvas);
procedure DrawRobot(var RS: TRobotState; extraColor: Tcolor; CNV: TCanvas);
procedure DrawRobotInfo(var RS: TRobotState; var RI: TRobotInfo; CNV: TCanvas);

implementation

uses Utils, Param, Field;


procedure RobotStateMatrixToDoubles(var Robot: TRobotState);
begin
  with Robot do begin
    x:=Xk.getv(0,0);
    y:=Xk.getv(1,0);
    teta:=Xk.getv(2,0);

    cov_x:=Pk.getv(0,0);
    cov_y:=Pk.getv(1,1);
    cov_xy:=0.5*(Pk.getv(0,1)+Pk.getv(1,0));
    cov_teta:=Pk.getv(2,2);
  end;
end;

procedure RobotStateDoublesToMatrix(var Robot: TRobotState);
begin
  with Robot do begin
    Xk.setv(0,0,x);
    Xk.setv(1,0,y);
    Xk.setv(2,0,teta);

    Pk.setv(0,0,cov_x);
    Pk.setv(1,1,cov_y);
    Pk.setv(0,1,cov_xy);
    Pk.setv(1,0,cov_xy);
    Pk.setv(2,2,cov_teta);
  end;
end;

procedure SaturateRobotXY(var RS: TRobotstate);
begin
  with RS do begin
    if x>FieldDims.BoundaryDepth/2 then x:=FieldDims.BoundaryDepth/2;
    if x<-FieldDims.BoundaryDepth/2 then x:=-FieldDims.BoundaryDepth/2;
    if y>FieldDims.BoundaryWidth/2 then y:=FieldDims.BoundaryWidth/2;
    if y<-FieldDims.BoundaryWidth/2 then y:=-FieldDims.BoundaryWidth/2;
  end;
  RobotStateDoublesToMatrix(RS);
end;

procedure VxyToV(teta,vx,vy: double; var V: double);
var ct,st: double;
begin

  ct:=cos(teta);
  st:=sin(teta);
  v:=(vx+vy)/(ct+st);

end;

procedure VToVxy(teta, V: double; var vx,vy: double);
var ct,st: double;
begin

  vx:=v*cos(teta);
  vy:=v*sin(teta);


end;

procedure PropagateXYTeta(var RS: TRobotstate);
var i: integer;
begin
  with RS do begin

    v := (View.Odos[0].speedw[0]+View.Odos[0].speedw[1])/2;
    w := (View.Odos[0].speedw[0]-View.Odos[0].speedw[1])/0.2318;

    VxyToV(teta, v, vx, vy);
  end;
end;

procedure PropagateXYTetaOthers(var RS: TRobotstate);
var cov_xy_noise,cov_teta_noise: double;
begin
  cov_xy_noise:=0.01;
  cov_teta_noise:=0.001;
  // TODO
  with RS do begin
    x:=x+0.04*v*cos(teta);
    y:=y+0.04*v*sin(teta);
    teta:=teta+0.04*w*pi/180;
    cov_x:=cov_x+cov_xy_noise;
    cov_y:=cov_y+cov_xy_noise;
    cov_teta:=cov_teta+cov_teta_noise;
  end;
end;

procedure DrawRobot(var RS: TRobotState; extraColor: Tcolor; CNV: TCanvas);
var i,x1,y1: integer;
    xr,yr: double;
    Pts: array[Low(RobotDrawingVertex)..High(RobotDrawingVertex)] of TPoint;
begin
  with CNV do begin //tcanvas
    pen.color:=clblack;
    brush.color:=clBlack;
    brush.style:=bsSolid;
    if extraColor=clRed then begin
      pen.color:=clRed;
      brush.color:=clRed;
    end;

    for i:=Low(RobotDrawingVertex) to High(RobotDrawingVertex) do begin
      RotateAndTranslate(xr,yr,RobotDrawingVertex[i].x*1.25,RobotDrawingVertex[i].y*1.25,RS.x,RS.y,RS.teta);
      FMain.WorldToMap(xr,yr,Pts[i].x,Pts[i].y);
    end;
    Polygon(Pts);

    brush.color:=clgreen;
    brush.style:=bsClear;

    RotateAndTranslate(xr,yr,-0.08*1.25,0,RS.x,RS.y,RS.teta);
    FMain.WorldToMap(xr,yr,x1,y1);
    font.Color:=CTeamColorColor24[TeamColor];
    TextOut(x1-2,y1-5,inttostr(RS.num+1));

    if RS.num=myNumber then begin
      DrawCovElipse(RS.x,RS.y,RS.cov_x,RS.cov_y,RS.cov_xy,10,CNV);
    end;
  end;
end;

procedure DrawRobotText(var RS: TRobotState; extraColor: Tcolor; CNV: TCanvas);
var i,x1,y1: integer;
    xr,yr: double;
    Pts: array[Low(RobotDrawingVertex)..High(RobotDrawingVertex)] of TPoint;
begin
  with CNV do begin //tcanvas
    pen.color:=clblack;
    brush.color:=clBlack;
    brush.style:=bsSolid;

    for i:=Low(RobotDrawingVertex) to High(RobotDrawingVertex) do begin
      RotateAndTranslate(xr,yr,RobotDrawingVertex[i].x*1.25,RobotDrawingVertex[i].y*1.25,RS.x,RS.y,RS.teta);
      FMain.WorldToMap(xr,yr,Pts[i].x,Pts[i].y);
    end;
    Polygon(Pts);

    brush.color:=clgreen;
    brush.style:=bsClear;

    RotateAndTranslate(xr,yr,-0.08*1.25,0,RS.x,RS.y,RS.teta);
    FMain.WorldToMap(xr,yr,x1,y1);
    font.Color:=CTeamColorColor24[TeamColor];

    TextOut(x1-2,y1-5,inttostr(RS.num+1));

    if RS.num=myNumber then begin
      font.Color:=clWhite;
      TextOut(x1-20,y1-20,format('%.1f,%.1f,%d',[RS.x,RS.Y,round(RS.teta/(2*pi)*360)]));
      DrawCovElipse(RS.x,RS.y,RS.cov_x,RS.cov_y,RS.cov_xy,10,CNV);
    end;
  end;
end;

procedure DrawRobotInfo(var RS: TRobotState; var RI: TRobotInfo; CNV: TCanvas);
var i,x1,y1: integer;
    xr,yr: double;
    Pts: array[Low(RobotDrawingVertex)..High(RobotDrawingVertex)] of TPoint;
begin
  with CNV do begin //tcanvas
    font.Color:=clWhite;

    RotateAndTranslate(xr,yr,0,0,RS.x,RS.y,RS.teta);
    FMain.WorldToMap(xr,yr,x1,y1);
    TextOut(x1-14,y1-23,RoleDefs[RI.role].name);
  end;
end;

end.

