unit f_Main;
//{$DEFINE DELPHI7_UP}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, DB, ADODB

  ,o_Managers
//  ,tpk_Utls
  ,StrUtils, Spin

  ,System.JSON, AdvOfficeButtons
  ;

type
  TMainForm = class(TForm)
    edtRootFolder: TEdit;
    btnRootFolder: TButton;
    Label1: TLabel;
    chSales: TAdvOfficeCheckBox;
    chInternal: TAdvOfficeCheckBox;
    btnExec: TButton;
    btnAbort: TButton;
    ProgressBar: TProgressBar;
    mmoLog: TMemo;

    Label2: TLabel;
    speMonthsBefore: TSpinEdit;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    ADOConnection1: TADOConnection;
    chPurchases: TAdvOfficeCheckBox;
    procedure AnyClick(Sender: TObject);
  protected
    FIniFileName : string;
    FExecuting : Boolean;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Execute();
    procedure FileProcessor_OnStep(Manager: TInputManager; Processor: TFileProcessor; Status: TProcessorStatus);
    procedure FileProcessor_OnLog(Manager: TInputManager; Processor: TFileProcessor; Text: string);
    procedure Log(Text: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;
  implementation

{$R *.dfm}

uses
  IniFiles
  ,o_Purchases
  , MaskUtils
  , DateUtils
  ,uStringHandlingRoutines
  ,JclSysUtils

  ;

{ TMainForm }


(*----------------------------------------------------------------------------*)
constructor TMainForm.Create(AOwner: TComponent);
var
  Ini      : TIniFile;
  S        : string;
begin
  inherited;
//  FIniFileName := Utls.AppPath + 'Main.ini';
  SetLength(S, 4096);
  SetLength(S, GetModuleFileName(HInstance, PChar(S), Length(S)));
  GetModuleFileName(HInstance, PChar(S), Length(S));
  FIniFileName := ExtractFilePath(S) + 'Main.ini';

  Ini := TIniFile.Create(FIniFileName);
  try
    edtRootFolder.Text := Ini.ReadString('Main', 'RootFolder', '');
  finally
    Ini.Free;
  end;
end;
(*----------------------------------------------------------------------------*)
destructor TMainForm.Destroy;
var
  Ini : TIniFile;
begin
  Ini := TIniFile.Create(FIniFileName);
  try
    Ini.WriteString('Main', 'RootFolder',  edtRootFolder.Text);
  finally
    Ini.Free;
  end;

  inherited;
end;
(*----------------------------------------------------------------------------*)
procedure TMainForm.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if Key = VK_ESCAPE then
    Close();
end;
(*----------------------------------------------------------------------------*)
procedure TMainForm.Log(Text: string);
begin
  mmoLog.Lines.Add(Text);

end;
(*----------------------------------------------------------------------------*)
procedure TMainForm.AnyClick(Sender: TObject);
var
  FileName : string;
begin
  if Sender = btnRootFolder then
  begin
//    FileName := Trim(Utls.ShBrowseFolderDlg('Επιλέξτε φάκελο', [boOnlyDirs]));
    FileName := Trim(ShBrowseFolderDlg('Επιλέξτε φάκελο', [boOnlyDirs]));
    if Length(FileName) > 0 then
      edtRootFolder.Text := FileName;
  end else if Sender = btnExec then
  begin
    Execute();
  end else if Sender = btnAbort then
  begin
    if (FExecuting) then
    begin
      FExecuting := False;
    end;
  end;

end;
(*----------------------------------------------------------------------------*)
procedure TMainForm.Execute;
  {---------------------------------------------------}
  procedure ExecuteManager(ManagerClass: TInputManagerClass);
  var
    Manager: TInputManager;
  begin
    if not FExecuting then
      Exit;

    Manager               := ManagerClass.Create();
    if (Manager is TPurchaseManager) then
      TPurchaseManager(Manager).MonthsBefore := speMonthsBefore.Value;

    Log('START MANAGER: ' + Manager.Title + '-------------------------------------------');
    Manager.BasePath := edtRootFolder.Text;
    Manager.OnStep   := FileProcessor_OnStep;
    Manager.OnLog    := FileProcessor_OnLog;

    try
      try
        Manager.Start();
      except
        on E: Exception do
          Log(Format('ERROR: (%s) %s ',  [E.ClassName, E.Message]));
      end;
    finally
      Log('END MANAGER: ' + Manager.Title + '-------------------------------------------');
      Manager.Free;
    end;
  end;
  {---------------------------------------------------}
begin
  if not FExecuting then
  begin
    mmoLog.Clear();
    FExecuting := True;
    btnExec.Enabled := False;
    try
      if chPurchases.Checked then
        ExecuteManager(TPurchaseManager);

       //TODO: εδώ θα μπουν και οι άλλοι managers
    finally
      FExecuting  := False;
      btnExec.Enabled := True;
      ProgressBar.Position := 0;
    end;
  end;
end;
(*----------------------------------------------------------------------------*)
procedure TMainForm.FileProcessor_OnLog(Manager: TInputManager; Processor: TFileProcessor; Text: string);
begin
  Log(Format('Msg - [Processor: %s]: %s ', [Processor.Title, Text]));
end;
(*----------------------------------------------------------------------------*)
procedure TMainForm.FileProcessor_OnStep(Manager: TInputManager; Processor: TFileProcessor;  Status: TProcessorStatus);
begin
  case Status of
    psStart       : begin
                      Log('START PROC: ' + Processor.Title);
                      ProgressBar.Position := 0;
                      ProgressBar.Max := Processor.Total;
                    end;
    psProcessing  : begin
                      if not FExecuting then
                      begin
                        Manager.Abort();
                        Exit;
                      end;

                      ProgressBar.StepIt();

                      if Processor.ErrorMessage <> '' then
                      begin
                        Log(Processor.ErrorMessage);
                        Processor.ErrorMessage := '';
                      end;

                      Application.ProcessMessages();

                    end;
    psEnd         : begin
                      ProgressBar.Position := 0;
                      Log('END PROC: ' + Processor.Title);
                      Log(' ');
                    end;
  end;
end;

end.
