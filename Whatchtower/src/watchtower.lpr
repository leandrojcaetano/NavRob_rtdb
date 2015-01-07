program watchtower;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Main, lnetvisual, tachartlazaruspkg, Field, Param, Fuzzy, dynmatrix,
  Robots, Roles, Tatic, Utils, Log, LogCompat;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TFMain, FMain);
  Application.CreateForm(TFField, FField);
  Application.CreateForm(TFLog, FLog);
  Application.CreateForm(TFParam, FParam);
  Application.Run;
end.

