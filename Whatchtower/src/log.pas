unit Log;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Graphics, Controls, Forms, Dialogs, Main, StdCtrls,
  ComCtrls, ImgList, Grids, Types, IniFiles, ExtCtrls, Menus, LResources,
  IniPropStorage, ShellCtrls, TAGraph, LogCompat, TASeries;

const
  LogFrames=4096;

type
  pdouble=^double;
  pinteger=^integer;
  pword=^word;
  pboolean=^boolean;

  LogRecord=record
    RobotState: array[0..3] of TRobotState;
  end;

  TLogType=(logDouble,logInt,LogWord,logBool,logRole,logTask,logAction,logAvoid);


type

  { TFLog }

  TFLog = class(TForm)
    Chart: TChart;
    SGLog: TStringGrid;
    FormStorage: TIniPropStorage;
    ILCheckBox: TImageList;
    MenuClear: TMenuItem;
    MenuExport: TMenuItem;
    PopupMenuLog: TPopupMenu;
    SaveDialogLog: TSaveDialog;
    TreeView: TTreeView;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TreeView1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TreeViewMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject);
    procedure MenuExportClick(Sender: TObject);
    procedure MenuClearClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    function OffsetTypeToPointer(var variavel; tipo: TLogType): Pointer;
    procedure PointerToOffsetType(p: Pointer; var offset: integer; var tipo: TLogType);
    procedure FillRobotStateTreeView(num: integer; root: TTreeNode; tree: TTreeView);

    function GetLogString(tree: TTreeView; prop,index: integer): string;
    function GetLogValue(tree: TTreeView; prop,index: integer): double;

  public
    { Public declarations }
    IndexMenu: integer;

    function LogFrame(par_frame_timestamp,par_camera,increment: integer): integer;
    procedure RefreshGrid(tree: TTreeView);
    procedure LogToStrings(SL: TStrings; tree: TTreeView; idx: integer);
    function LogFrameShowing: integer;
    procedure FillTreeView(tree: TTreeView);
    procedure SaveTree(tree: TTreeView);
    procedure LoadTree(tree: TTreeView);
  end;

var
  FLog: TFLog;

  LogBuffer: array[0..LogFrames-1] of LogRecord;
  LogBufferIn: integer = 0;
  LogBufferCount: integer = 0;


implementation

uses Robots;

// initialization

procedure TFLog.FormCreate(Sender: TObject);
begin
  FormStorage.IniFileName:=Fmain.FormStorage.IniFileName;
end;

procedure TFLog.FormClose(Sender: TObject);
begin
  SaveTree(TreeView);
end;

procedure TFLog.FormDestroy(Sender: TObject);
begin
  SaveTree(TreeView);
end;

// treeview support

procedure TFLog.SaveTree(tree: TTreeView);
var ini: TIniFile;
    i: integer;
begin
  ini:=TIniFile.Create(extractfilepath(application.ExeName)+FMain.dataDir+'/tree.ini');
  for i:=0 to tree.Items.Count-1 do begin
    ini.WriteInteger(tree.Name,'item'+inttostr(i),tree.Items[i].ImageIndex);
    ini.WriteBool(tree.Name,'expand'+inttostr(i),tree.Items[i].Expanded);
  end;
  ini.UpdateFile;
  ini.Free;
end;

procedure TFLog.LoadTree(tree: TTreeView);
var ini: TIniFile;
    i,def: integer;
begin
  ini:=TIniFile.Create(extractfilepath(application.ExeName)+FMain.dataDir+'/tree.ini');
  for i:=0 to tree.Items.Count-1 do begin
    if tree.Items[i].data=nil then def:=2
    else def:=0;
    tree.Items[i].SelectedIndex:=ini.ReadInteger(tree.Name,'item'+inttostr(i),def);
    tree.Items[i].Expanded:=ini.ReadBool(tree.Name,'expand'+inttostr(i),false);
  end;
  ini.Free;
end;

function TFLog.OffsetTypeToPointer(var variavel; tipo: TLogType): Pointer;
var offset: integer;
begin
  offset:=pchar(@variavel)-pchar(@LogBuffer[0]);
  result:=Pointer(offset+(ord(tipo) shl 16));
end;

procedure TFLog.PointerToOffsetType(p: Pointer; var offset: integer; var tipo: TLogType);
var i: integer;
begin
  i:=integer(p);
  offset:=i and $FFFF;
  tipo:=TLogType(i shr 16);
end;

procedure TFLog.FillRobotStateTreeView(num: integer; root: TTreeNode; tree: TTreeView);
var node: TTreeNode;
begin
   with tree.Items,LogBuffer[0].RobotState[num] do begin
    node:=AddChild(root,'x');
    node.Data:=OffsetTypeToPointer(x,logDouble);
    node:=AddChild(root,'y');
    node.Data:=OffsetTypeToPointer(y,logDouble);
    node:=AddChild(root,'teta');
    node.Data:=OffsetTypeToPointer(teta,logDouble);
    node:=AddChild(root,'vx');
    node.Data:=OffsetTypeToPointer(vx,logDouble);
    node:=AddChild(root,'vy');
    node.Data:=OffsetTypeToPointer(vy,logDouble);
    node:=AddChild(root,'w');
    node.Data:=OffsetTypeToPointer(w,logDouble);
   end;
end;

procedure TFLog.FillTreeView(tree: TTreeView);
var node: TTreeNode;
    i: integer;
begin
  tree.Items.Clear;
  with tree.Items do begin
    node:=Add(nil,'Robot 1');
    node.Data:=nil;
    FillRobotStateTreeView(0,node,tree);
    node:=Add(nil,'Robot 2');
    node.Data:=nil;
    FillRobotStateTreeView(1,node,tree);
    node:=Add(nil,'Robot 3');
    node.Data:=nil;
    FillRobotStateTreeView(2,node,tree);
    node:=Add(nil,'Robot 4');
    node.Data:=nil;
    FillRobotStateTreeView(3,node,tree);

    for i:=0 to Count-1 do begin
      if tree.Items[i].Data=nil then begin
        tree.Items[i].ImageIndex:=2
      end else begin
        tree.Items[i].ImageIndex:=0;
      end;
      tree.Items[i].SelectedIndex:=tree.Items[i].ImageIndex;
    end;
  end;
end;

// click procedure

procedure TFLog.TreeViewMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var node: TTreeNode;
begin
  node:=(Sender as TTreeView).GetNodeAt(X,Y);
  if node=nil then exit;
  if node.ImageIndex=0 then begin
    node.ImageIndex:=1;
    node.SelectedIndex:=1;
  end else begin
    if node.ImageIndex=1 then begin
      node.ImageIndex:=0;
      node.SelectedIndex:=0;
    end;
  end;

  RefreshGrid(TreeView);
end;

function TFLog.LogFrame(par_frame_timestamp,par_camera,increment: integer): integer;
begin

  LogBuffer[LogBufferIn].RobotState[0]:=RobotState[0];
  LogBuffer[LogBufferIn].RobotState[1]:=RobotState[1];
  LogBuffer[LogBufferIn].RobotState[2]:=RobotState[2];
  LogBuffer[LogBufferIn].RobotState[3]:=RobotState[3];

  result:=LogBufferIn;

  if increment<>0 then begin
    Inc(LogBufferIn);
    if LogBufferIn>=LogFrames then LogBufferIn:=0;

    if LogBufferCount<LogFrames then Inc(LogBufferCount);
  end;
end;


function TFLog.GetLogString(tree: TTreeView; prop,index: integer): string;
var offset: integer;
    tipo: TLogType;
    ptr: Pointer;
begin
  result:='';
  if tree.Items[prop].Data=nil then exit;

  PointerToOffsetType(tree.Items[prop].Data,offset,tipo);
  ptr:=pchar(@(LogBuffer[index]))+offset;

  case tipo of
    logInt: result:=inttostr(pinteger(ptr)^);
    logDouble: result:=Format('%.3f',[pdouble(ptr)^]);
    logBool: if pboolean(ptr)^ then result:='True' else result:='False';
    logWord: result:=inttostr(pword(ptr)^);
  end;
end;

function TFLog.GetLogValue(tree: TTreeView; prop,index: integer): double;
var offset: integer;
    tipo: TLogType;
    ptr: Pointer;
begin
  result:=0.0;
  if tree.Items[prop].Data=nil then exit;

  PointerToOffsetType(tree.Items[prop].Data,offset,tipo);
  ptr:=pchar(@(LogBuffer[index]))+offset;

  case tipo of
    logInt: result:=pinteger(ptr)^;
    logDouble: result:=pdouble(ptr)^;
    logBool: result:=ord(pboolean(ptr)^);
  end;
end;

function RandColor(i: integer): TColor;
begin
  RandSeed:=i;
  result:=TColor(random(255) or (random(255) shl 8) or (random(255) shl 16));
end;

function GetPropName(tree: TTreeView; idx: integer): string;
var node: TTreeNode;
begin
  result:='';
  node:=tree.Items[idx];
  while node<>nil do begin
    result:='.'+node.Text+result;
    node:=node.Parent;
  end;
  if result<>'' then result:=copy(result,2,1000);
end;

procedure TFLog.RefreshGrid(tree: TTreeView);
var i,j,cnt,idx: integer;
    cs: TSerie;
begin
  with tree.Items do begin

    While Chart.SeriesCount>0 do begin
      i := Chart.SeriesCount;
      cs := TSerie(Chart.Series.Items[0]);
      cs.Free;
    end;

    cnt:=0;
    for i:=0 to Count-1 do begin
      if tree.Items[i].ImageIndex=1 then begin
        Inc(cnt);

        cs := TSerie.Create(Chart);
        cs.ShowLines := true;
        cs.ShowPoints := false;

        cs.SeriesColor := RandColor(i);
        Chart.AddSeries(cs);

      end;
    end;
        //fim do descomentado

    // set grid size
    if cnt<1 then cnt:=1;
    SGLog.RowCount:=cnt+1;
    if LogBufferCount<1 then begin
      SGLog.ColCount:=2;
      SGLog.Cols[1].Clear;
    end else
    SGLog.ColCount:=LogBufferCount+1;
    SGLog.FixedRows:=1;
    SGLog.FixedCols:=1;
    SGLog.ColWidths[0]:=150;

    cnt:=0;
    for i:=0 to Count-1 do begin
      if tree.Items[i].ImageIndex=1 then begin
        Inc(cnt);
        SGLog.Cells[0,cnt]:=GetPropName(tree,i);
        for j:=0 to LogBufferCount-1 do begin
          idx:=(LogBufferIn-LogBufferCount+j+LogFrames) mod LogFrames;
          SGLog.Cells[j+1,cnt]:=GetLogString(tree,i,idx);
          Tserie(Chart.Series[cnt-1]).AddXY(j,GetLogValue(tree,i,idx),'',Chart.Color);
        end;
      end;
    end;
  end;
end;

procedure TFLog.LogToStrings(SL:TStrings; tree: TTreeView; idx: integer);
var i: integer;
begin
  with tree.Items do begin
    for i:=0 to Count-1 do begin
      if tree.Items[i].ImageIndex=1 then begin
        SL.add(GetPropName(tree,i)+': '+GetLogString(tree,i,idx));
      end;
    end;
  end;
end;

function TFLog.LogFrameShowing: integer;
begin
  if not FLog.Showing then begin
    result:=-1;
  end else begin
    result:=(LogBufferIn - LogBufferCount + SGLog.Selection.Left + LogFrames) mod LogFrames;
  end;
end;

procedure TFLog.FormShow(Sender: TObject);
begin
  FillTreeView(TreeView);
  LoadTree(TreeView);
  RefreshGrid(TreeView);
end;

procedure TFLog.TreeView1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin

end;

procedure TFLog.MenuExportClick(Sender: TObject);
var i,j: integer;
    s: string;
    sl: TStringList;
begin
  if SaveDialogLog.Execute then begin
    SaveDialogLog.InitialDir:=ExtractFilePath(SaveDialogLog.FileName);

    sl:=TStringList.Create;
    try
      for i:=1 to SGLog.ColCount-1 do begin
        s:='';
        for j:=1 to SGLog.RowCount-1 do begin
          s:=s+Format('%10s ',[SGLog.Cells[i,j]]);
        end;
        sl.Add(s);
      end;
      sl.SaveToFile(SaveDialogLog.FileName);
    finally
      sl.Free;
    end;
  end;
end;

procedure TFLog.MenuClearClick(Sender: TObject);
begin
  LogBufferIn:=0;
  LogBufferCount:=0;
  RefreshGrid(TreeView);
end;

procedure TFLog.FormActivate(Sender: TObject);
begin
  RefreshGrid(TreeView);
end;

initialization
  {$I Log.lrs}

end.

