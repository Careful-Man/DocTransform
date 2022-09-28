unit o_Managers;

interface

uses
   Windows
  ,SysUtils
  ,Classes
  ,Controls
  ,Forms
  ,Contnrs
  ,ADODB
  ,Db
  ,MidasLib
  ,DbClient

//  ,Dialogs

  ,o_Descriptors
  ,uStringHandlingRoutines
//  ,tpk_Utls
    ;

type
  TProcessorStatus = (psStart, psProcessing, psEnd);

  TFileProcessor = class;
  TFileReader = class;
  TFileWriter = class;

  TInputManager = class;
  TInputManagerClass = class of TInputManager;

  TProcessorEvent = procedure(Manager: TInputManager; Processor: TFileProcessor; Status: TProcessorStatus)  of object;
  TLogEvent = procedure (Manager: TInputManager; Processor: TFileProcessor; Text: string) of object;
(*----------------------------------------------------------------------------*)
  { Τροχονόμος - Θα υπάρχουν διάφοροι απόγονοι ανάλογα
    με το αναμενόμενο input, πχ Αγορών, Πωλήσεων, Ενδοδιακίνησης κλπ. }
  TInputManager = class(TPersistent)
  private
    FReaderList       : TObjectList;
    FWriter           : TFileWriter;
    FIsProcessing     : Boolean;
    FBasePath         : string;
    FOnStep           : TProcessorEvent;
    FOnLog            : TLogEvent;
    FMasterSource     : TDatasource;
    FMasterTable      : TClientDataset;
    FDetailTable      : TClientDataset;

    FProcessCount     : Integer;
    FCanContinue      : Boolean;

    FCon              : TADOConnection;
    FSupplierTable    : TDataset;

    procedure Process();
    procedure SetBasePath(const Value: string);
    procedure DoStep(Status: TProcessorStatus; Processor: TFileProcessor);

  protected
    { ΠΡΟΣΟΧΗ: Αυτές οι τρεις μέθοδοι πρέπει να υλοποιηθούν σε ΚΑΘΕ απόγονο }
    procedure CreateReaders(List: TObjectList); virtual; abstract;
    function  CreateWriter: TFileWriter; virtual; abstract;
    procedure CompleteDatasetSchema(tblMaster, tblDetail: TDataset); virtual; abstract;

    function GetTitle: string; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Start;
    procedure Abort; // TODO:

    procedure Log(Processor: TFileProcessor; Text: string);

    function  Select(SqlText: string): TDataset;

    function  SelectSupplierMaterialDataset(SupplierCode: string): TDataset;

    function  GetMaterialMeasureUnitAA(MaterialAA: Integer; MeasUnitCode: string): Integer;
    function  IsDocSaved(SupCode: string; DocDate: TDate; RelDoc: string; GLN: Integer): Boolean;


    property IsProcessing  : Boolean read FIsProcessing;
    property CanContinue   : Boolean read FCanContinue;
    property BasePath      : string read FBasePath write SetBasePath;

    property OnStep        : TProcessorEvent read FOnStep write FOnStep;
    property OnLog         : TLogEvent read FOnLog write FOnLog;
    property Title         : string read GetTitle;

    property tblSupplier   : TDataset read FSupplierTable;
  end;

(*----------------------------------------------------------------------------*)
{ Η base class για Readers και Writers }
  TFileProcessor = class(TPersistent)
  protected
    FDescriptor  : TFileDescriptor;

    FTitle       : string;
    FTotal       : Integer;
    FCurrent     : Integer;
    FManager     : TInputManager;
    FErrorMessage: string;

    { ΠΡΟΣΟΧΗ: Εδώ γίνεται η κύρια επεξεργασία. Σε κάθε κύκλο πρέπει να
      τσεκάρεις την CanContinue για να δεις αν πρέπει να συνεχίσεις,
      μήπως και πάτησε ο χρήστης το Abort
      και σε κάθε κύκλο επίσης καλείς απαραίτητα την DoStep() }
    procedure Process(tblMaster, tblDetail: TDataset); virtual; abstract;
    procedure DoStep(Status: TProcessorStatus);

    //function  FindItemCode(SupplierItemCode: string): string;
  public
    constructor Create(Manager: TInputManager; Title: string); virtual;

    property Title        : string  read FTitle;
    property Total        : Integer read FTotal;
    property Current      : Integer read FCurrent;
    property ErrorMessage : string  read FErrorMessage write FErrorMessage;
  end;
(*----------------------------------------------------------------------------*)
  { διαβάζει από έναν κατάλογο και αν υπάρχει input
    το επεξεργάζεται, δημιουργεί μια λίστα πληροφοριών,
    και περιμένει έναν TFileWriter να πάρει τις πληροφορίες
    αυτές και να δημιουργήσει το output }
  TFileReader = class(TFileProcessor)
  public
    { ΠΡΟΣΟΧΗ: Μέσα στον Create() κάθε απογόνου, πρέπει να πας στο FileDescriptors
      και να κάνεις Find() τον περιγραφέα και να τον κρατήσεις σε κάποιο private πεδίο }
    constructor Create(Manager: TInputManager; Title: string); override;
  end;
(*----------------------------------------------------------------------------*)
  { Θα παίρνει πληροφορίες από έναν TFileReader
    και θα δημιουργεί το output }
  TFileWriter = class(TFileProcessor)
  end;



implementation

uses
  IniFiles
  ;


{ TFileProcessor }

constructor TFileProcessor.Create(Manager: TInputManager; Title: string);
begin
  inherited Create;
  FTitle := Title;
  FManager := Manager;
end;

procedure TFileProcessor.DoStep(Status: TProcessorStatus);
begin
  FManager.DoStep(Status, Self);
end;


(*
function TFileProcessor.FindItemCode(SupplierItemCode: string): string;
begin

end;
*)

{ TInputManager }

constructor TInputManager.Create;
begin
  inherited;

  FCon := TADOConnection.Create(nil);

  FReaderList := TObjectList.Create(True);

  CreateReaders(FReaderList);
  FWriter := CreateWriter();

  FMasterTable  := TClientDataSet.Create(nil);
  FDetailTable  := TClientDataset.Create(nil);

  FMasterSource := TDataSource.Create(nil);
  FMasterSource.DataSet := FMasterTable;

  FMasterTable.FieldDefs.Add('Id', ftAutoInc);
  FMasterTable.FieldDefs.Add('Flag', ftBoolean);   // μόνο οταν είναι True ο writer αναλαμβάνει να "γράψει" το παραστατικό

  FDetailTable.FieldDefs.Add('Id', ftAutoInc);
  FDetailTable.FieldDefs.Add('MasterId', ftInteger);

  CompleteDatasetSchema(FMasterTable, FDetailTable);

  {
     Table.FieldDefs.Add('Name', ftString, 32);
     Table.FeildDefs.Add('MyDate', ftDateTime);
  }

  FMasterTable.CreateDataSet();
  FDetailTable.CreateDataSet();

  FMasterTable.Active := True;
  FDetailTable.Active := True;

  FDetailTable.IndexFieldNames     := 'MasterId';
  FDetailTable.MasterFields        := 'Id';
  FDetailTable.MasterSource        := FMasterSource;

end;

destructor TInputManager.Destroy;
begin
  FreeAndNil(FSupplierTable);
  FreeAndNil(FCon);
  FreeAndNil(FDetailTable);
  FreeAndNil(FMasterTable);
  FreeAndNil(FMasterSource);
  FReaderList.Free;
  inherited;
end;

procedure TInputManager.DoStep(Status: TProcessorStatus; Processor: TFileProcessor);
begin
  if Assigned(FOnStep) then
    FOnStep(Self, Processor, Status);

  Inc(FProcessCount);

  if (FProcessCount mod 20 = 0) then
     Application.ProcessMessages();
end;
(*----------------------------------------------------------------------------*)
function TInputManager.GetTitle: string;
begin
  Result := '<κενό>';
end;
(*----------------------------------------------------------------------------*)
procedure TInputManager.SetBasePath(const Value: string);
begin
  if not FIsProcessing then
  begin
    FBasePath := Value;
  end;
end;
(*----------------------------------------------------------------------------*)
procedure TInputManager.Start;
 const
   CCS = 'Provider=SQLOLEDB.1;Password=yoda2k;Persist Security Info=True;User ID=sa;Initial Catalog=Afroditi;Data Source=localhost';
var
  SqlText : string;
  IniFileName: string;
  Ini : TIniFile;
  CS  : string;
  S   : string;
begin
  if not FIsProcessing then
  begin

//    IniFileName := Utls.AppPath + 'Main.ini';
    SetLength(S, 4096);
    SetLength(S, GetModuleFileName(HInstance, PChar(S), Length(S)));
    GetModuleFileName(HInstance, PChar(S), Length(S));
    IniFileName := ExtractFilePath(S) + 'Main.ini';
    Ini := TIniFile.Create(IniFileName);
    try
      CS := Ini.ReadString('Main', 'ConnectionString', '');
      if (CS = '') then
      begin
        CS := CCS;
        Ini.WriteString('Main', 'ConnectionString', CS);
      end;

      FCon.Connected := False;
      FCon.LoginPrompt := False;
      FCon.ConnectionString := CS;
      FCon.Connected := True;

    finally
      Ini.Free;
    end;

    FreeAndNil(FSupplierTable);

    SqlText := 'select PersonId, AFM from clroot.Supplier where TrdPersStat = 0 order by AFM';
    FSupplierTable := Select(SqlText);

    FCanContinue := True;
    Process();
  end;
end;
(*----------------------------------------------------------------------------*)
procedure TInputManager.Abort;
begin
  if FIsProcessing then
  begin
    FCanContinue := False;
  end;
end;
(*----------------------------------------------------------------------------*)
procedure TInputManager.Process;
var
  i : Integer;
begin
  FIsProcessing := True;
  try
    FProcessCount := 0;

    for i := 0 to FReaderList.Count - 1 do
      if CanContinue then
        TFileReader(FReaderList[i]).Process(FMasterTable, FDetailTable);

    if CanContinue then
      FWriter.Process(FMasterTable, FDetailTable);

  finally
    FIsProcessing := False;
  end;
end;

(*----------------------------------------------------------------------------*)
function TInputManager.Select(SqlText: string): TDataset;
var
  Q : TAdoQuery;
begin

  Q := TADOQuery.Create(nil);
  Q.Connection := FCon;
  Q.SQL.Text := SqlText;
  Q.Active := True;

  Result := Q;
end;

(*-----------------------------------------------------------------------------
 Επιστρέφει ένα dataset με τους Κωδικούς Είδους (δικούς μας και του προμηθευτή)
 το οποίο χρησιμεύει για lookup κωδικών είδους
-------------------------------------------------------------------------------*)
function TInputManager.SelectSupplierMaterialDataset(SupplierCode: string): TDataset;
const
  SupMatCodeSql =
'select                                             ' + LB +
'  m.AA   as MatAA                                  ' + LB +  // Material Id
' ,m.Code as MatCode                                ' + LB +
' ,IsNull(v.SupMatCode, ''XX'') as SupMatCode       ' + LB +
' ,v.SupplierCd as SupCode                          ' + LB +
//' ,e.TaxPrice                                       ' + LB +
'from                                               ' + LB +
'  clroot.Material m with (nolock)                  ' + LB +
'    join clroot.AltSupVi v on m.AA = v.MaterialAA  ' + LB +
//'    join clroot.ExtraTax e on m.ExtraTaxAA = e.AA  ' + LB +
'where                                              ' + LB +
'     v.SupplierCd = %s                             ' + LB +
'and  v.SupMatCode is not null                      ' + LB +
'';
var
  SqlText : string;
begin
//  SqlText := Format(SupMatCodeSql, [Utls.QS(SupplierCode)]);
  SqlText := Format(SupMatCodeSql, [QS(SupplierCode)]);
  Result := Select(SqlText);
end;


const
  cMaterialMeasureUnitAA =
'select                                                                      ' + LB +
'  clroot.MtrlMUnt.AA    as AA                                               ' + LB +
'from                                                                        ' + LB +
'  clroot.MtrlMUnt                                                           ' + LB +
'    join clroot.MeasUnit on clroot.MeasUnit.AA = clroot.MtrlMUnt.MUnitAA    ' + LB +
'where                                                                       ' + LB +
'       clroot.MtrlMUnt.MaterialAA = %d                                      ' + LB +
'   and clroot.MeasUnit.Code       = %s                                      ' + LB +
'';
(*----------------------------------------------------------------------------*)
function  TInputManager.GetMaterialMeasureUnitAA(MaterialAA: Integer; MeasUnitCode: string): Integer;
var
  SqlText: string;
  Table  : TDataset;
begin
  Result := -1;

//  SqlText := Format(cMaterialMeasureUnitAA, [MaterialAA, Utls.QS(MeasUnitCode)]);
  SqlText := Format(cMaterialMeasureUnitAA, [MaterialAA, QS(MeasUnitCode)]);
  Table := Select(SqlText);
  try
    if not Table.RecordCount = 1 then
      raise Exception.CreateFmt('Cannot retrieve MaterialMeasureUnitAA: MatAA %d, MeasUnitCode %s', [MaterialAA, MeasUnitCode]);
    Result := Table.FieldByName('AA').AsInteger;
  finally
    FreeAndNil(Table);
  end;

end;

const
  cSavedDocSql =
'select                            ' + LB +
'  count(Id) as Result             ' + LB +
'from                              ' + LB +
'  clroot.DocHdPur                 ' + LB +
'where                             ' + LB +
'      PersonId = %s               ' + LB +
'  and Date1 = %s                  ' + LB +
'  and AlterDoc like %s            ' + LB +
'  and WareHouseAA = %d            ' + LB +
'';

(*----------------------------------------------------------------------------*)
function TInputManager.IsDocSaved(SupCode: string; DocDate: TDate; RelDoc: string; GLN: Integer): Boolean;
var
  SqlText : string;
  Table   : TDataset;
begin
//  SqlText := Format(cSavedDocSql, [Utls.QS(SupCode), Utls.DateToStrSQL(DocDate, True), Utls.QS('%' + RelDoc), GLN]);
  SqlText := Format(cSavedDocSql, [QS(SupCode), DateToStrSQL(DocDate, True), QS('%' + RelDoc), GLN]);
//  ShowMessage(SqlText);
  Table := Select(SqlText);
  try
    Result := Table.Fields[0].AsInteger > 0;
  finally
    Table.Free;
  end;

end;

procedure TInputManager.Log(Processor: TFileProcessor; Text: string);
begin
  if (Assigned(FOnLog)) then
    FOnLog(Self, Processor, Text);
end;

{ TFileReader }

constructor TFileReader.Create(Manager: TInputManager; Title: string);
begin
  inherited;
  // πχ. FileDescriptors.Find('ονομα περιγραφέα');
end;

end.
