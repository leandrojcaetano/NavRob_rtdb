unit drawmap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, Forms, Robots, Tatic,
  Field, Main, Roles;

const
   RobotDrawingVertex: array[0..13] of TPos=(
      (x:-0.21; y:0.065), (x:0.1; y:0.24), (x:0.21; y:0.175),
      (x:0.21; y:0.125),  (x:0.26; y:0.125), (x:0.26; y:0.1), (x:0.21; y:0.1),
      (x:0.21; y:-0.1),  (x:0.26; y:-0.1), (x:0.26; y:-0.125), (x:0.21; y:-0.125),
      (x:0.21; y:-0.175), (x:0.1; y:-0.24), (x:-0.21; y:-0.065));

procedure DrawRobot(var RS: TRobotState; extraColor: Tcolor; CNV: TCanvas);
procedure DrawRobotInfo(var RS: TRobotState; var RI: TRobotInfo; CNV: TCanvas);
procedure DrawRobotText(var RS: TRobotState; extraColor: Tcolor; CNV: TCanvas);


var
  FieldImageWidth, FieldImageHeight: integer;
  Dfieldmag: double;

implementation

uses Utils;

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
      TFMain.WorldToMap(xr,yr,Pts[i].x,Pts[i].y);
    end;
    Polygon(Pts);

    brush.color:=clgreen;
    brush.style:=bsClear;

    RotateAndTranslate(xr,yr,-0.08*1.25,0,RS.x,RS.y,RS.teta);
    TFMain.WorldToMap(xr,yr,x1,y1);
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
      WorldToMap(xr,yr,Pts[i].x,Pts[i].y);
    end;
    Polygon(Pts);

    brush.color:=clgreen;
    brush.style:=bsClear;

    RotateAndTranslate(xr,yr,-0.08*1.25,0,RS.x,RS.y,RS.teta);
    WorldToMap(xr,yr,x1,y1);
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
    WorldToMap(xr,yr,x1,y1);
    TextOut(x1-14,y1-23,RoleDefs[RI.role].name);
  end;
end;

end.

