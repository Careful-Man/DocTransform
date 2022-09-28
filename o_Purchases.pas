(*
    if (not CanProcessDoc) then begin
        FManager.Log(Self, Format('WARNING: Document already exists. Line: %d, SupCode: %s, Date1: %s, RelDoc: %s %s, AX: %d',
                         [LineNumber, SupCode, Utls.DateToStrSQL(DocDate, False), DocTypeMap, sRelDoc, GlnId]))
*)

unit o_Purchases;

interface

uses
   Windows
  ,SysUtils
  ,Classes
  ,Controls
  ,Forms
  ,Contnrs
  ,Db
  ,ADODB
  ,MidasLib
  ,DbClient
  ,Variants
  ,IniFiles

  ,o_Managers
  ,o_Descriptors
  ,f_Main
  ;


(*
   ������� ��� �� ������� ���  TxxxReader
   �� �������� ��� �� ������ ��� ������ ��� �� �������
   �� ������������ �� ��� ����������

   ������ ������ �� ������� ��� static �����
   ��� Cache ����, ���� �� ������� TDataset
   ��� �� ��������� ��� select ���� database
   ����� �� �� ����������� ��� ��������������.

   ��� ������ �� ������� ��� ���� ���������.


*)

CONST
  NULL_STR   = '##null##';

type
(*----------------------------------------------------------------------------*)
  TPurchaseManager = class(TInputManager)
  private
    FMonthsBefore: Integer;
  protected
    { �������: ����� �� ����� ������� ������ �� ����������� �� ���� ������� }
    procedure CreateReaders(List: TObjectList); override;
    function  CreateWriter: TFileWriter; override;
    procedure CompleteDatasetSchema(tblMaster, tblDetail: TDataset); override;

    function GetTitle: string; override;
  public
    property MonthsBefore: Integer read FMonthsBefore write FMonthsBefore;

    function IsDocDateInValidRange(DT: TDate): Boolean;
   end;
(*----------------------------------------------------------------------------*)
  TPurchaseWriterDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
    destructor Destroy; override;
  end;
(*----------------------------------------------------------------------------*)
  TPurchaseWriter = class(TFileWriter)
  protected
    procedure Process(tblMaster, tblDetail: TDataset); override;
  public
    constructor Create(Manager: TInputManager; Title: string); override;
    destructor Destroy; override;
  end;
(*----------------------------------------------------------------------------*)
  TPurchaseReader = class(TFileReader)
  protected
    FInputPath        : string;
    FFileName         : string;

    FFileNameDetail   : string;

    tblMaterial       : TDataset;

    CanProcessDoc     : Boolean;
    Line              : string;
    DataList          : TStringList;
    ValueList         : TStringList;

    fiAFM             : TFileItem;
    fiDate            : TFileItem;
    fiDocType         : TFileItem;
    fiDocId           : TFileItem;
    fiDocChanger      : TFileItem;
    fiGLN             : TFileItem;    // GLN
    fiPayType         : TFileItem;

    fiCode            : TFileItem;
    fiQty             : TFileItem;
    fiPrice           : TFileItem;
    fiVAT             : TFileItem;
    fiVAT2            : TFileItem;
    fiDisc            : TFileItem;

    fiDisc2           : TFileItem;
    fiDisc3           : TFileItem;
//    fiSpecialTaxAlcohol  : TFileItem;
//    fiSpecialTaxRecycle  : TFileItem;



    fiLineValue       : TFileItem;
    fiBarcode         : TFileItem;
    fiMeasUnit        : TFileItem;

    fiMeasUnitRelation: TFileItem;

    FCon : TADOConnection;

    AFM               : string;
    SupCode           : string;
    GLN               : string;
    GlnId             : Integer;
    DocType           : string;
    DocDate           : TDate;
    RelDoc            : string;
    BarCode           : string;
    MatCode           : string;
    MatAA             : Integer;
    VATCode           : real;
    VATCode2          : real;

    DocNo             : string;
    LastDocNo         : string;
    LineKind          : TLineKind;
    LineIndex         : Integer;
    LastSupCode       : string;

    { �������� �� input ������ }
    procedure LoadFromFile(); virtual;

    { ���� ������ �������� ������ ��� ������� �� �� ������� merge }
{TODO: �� ������� ��� ��������� �� ��� ������������ ������� ��� merge,
       ���� �.�. ����� ������ (Raw), � �� �������� ��� ������ (NoDuplicates }
    procedure MergeFiles(FileList : TStringList); virtual;

    { standard ������ ����������� ��� ������� - ������ �� ��������� override }
    procedure Process(tblMaster, tblDetail: TDataset); override;
    procedure ProcessFile(tblMaster, tblDetail: TDataset);  virtual;
    procedure PrepareProcessFile(); virtual;

    { ������ �� ��������� override }
    function  CheckIsAborted: Boolean; virtual;
    function  CheckMasterCanContinue(LineNumber: Integer; sRelDoc, DocTypeMap: string): Boolean; virtual;
//    function  CheckDuplicateDoc(LineNumber: Integer; sRelDoc, DocTypeMap: string): Boolean; virtual;
    function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; virtual;
    function  GetCanProcessDoc(): Boolean; virtual;
    function  GetSupplierCode(AFM: string; var SupplierCode: string): Boolean; virtual;
    function  GetLineKind(PreviousLineKind: TLineKind): TLineKind; virtual;

    { overridables }
    function  ResolveGLN: Boolean; virtual;
    function  DocStrToDate(S: string): TDate; virtual;
    function  GetLineMarker(): string; virtual;

    { get ������� }
    function GetStrDef(FileItem: TFileItem; Default: string = ''): string; virtual;

    { get ����������� ��� �� ������ - master }
    function GetDocNo(): string; virtual;
    function GetDocType(): string; virtual;
    function GetDocTypeMap(): string; virtual;
    function GetAFM(): string; virtual;
    function GetRelDocNum(): string; virtual;
    function GetGLN(): string; virtual;
    function GetDocDate(): TDate; virtual;
    function GetPayType: string; virtual;

    { get ����������� ��� �� ������ - detail }
    function GetCode: string; virtual;
    function GetBarcode: string; virtual;
    function GetQty: Double; virtual;
    function GetMeasUnitRelation: integer; virtual;
    function GetPrice: Double; virtual;
    function GetVAT(MatCode: string): string; virtual;
    function GetDiscount: Double; virtual;
    function GetDiscount2: Double; virtual;
    function GetDiscount3: Double; virtual;
//    function GetSpecialTaxAlcohol: Double; virtual;
//    function GetSpecialTaxRecycle: Double; virtual;
    function GetLineValue: Double; virtual;
    function GetMeasUnitAA: Integer; virtual;

    { ������� ��� ��� datasets }
    procedure AddToMaster(tblMaster: TDataset); virtual;
    procedure AddToDetail(tblMaster: TDataset; tblDetail: TDataset); virtual;
  public
    constructor Create(Manager: TInputManager; Title: string); override;
    destructor Destroy; override;
    function Select(SqlText: string): TDataset;
  end;



implementation

uses
   StrUtils
//  ,tpk_Utls
  ,uStringHandlingRoutines

//  ,o_Agno
  ,o_Chipita
  ,o_CocaCola
  ,o_CretaFarm
  ,o_CretaNew
  ,o_Elbisco
  ,o_Amvrosiadis
  ,o_Asteriou
  ,o_Georgiadis
  ,o_Delta
//  ,o_Dianomi
//  ,o_Dianomi_Bingo
  ,o_Edesma
  ,o_Elgeka
  ,o_Kadoglou
  ,o_Karamolegos
  ,o_Kolios
  ,o_Kontzoglou
  ,o_Kore
  ,o_KriKri
  ,o_KriKriP
  ,o_Krios
  ,o_KriPap
  ,o_KriPapP
  ,o_Leivadopoulos
  ,o_Lykas
  ,o_Matina
  ,o_Mebgal
  ,o_Minas
  ,o_Moumtzis
  ,o_BarbaStathis
  ,o_Nedeltzidis
  ,o_Nikas
  ,o_Noulis
//  ,o_Nutriart
  ,o_Olympos
  ,o_Orizontes
  ,o_Papadopoulou
  ,o_Sergal
  ,o_Tsernos
  ,o_Yfantis
  ,o_FarmaKoukaki
  ,o_FarmesXoriou
  ,o_Xitos
  ,o_XatziGiannakidi
  ;


{ TPurchaseManager }
(*----------------------------------------------------------------------------*)
procedure TPurchaseManager.CompleteDatasetSchema(tblMaster, tblDetail: TDataset);
begin
  inherited;

  tblMaster.FieldDefs.Add('DocType', ftString, 12);                    //
  tblMaster.FieldDefs.Add('AFM', ftString, 12);                        // ��� ����������
  tblMaster.FieldDefs.Add('SupplierCode', ftString, 32);               // ������� ����������
  tblMaster.FieldDefs.Add('GLN', ftString, 8);                         // ������� ���������������
  tblMaster.FieldDefs.Add('Date', ftDate);
  tblMaster.FieldDefs.Add('RelDocId', ftString, 32);
  tblMaster.FieldDefs.Add('PayType', ftString, 22);

  tblDetail.FieldDefs.Add('MatAA', ftInteger);
  tblDetail.FieldDefs.Add('Code', ftString, 40);                       // ������� ������ (����� ���, ��� ��� ����������)
  tblDetail.FieldDefs.Add('Barcode', ftString, 40);
  tblDetail.FieldDefs.Add('MatMeasUnitAA', ftInteger);
  tblDetail.FieldDefs.Add('Qty', ftFloat);
  tblDetail.FieldDefs.Add('Price', ftFloat);
  tblDetail.FieldDefs.Add('VAT', ftFloat);                         // 13, 23 ���
  tblDetail.FieldDefs.Add('VAT2', ftFloat);                        // 13, 23 ���
  tblDetail.FieldDefs.Add('Disc', ftFloat);                       // ������ �������
  tblDetail.FieldDefs.Add('Disc2', ftFloat);                       // ������ �������
  tblDetail.FieldDefs.Add('Disc3', ftFloat);                       // ������ �������

//  tblDetail.FieldDefs.Add('SpecialTaxAlcohol', ftFloat);
//  tblDetail.FieldDefs.Add('SpecialTaxRecycle', ftFloat);

  tblDetail.FieldDefs.Add('LineValue', ftFloat);
end;
(*----------------------------------------------------------------------------*)
procedure TPurchaseManager.CreateReaders(List: TObjectList);
begin
  inherited;
//  List.Add(TAgnoReader.Create(Self,            '������ - ���� (reader)'));
          List.Add(TChipitaReader.Create(Self,         '������ - CHIPITA '));
          List.Add(TCocaColaReader.Create(Self,        '������ - COCA COLA '));
          List.Add(TCretaFarmReader.Create(Self,       '������ - CRETAFARM '));
          List.Add(TCretaNewReader.Create(Self,        '������ - CRETANEW '));
          List.Add(TElbiscoReader.Create(Self,         '������ - ELBISCO '));
          List.Add(TAmvrosiadisReader.Create(Self,     '������ - ����������� '));
          List.Add(TAsteriouReader.Create(Self,        '������ - �������� '));
          List.Add(TGeorgiadisReader.Create(Self,      '������ - ���������� '));
          List.Add(TDeltaReader.Create(Self,           '������ - ����� '));
//  List.Add(TDianomiReader.Create(Self,         '������ - ������� '));
//  List.Add(TDianomi_BingoReader.Create(Self,   '������ - �������_BINGO '));
          List.Add(TEdesmaReader.Create(Self,          '������ - ������ '));
          List.Add(TElgekaReader.Create(Self,          '������ - ������ '));
          List.Add(TKadoglouReader.Create(Self,        '������ - �������� '));
          List.Add(TKaramolegosReader.Create(Self,     '������ - ������������ '));
          List.Add(TKoliosReader.Create(Self,          '������ - ������ '));
          List.Add(TKontzoglouReader.Create(Self,      '������ - ���������� '));
          List.Add(TKoreReader.Create(Self,            '������ - ���� '));
          List.Add(TKriKriReader.Create(Self,          '������ - ������-� '));
          List.Add(TKriKriPReader.Create(Self,         '������ - ������-� '));
          List.Add(TKriosReader.Create(Self,           '������ - ����� '));
          List.Add(TKriPapReader.Create(Self,          '������ - ������-� '));
          List.Add(TKriPapPReader.Create(Self,         '������ - ������-� '));
          List.Add(TLeivadopoulosReader.Create(Self,   '������ - ������������� '));
          List.Add(TLykasReader.Create(Self,           '������ - ����� '));
          List.Add(TMatinaReader.Create(Self,          '������ - ������ '));
          List.Add(TMebgalReader.Create(Self,          '������ - ������ '));
          List.Add(TMinasReader.Create(Self,           '������ - ����� '));
          List.Add(TMoumtzisReader.Create(Self,        '������ - �������� '));
          List.Add(TBarbaStathisReader.Create(Self,    '������ - �������-������ '));
          List.Add(TNedeltzidisReader.Create(Self,     '������ - ����������� '));
          List.Add(TNikasReader.Create(Self,           '������ - ����� '));
          List.Add(TNoulisReader.Create(Self,          '������ - ������ '));
//  List.Add(TNutriartReader.Create(Self,        '������ - NUTRIART '));
          List.Add(TOlymposReader.Create(Self,         '������ - ������� '));
          List.Add(TOrizontesReader.Create(Self,       '������ - ��������� '));
        List.Add(TPapadopoulouReader.Create(Self,    '������ - ������������ '));
          List.Add(TSergalReader.Create(Self,          '������ - ������ '));
          List.Add(TTsernosReader.Create(Self,         '������ - ������� '));
          List.Add(TYfantisReader.Create(Self,         '������ - ������� '));
          List.Add(TFarmaKoukakiReader.Create(Self,    '������ - �����-������� '));
          List.Add(TFarmesXoriouReader.Create(Self,    '������ - ������-������ '));
        List.Add(TXitosReader.Create(Self,           '������ - ����� '));
          List.Add(TXatziGiannakidiReader.Create(Self, '������ - ��������������� '));
end;
(*----------------------------------------------------------------------------*)
function TPurchaseManager.CreateWriter: TFileWriter;
begin
  Result := TPurchaseWriter.Create(Self, '������ (writer)');
end;
(*----------------------------------------------------------------------------*)
function TPurchaseManager.GetTitle: string;
begin
  Result := '������';
end;
(*----------------------------------------------------------------------------*)
function TPurchaseManager.IsDocDateInValidRange(DT: TDate): Boolean;
var
  StartDate: TDate;
  Y, M, D: Word;
begin
  StartDate := SysUtils.Date;

  if (MonthsBefore > 0) then
    StartDate := SysUtils.IncMonth(StartDate, -MonthsBefore);

  DecodeDate(StartDate, Y, M, D);
  D := 1;
  StartDate := EncodeDate(Y, M, D);

  Result := DT >= StartDate;
end;









{ TPurchaseWriterDescriptor }
(*----------------------------------------------------------------------------*)
constructor TPurchaseWriterDescriptor.Create;
begin
  inherited;
  FName            := 'Writer.Purchases';
  FFileName        := 'Impact.txt';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'T1';
  FDetailMarker    := 'T2';
  FAFM             := '';
  FInitialEmpyLine := True;
end;
(*----------------------------------------------------------------------------*)
destructor TPurchaseWriterDescriptor.Destroy;
begin

  inherited;
end;
(*----------------------------------------------------------------------------*)
procedure TPurchaseWriterDescriptor.AddFileItems;
begin

  { master }
  FItemList.Add(TFileItem.Create(itGLN,      1, 4, 5));    // GLN
  FItemList.Add(TFileItem.Create(itDate,     1, 10, 8));
  FItemList.Add(TFileItem.Create(itDocType,  1, 19, 10));
  FItemList.Add(TFileItem.Create(itRelDoc,   1, 29, 8));
  FItemList.Add(TFileItem.Create(itSupCode,  1, 38, 10));
  FItemList.Add(TFileItem.Create(itAlterDoc, 1, 68, 18));

  { detail }
  FItemList.Add(TFileItem.Create(itCode,      2, 38, 6));                     // ����� lookup select
  FItemList.Add(TFileItem.Create(itBarcode,   2, 46, 13));
  FItemList.Add(TFileItem.Create(itQty,       2, 60, 8));
  FItemList.Add(TFileItem.Create(itPrice    , 2, 69 , 12));
  FItemList.Add(TFileItem.Create(itLineValue, 2, 117, 12));
  FItemList.Add(TFileItem.Create(itVAT,       2, 130, 2));                     // percent
  FItemList.Add(TFileItem.Create(itMeasUnit,  2, 135, 8));

//  FItemList.Add(TFileItem.Create(itPrice               , 2, 144 , 12));
  FItemList.Add(TFileItem.Create(itDisc                , 2, 157 , 12));
  //FItemList.Add(TFileItem.Create(itDisc2               , 2, 170 , 12));
  //FItemList.Add(TFileItem.Create(itDisc3               , 2, 183 , 12));
//  FItemList.Add(TFileItem.Create(itSpecialTax   , 2, 170 , 12));
  //FItemList.Add(TFileItem.Create(itSpecialTaxAlcohol   , 2, 196 , 12));
  //FItemList.Add(TFileItem.Create(itSpecialTaxRecycle   , 2, 209 , 12));

end;






{ TPurchaseWriter }
(*----------------------------------------------------------------------------*)
constructor TPurchaseWriter.Create(Manager: TInputManager; Title: string);
begin
  inherited;
  FDescriptor := TPurchaseWriterDescriptor.Create();
end;
(*----------------------------------------------------------------------------*)
destructor TPurchaseWriter.Destroy;
begin
  FreeAndNil(FDescriptor);
  inherited;
end;
(*----------------------------------------------------------------------------*)
procedure TPurchaseWriter.Process(tblMaster, tblDetail: TDataset);
  {-------------------------------------------------}
  function GetVatCategory(DT: TDate): string;
  begin
    if (DT < EncodeDate(2010, 3, 15)) then
      Result := '6'
    else if (DT < EncodeDate(2010, 7, 1)) then
      Result := '7'
    else if (DT < EncodeDate(2016, 6, 1)) then
      Result := '8'
    else
      Result := '0';
  end;
  {-------------------------------------------------}
var
  FilePath : string;
  List     : TStringList;            // DD/MM/YY
  Line     : string;
  SampleLine : string;
  S        : string;

  dValue   : Double;



  fiGLN      : TFileItem;
  fiDate     : TFileItem;
  fiDocType  : TFileItem;
  fiAlterDoc : TFileItem;
  fiSupCode  : TFileItem;
  fiRelDoc   : TFileItem;


  fiCode        : TFileItem;
  fiBarcode     : TFileItem;
  fiQty         : TFileItem;

  fiPrice  : TFileItem;
  fiDisc   : TFileItem;
  //fiDisc2  : TFileItem;
  //fiDisc3  : TFileItem;

//  fiSpecialTax : TFileItem;
  //fiSpecialTaxAlcohol : TFileItem;
  //fiSpecialTaxRecycle : TFileItem;

  fiLineValue        : TFileItem;
  fiMeasUnit         : TFileItem;
  fiMeasUnitRelation : TFileItem;
  fiVAT              : TFileItem;
begin
//  FilePath := Utls.NormalizePath(FManager.BasePath) + FDescriptor.FileName;
  FilePath := NormalizePath(FManager.BasePath) + FDescriptor.FileName;

  //Utls.CourierBox(FilePath);

  fiGLN      := FDescriptor.FindFileItem(itGLN        );
  fiDate     := FDescriptor.FindFileItem(itDate       );
  fiDocType  := FDescriptor.FindFileItem(itDocType    );
  fiRelDoc   := FDescriptor.FindFileItem(itRelDoc     );
  fiAlterDoc := FDescriptor.FindFileItem(itAlterDoc   );
  fiSupCode  := FDescriptor.FindFileItem(itSupCode    );


  fiBarcode  := FDescriptor.FindFileItem(itBarcode    );
  fiCode     := FDescriptor.FindFileItem(itCode       );
  fiQty      := FDescriptor.FindFileItem(itQty        );

  fiPrice    := FDescriptor.FindFileItem(itPrice      );
  fiDisc     := FDescriptor.FindFileItem(itDisc       );
  //fiDisc2  := FDescriptor.FindFileItem(itDisc2  );
  //fiDisc3  := FDescriptor.FindFileItem(itDisc3  );

//  fiSpecialTax  := FDescriptor.FindFileItem(itSpecialTax  );
  //fiSpecialTaxAlcohol  := FDescriptor.FindFileItem(itSpecialTaxAlcohol  );
  //fiSpecialTaxRecycle  := FDescriptor.FindFileItem(itSpecialTaxRecycle  );

  fiLineValue         := FDescriptor.FindFileItem(itLineValue );
  fiMeasUnit          := FDescriptor.FindFileItem(itMeasUnit  );
  fiMeasUnitRelation  := FDescriptor.FindFileItem(itMeasUnitRelation  );
  fiVAT               := FDescriptor.FindFileItem(itVAT       );

  tblMaster.First;

  List := TStringList.Create;
  try
    while not tblMaster.Eof do
    begin
      { �� �� Flag ����� False ���� ��� ������ �� ������������� �� ����������.
        �� Flag ����� False ���� ������������ ��� ��������� ����� }
      if (tblMaster.FieldByName('Flag').AsBoolean) then
      begin
        List.Add('');

        Line        := 'T1' + StringOfChar(' ', 116);
        SampleLine  := 'T2' + StringOfChar(' ', 240);

//        S := Utls.StrPadLeft(tblMaster.FieldByName('GLN').AsString, '0', fiGLN.Length);
        S := StrPadLeft(tblMaster.FieldByName('GLN').AsString, '0', fiGLN.Length);
        Line := StuffString(Line, fiGLN.Position, Length(S), S);
        SampleLine := StuffString(SampleLine, fiGLN.Position, Length(S), S);

        S := FormatDateTime('DD/MM/YY', tblMaster.FieldByName('Date').AsDateTime);
        Line := StuffString(Line, fiDate.Position, Length(S), S);
        SampleLine := StuffString(SampleLine, fiDate.Position, Length(S), S);

//        S := Utls.StrPadLeft(tblMaster.FieldByName('DocType').AsString, ' ', fiDocType.Length);
        S := StrPadLeft(tblMaster.FieldByName('DocType').AsString, ' ', fiDocType.Length);
        Line := StuffString(Line, fiDocType.Position, Length(S), S);
        SampleLine := StuffString(SampleLine, fiDocType.Position, Length(S), S);

//        S := Utls.StrPadRight(tblMaster.FieldByName('RelDocId').AsString, ' ', fiRelDoc.Length);
        S := StrPadRight(tblMaster.FieldByName('RelDocId').AsString, ' ', fiRelDoc.Length);
        Line := StuffString(Line, fiRelDoc.Position, Length(S), S);
        SampleLine := StuffString(SampleLine, fiRelDoc.Position, Length(S), S);

//        S := Utls.StrPadLeft(tblMaster.FieldByName('DocType').AsString, ' ', fiDocType.Length)
//             + Utls.StrPadRight(tblMaster.FieldByName('RelDocId').AsString, ' ', fiRelDoc.Length);
        S := StrPadLeft(tblMaster.FieldByName('DocType').AsString, ' ', fiDocType.Length)
             + StrPadRight(tblMaster.FieldByName('RelDocId').AsString, ' ', fiRelDoc.Length);
        Line := StuffString(Line, fiAlterDoc.Position, Length(S), S);

//        S := Utls.StrPadLeft(tblMaster.FieldByName('SupplierCode').AsString, ' ', fiSupCode.Length);
        S := StrPadLeft(tblMaster.FieldByName('SupplierCode').AsString, ' ', fiSupCode.Length);
        Line := StuffString(Line, fiSupCode.Position, Length(S), S);

//        S := Utls.StrPadLeft(GetVatCategory(tblMaster.FieldByName('Date').AsDateTime), ' ', 2);
        S := StrPadLeft(GetVatCategory(tblMaster.FieldByName('Date').AsDateTime), ' ', 2);
        Line := StuffString(Line, 117, Length(S), S);

        List.Add(Line);

        tblDetail.First;
        while not tblDetail.Eof do
        begin
          //SampleLine  := 'T2' + StringOfChar(' ', 149);
          Line := SampleLine;

//          S := Utls.StrPadLeft(tblDetail.FieldByName('Code').AsString, ' ', fiCode.Length);
          S := StrPadLeft(tblDetail.FieldByName('Code').AsString, ' ', fiCode.Length);
          Line := StuffString(Line, fiCode.Position, Length(S), S);

//          S := Utls.StrPadLeft(tblDetail.FieldByName('Barcode').AsString, ' ', fiBarcode.Length);
          S := StrPadLeft(tblDetail.FieldByName('Barcode').AsString, ' ', fiBarcode.Length);
          Line := StuffString(Line, fiBarcode.Position, Length(S), S);

//          S := Utls.CommaToDot(FormatFloat('000#.000', tblDetail.FieldByName('Qty').AsFloat));
          S := CommaToDot(FormatFloat('000#.000', tblDetail.FieldByName('Qty').AsFloat));
          Line := StuffString(Line, fiQty.Position, Length(S), S);

//          S := Utls.CommaToDot(FormatFloat('00000000#.00', tblDetail.FieldByName('LineValue').AsFloat));
          S := CommaToDot(FormatFloat('00000000#.00', tblDetail.FieldByName('LineValue').AsFloat));
          Line := StuffString(Line, fiLineValue.Position, Length(S), S);

//          S := Utls.StrPadLeft(tblDetail.FieldByName('VAT').AsString, '0', fiVAT.Length);
          S := StrPadLeft(tblDetail.FieldByName('VAT').AsString, '0', fiVAT.Length);
          Line := StuffString(Line, fiVAT.Position, Length(S), S);

//          S := Utls.StrPadLeft(tblDetail.FieldByName('MatMeasUnitAA').AsString, '0', fiMeasUnit.Length);
          S := StrPadLeft(tblDetail.FieldByName('MatMeasUnitAA').AsString, '0', fiMeasUnit.Length);
          Line := StuffString(Line, fiMeasUnit.Position, Length(S), S);

          //////////////////////////////////////////////////////////////////////////////////
//          S := Utls.CommaToDot(FormatFloat('00000000#.00', tblDetail.FieldByName('Price').AsFloat));
          S := CommaToDot(FormatFloat('00000000#.00', tblDetail.FieldByName('Price').AsFloat));
          Line := StuffString(Line,   fiPrice.Position, Length(S), S);

          dValue := tblDetail.FieldByName('Disc').AsFloat +
                    tblDetail.FieldByName('Disc2').AsFloat +
                    tblDetail.FieldByName('Disc3').AsFloat;

//          S := Utls.CommaToDot(FormatFloat('00000000#.00', dValue));
          S := CommaToDot(FormatFloat('00000000#.00', dValue));
          Line := StuffString(Line,   fiDisc.Position, Length(S), S);

          //S := Utls.CommaToDot(FormatFloat('00000000#.00', tblDetail.FieldByName('Disc2').AsFloat));
          //Line := StuffString(Line,   fiDisc2.Position, Length(S), S);

          //S := Utls.CommaToDot(FormatFloat('00000000#.00', tblDetail.FieldByName('Disc3').AsFloat));
          //Line := StuffString(Line,   fiDisc3.Position, Length(S), S);


//          dValue := tblDetail.FieldByName('SpecialTaxAlcohol').AsFloat +
//                    tblDetail.FieldByName('SpecialTaxRecycle').AsFloat;

//          S := Utls.CommaToDot(FormatFloat('00000000#.00', dValue));
//          Line := StuffString(Line,   fiSpecialTax.Position, Length(S), S);

          //S := Utls.CommaToDot(FormatFloat('00000000#.00', tblDetail.FieldByName('SpecialTaxAlcohol').AsFloat));
          //Line := StuffString(Line,   fiSpecialTaxAlcohol.Position, Length(S), S);

          //S := Utls.CommaToDot(FormatFloat('00000000#.00', tblDetail.FieldByName('SpecialTaxRecycle').AsFloat));
          //Line := StuffString(Line,   fiSpecialTaxRecycle.Position, Length(S), S);


          List.Add(Line);

          tblDetail.Next;
        end;
      end;


      tblMaster.Next;
    end;
    List.SaveToFile(FilePath);
  finally
    List.Free;
  end;


end;
















{ TPurchaseReader }
(*----------------------------------------------------------------------------*)
constructor TPurchaseReader.Create(Manager: TInputManager; Title: string);
begin
  inherited;
  DataList := TStringList.Create;
end;
(*----------------------------------------------------------------------------*)
destructor TPurchaseReader.Destroy;
begin
  FreeAndNil(DataList);
  FreeAndNil(ValueList);
  inherited;
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.CheckIsAborted: Boolean;
begin
  if not FManager.CanContinue then
  begin
    FManager.Log(Self, 'Aborted by the user');
    Result := True;
  end else begin
    DoStep(psProcessing);
    Result := False;
  end;
end;
(*-----------------------------------------------------------------------------
  Lookup. ���������� �� ���� �� ��� ��� ������ ����������
-------------------------------------------------------------------------------*)
function TPurchaseReader.GetSupplierCode(AFM: string; var SupplierCode: string): Boolean;
begin
  SupplierCode := '';

  Result := FManager.tblSupplier.Locate('AFM', AFM, []);

  if not Result then
    //raise Exception.CreateFmt('Supplier code not found. AFM: %s', [AFM])
    FManager.Log(Self, Format('   ERROR: Supplier code not found. AFM: %s - Line: %d', [AFM, LineIndex + 1]))
  else
    SupplierCode := FManager.tblSupplier.FieldByName('PersonId').AsString;
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.Select(SqlText: string): TDataset;
var
  Q : TAdoQuery;
begin

  Q := TADOQuery.Create(nil);
  Q.Connection := FCon;
  Q.SQL.Text := SqlText;
  Q.Active := True;

  Result := Q;
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.DocStrToDate(S: string): TDate;
var
  DT: TDateTime;
begin
  if TryStrToDate(S, DT) then
    Result := DT
  else
    Result := SysUtils.Date;
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetCanProcessDoc: Boolean;
begin
  Result := FDescriptor.DocTypeMap.IndexOfName(DocType) <> -1;
end;
(*----------------------------------------------------------------------------*)
function  TPurchaseReader.GetLineMarker(): string;
begin
  Result := '';

  if (FDescriptor.SeparationMode = smMarker) then
  begin
    if (FDescriptor.Kind = fkDelimited) then
      Result := Trim(ValueList[0])
    else if (FDescriptor.Kind = fkFixedLength) then
      Result := Trim(DataList[LineIndex])[1];
  end;
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetLineKind(PreviousLineKind: TLineKind): TLineKind;
var
  Line : string;
  Marker : string;
begin


  Result := lkNone;

  case FDescriptor.Schema of
    fsHeaderDetail : case FDescriptor.SeparationMode of
                       smEmptyLine : begin
                                       Line := Trim(DataList[LineIndex]);

                                       if ((PreviousLineKind = lkNone) or (PreviousLineKind = lkOnDetailLine)) then
                                       begin
                                         if Length(Line) <= 0 then
                                           Result := lkOnEmptyLine
                                         else
                                           Result := lkOnDetailLine;
                                       end else if (PreviousLineKind = lkOnEmptyLine) then
                                       begin
                                         if Length(Line) > 0 then
                                           Result := lkOnMasterLine;
                                       end else if (PreviousLineKind = lkOnMasterLine) then
                                       begin
                                         if Length(Line) > 0 then
                                           Result := lkOnDetailLine;
                                       end;
                                     end;

                       smMarker    : begin // �������� ��� ��� ������ �� ������� �� ���� ������
                                       Line := Trim(DataList[LineIndex]);

                                       Marker := GetLineMarker();

                                       if (Marker = FDescriptor.MasterMarker) then
                                         Result := lkOnMasterLine
                                       else if (Marker = FDescriptor.DetailMarker) then
                                         Result := lkOnDetailLine
                                       else if Length(Line) <= 0 then
                                           Result := lkOnEmptyLine;

                                     end;
                     end;


    fsSameLine     : begin // �������� ��� ��� ������ �� ������� �� ���� ������
                       if (fiDocChanger <> nil) then
                       begin
                         DocNo := GetDocNo();

                         if (DocNo <> '') and ((PreviousLineKind = lkNone) or (DocNo <> LastDocNo) )  then
                         begin
                           Result    := lkOnMasterLine;
                           LastDocNo := DocNo;
                         end else if (DocNo <> '') and (DocNo = LastDocNo) then
                           Result := lkOnDetailLine;

                       end;
                     end;

  end;




end;

(*----------------------------------------------------------------------------*)
procedure TPurchaseReader.LoadFromFile();
//var
//  SrcText: PWideChar;
//  DstText: PAnsiChar;
begin
  DataList.LoadFromFile(FFileName);

  if (FDescriptor.IsOem) then
//    DataList.Text := Utls.OemToAnsi(DataList.Text)
    DataList.Text := OemToAnsi(DataList.Text)
  else if (FDescriptor.IsUnicode) then
    DataList.Text := UTF8ToANSI(DataList.Text);
//  else if (FDescriptor.IsANSI) then begin
//    SrcText := PWideChar(DataList.Text);
//    CharToOem(SrcText, DstText);
//    DataList.Text := AnsiToOEM(DstText);
//  end;

  FTotal := DataList.Count;
end;
(*----------------------------------------------------------------------------
 ������ ��� �� ����������� fiXXXX ������ �� ����� nil
 ��� ��� ��� ���������������� ��� ��� ����� ���� �����������
----------------------------------------------------------------------------*)
procedure TPurchaseReader.PrepareProcessFile;
begin
  fiAFM          := FDescriptor.FindFileItem(itAFM          );
  fiDate         := FDescriptor.FindFileItem(itDate         );
  fiDocType      := FDescriptor.FindFileItem(itDocType      );

  fiDocId        := FDescriptor.FindFileItem(itDocId        );
  fiDocChanger   := FDescriptor.FindFileItem(itDocChanger   );


  fiGLN          := FDescriptor.FindFileItem(itGLN          );
  fiPayType      := FDescriptor.FindFileItem(itPayType      );

  fiBarCode      := FDescriptor.FindFileItem(itBarCode      );
  fiCode         := FDescriptor.FindFileItem(itCode         );
  fiQty          := FDescriptor.FindFileItem(itQty          );
  fiPrice        := FDescriptor.FindFileItem(itPrice        );
  fiVAT          := FDescriptor.FindFileItem(itVAT          );
  fiVAT2         := FDescriptor.FindFileItem(itVAT2         );

  fiDisc         := FDescriptor.FindFileItem(itDisc         );
  fiDisc2        := FDescriptor.FindFileItem(itDisc2        );
  fiDisc3        := FDescriptor.FindFileItem(itDisc3        );

//  fiSpecialTaxAlcohol  := FDescriptor.FindFileItem(itSpecialTaxAlcohol  );
//  fiSpecialTaxRecycle  := FDescriptor.FindFileItem(itSpecialTaxRecycle  );


  fiLineValue        := FDescriptor.FindFileItem(itLineValue    );
  fiMeasUnit         := FDescriptor.FindFileItem(itMeasUnit     );

  fiMeasUnitRelation := FDescriptor.FindFileItem(itMeasUnitRelation     );

end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.ResolveGLN: Boolean;
var
  Index : Integer;
  S : string;
begin


  if (FDescriptor.NeedsMapGln) then
  begin
    Index  := FDescriptor.GLNMap.IndexOfName(GLN);
    Result := Index <> -1;
    if Result then
    begin
      S      := FDescriptor.GLNMap.Values[GLN];
      Result := TryStrToInt(S, GlnId);
    end;
  end else begin
    Result := TryStrToInt(GLN, GlnId);
  end;

end;
(*----------------------------------------------------------------------------
�������� ������� ��� �������� ���� ������ ���������� ��� �� �� ��������
�� ������������� �� �����������.
----------------------------------------------------------------------------*)
function TPurchaseReader.CheckMasterCanContinue(LineNumber: Integer; sRelDoc, DocTypeMap: string ): Boolean;
begin

  CanProcessDoc := (FManager as TPurchaseManager).IsDocDateInValidRange(DocDate);

  if (not CanProcessDoc) then
  begin
    FManager.Log(Self, Format('ERROR: DocDate is out of range. Line: %d, RelDoc: %s %s, AFM: %s, DocDate: %s', [LineNumber, DocTypeMap, sRelDoc, AFM, DateToStr(DocDate)]));
    Result := False;
    Exit;
  end;


  CanProcessDoc := ResolveGLN();

  if not CanProcessDoc then
  begin
    Result := False;
    FManager.Log(Self, Format('ERROR: WareHouse not found. Line: %d, RelDoc: %s %s, AFM: %s', [LineNumber, DocTypeMap, sRelDoc, AFM]));
    //Continue;  // skip detail lines and go to the next master line


  end else begin
    Result := True;

    CanProcessDoc := not FManager.IsDocSaved(SupCode, DocDate, DocTypeMap + sRelDoc, GlnId);

    if (not CanProcessDoc) then begin
      if MainForm.CheckBox1.Checked = True then
//        FManager.Log(Self, Format('WARNING: Document already exists. Line: %4d, SupCode: %10s, Date1: %10s, RelDoc: %5s %-10s, AX: %2d',
//                         [LineNumber, SupCode, Utls.DateToStrSQL(DocDate, False), DocTypeMap, sRelDoc, GlnId]))
        FManager.Log(Self, Format('WARNING: Document already exists. Line: %4d, SupCode: %10s, Date1: %10s, RelDoc: %5s %-10s, AX: %2d',
                         [LineNumber, SupCode, DateToStrSQL(DocDate, False), DocTypeMap, sRelDoc, GlnId]))

    end
    else
//      FManager.Log(Self, Format('New document. Line: %4d, SupCode: %10s, Date1: %10s, RelDoc: %5s %-10s, AX: %2d',
//                         [LineNumber, SupCode, Utls.DateToStrSQL(DocDate, False), DocTypeMap, sRelDoc, GlnId]));
      FManager.Log(Self, Format('New document. Line: %4d, SupCode: %10s, Date1: %10s, RelDoc: %5s %-10s, AX: %2d',
                         [LineNumber, SupCode, DateToStrSQL(DocDate, False), DocTypeMap, sRelDoc, GlnId]));

// ��� �������� �� ��� �������� �� ����������� ��� ������� �������� �������.
// ���� ��� ����� ���� ����������� �� ������������ �� �����������,
// ������ ��� ������������ �� ������������ ��� ��� �.�. 99.
  if CanProcessDoc = True then begin

    if GlnId <> 99 then
      CanProcessDoc := True
    else
      CanProcessDoc := (GlnId = 99) and (MainForm.CheckBox2.Checked = True);

    if not CanProcessDoc then
    begin
      Result := False;
      FManager.Log(Self, Format('ERROR: WareHouse = 99 and disallowed. Line: %d, RelDoc: %s %s, AFM: %s', [LineNumber, DocTypeMap, sRelDoc, AFM]));
    end;

  end;


end;


end;
(*-----------------------------------------------------------------------------
 Lookup. ������� ��� ������ ������ ��� ���������� ��� ��������� ��� ���� ���
 ������ ������. �� tblMaterial ���������� ��� SELECT ��� ������� ���� reader
 ���� ������� �� �������� �� ������ ��� ������� � ����������� ��� ����������
 ��� ��� SelectSupplierMaterialDataset()
-------------------------------------------------------------------------------*)
function  TPurchaseReader.GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
begin
  Result := False;

  MatCode := '';
  MatAA   := -1;

  if tblMaterial.Locate('SupMatCode;SupCode', VarArrayOf([SupMatCode, SupCode]), []) then
  begin
    MatCode := tblMaterial.FieldByName('MatCode').AsString;
    MatAA   := tblMaterial.FieldByName('MatAA').AsInteger;

    Result := True;
  end;


  if not Result then
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %10s, Date1: %10s, RelDoc: %5s, %-10s, SupMatCode: %-10s',
//                   [SupCode, Utls.DateToStrSQL(DocDate, False), SupMatCode, RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %10s, Date1: %10s, RelDoc: %5s, %-10s, SupMatCode: %-10s',
                   [SupCode, DateToStrSQL(DocDate, False), SupMatCode, RelDoc, SupMatCode]));

end;
(*----------------------------------------------------------------------------*)
procedure TPurchaseReader.MergeFiles(FileList : TStringList);
var
  OutFile : TextFile;
  i       : Integer;
  j       : Integer;
  s       : string;
  tmpList : TStringList;
  OutList : TStringList;
begin
  tmpList := TStringList.Create;
  OutList := TStringList.Create;
  try
    AssignFile(OutFile, FDescriptor.FileName);
    for i := 0 to FileList.Count - 1 do
    begin
      tmpList.Clear;
      tmpList.LoadFromFile(FileList[i]);
// ����� ��� �� ����� ����������� ����� ��� ���������� ��������.
//      if i > 0 then
        OutList.Add('');
      for j := 0 to tmpList.Count - 1 do
      begin
//        s := Utls.UnicodeToAnsi(tmpList[j]);
        s := tmpList[j];
        OutList.Add(s);
      end;
    end;
    OutList.SaveToFile(FInputPath + ExtractFileName(FDescriptor.FileName));
  finally
    tmpList.Free;
    OutList.Free;
  end;
end;
(*----------------------------------------------------------------------------*)
procedure TPurchaseReader.Process(tblMaster, tblDetail: TDataset);
var
  FileList  : TStringList;
  i         : Integer;
begin

//  FInputPath := Utls.NormalizePath(FManager.BasePath) + FDescriptor.FileName;
  FInputPath := NormalizePath(FManager.BasePath) + FDescriptor.FileName;
  FFileName  := ExtractFileName(FInputPath);
  FInputPath := ExtractFilePath(FInputPath);

  { Needs Create first, Clear later }
  FileList  := TStringList.Create;

  { Merging }
  if FDescriptor.NeedsFileMerge = True then
  begin
//    Utls.FindFiles(FInputPath, FDescriptor.FileMask, FileList, True, False);
    FindFiles(FInputPath, FDescriptor.FileMask, FileList, True, False);
    MergeFiles(FileList);
  end;

//  FileList  := TStringList.Create;
  FileList.Clear;
  try
//     Utls.FindFiles(FInputPath, FFileName, FileList, True, False);
     FindFiles(FInputPath, FFileName, FileList, True, False);

     for i := 0 to FileList.Count - 1 do
     begin
       if CheckIsAborted() then
       begin
         FManager.Log(Self, 'Aborted by the user');
         Break;
       end else begin
         FFileName := FileList[i];
         FManager.Log(Self, 'Start processing file: ' + FFileName);
         LoadFromFile();
         DoStep(psStart);
         ProcessFile(tblMaster, tblDetail);
       end;
     end;

  finally
    FileList.Free;
    DoStep(psEnd);
  end;

end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetStrDef(FileItem: TFileItem; Default: string = ''): string;
begin
  Result := Default;

  if (FileItem <> nil) then
  begin
    if (FDescriptor.Kind = fkDelimited) then
      Result := Trim(ValueList[FileItem.Position])
    else  // fkFixedLength
      Result := Trim(Copy(DataList[LineIndex], FileItem.Position, FileItem.Length));

    if (Result = '') then
      Result := Default;
  end;
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetDocNo: string;
begin
  Result := GetStrDef(fiDocChanger);
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetDocType: string;
begin
  Result := GetStrDef(fiDocType);
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetDocTypeMap: string;
begin
  Result := FDescriptor.DocTypeMap.Values[DocType];
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetAFM: string;
begin
  if (not FDescriptor.IsMultiSupplier) then
    Result := FDescriptor.AFM
  else
    Result := GetStrDef(fiAFM);
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetRelDocNum(): string;
var
  Len : Integer;         // 02��� 1326006552
  S : string;
begin
  Result := '';
  S      := GetStrDef(fiDocId);

  Len    := Length(S);

  while Len > 0 do
  begin
    if (S[Len] in ['0'..'9']) then
      Result := S[Len] + Result
    else
      break;
    Len := Len - 1;
  end;

//  if Length(S) > 0 then
//  begin
    while Result[1] = '0' do
    begin
      if (Length(Result) = 1) then
        Exit;
      Delete(Result, 1, 1);
    end;
//  end;
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetGLN: string;
begin
  Result := GetStrDef(fiGLN);
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetDocDate(): TDate;
begin
  if (FDescriptor.Kind = fkDelimited) then
      Result := DocStrToDate(Trim(ValueList[fiDate.Position]))
  else  // fkFixedLength
      Result := DocStrToDate(Copy(DataList[LineIndex], fiDate.Position, fiDate.Length));
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetPayType: string;
begin
  if (FDescriptor.NeedsMapPayMode) then
  begin
    Result := GetStrDef(fiPayType);

    if (FDescriptor.PayModeMap.IndexOfName(Result) = -1) then
      raise Exception.CreateFmt('Invalid PayType. Map not found: %s', [Result]);

    Result :=  FDescriptor.PayModeMap.Values[Result];
  end else begin
    Result :=  '��� �������';
  end;
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetCode: string;
begin
  Result := GetStrDef(fiCode);
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetBarcode: string;
begin
  Result := GetStrDef(fiBarcode);

  if (Result <> '') then
//    Result := Utls.StrPadRight(Result, '0', 13) ;
    Result := StrPadRight(Result, '0', 13) ;
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetQty: Double;
var
  S : string;
begin
  S := GetStrDef(fiQty, '0');
//  S := Utls.CommaToDot(S);
//  Result := StrToFloat(S, Utls.GlobalFormatSettings);
//  S := CommaToDot(S);
  S := DotToComma(S);
//  Result := StrToFloat(S, GlobalFormatSettings);
  Result := StrToFloat(S);
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetMeasUnitRelation: integer;
var
  S : string;
  F : real;
begin
  S := GetStrDef(fiMeasUnitRelation, '0');
//  S := Utls.CommaToDot(S);
//  Result := StrToFloat(S, Utls.GlobalFormatSettings);
//  S := CommaToDot(S);
  S := DotToComma(S);
//  Result := StrToFloat(S, GlobalFormatSettings);
  F := StrToFloat(S);
  Result := Trunc(F);
//  Result := StrToInt(S);
end;
(*----------------------------------------------------------------------------*)
(*

*)
function TPurchaseReader.GetPrice: Double;

  function GetHistoryPrice(MatAA: integer): Double;
  const
    CCS = 'Provider=SQLOLEDB.1;Password=yoda2k;Persist Security Info=True;User ID=sa;Initial Catalog=Afroditi;Data Source=localhost';
  var
    SqlText    : string;
    IniFileName: string;
    Ini        : TIniFile;
    CS         : string;
    Prices     : TDataset;
    APrice     : Double;
    S          : string;
  begin
    SetLength(S, 4096);
    SetLength(S, GetModuleFileName(HInstance, PChar(S), Length(S)));
    GetModuleFileName(HInstance, PChar(S), Length(S));
    IniFileName := ExtractFilePath(S) + 'Main.ini';
    Ini         := TIniFile.Create(IniFileName);
    try
      CS        := Ini.ReadString('Main', 'ConnectionString', '');
      if (CS = '') then
      begin
        CS := CCS;
        Ini.WriteString('Main', 'ConnectionString', CS);
      end;
    FCon                  := TADOConnection.Create(nil);
    FCon.Connected        := False;
    FCon.LoginPrompt      := False;
    FCon.ConnectionString := CS;
    FCon.Connected        := True;
    finally
      Ini.Free;
    end;
    SqlText := 'select top 1 d.Date1, l.Price' + LB +
               'from clroot.DocHdPur d with (nolock) join clroot.LItmPurc l with (nolock) on d.AA = l.DocumentAA' + LB +
               'where l.LinkIDNum = ' + IntToStr(MatAA) + LB +
               'and d.SeriesCode in (''���'', ''���'')' + LB +
               'and l.Price <> 0.00' + LB +
               'order by d.Date1 desc';
    Prices := Select(SqlText);
    Prices.Open;
    APrice := Prices.FieldByName('Price').AsFloat;
    Result := APrice;
    FreeAndNil(FCon);
    FreeAndNil(Prices);
  end;

var
  S : string;
//  R : double;
begin
  S := GetStrDef(fiPrice, '0');
  S := DotToComma(S);
// ��� ������� ��� ��� �� � ���� ������� ����� 0
//  if StrToFloat(S) = 0 then
//  begin
//    R := GetHistoryPrice(MatAA);
//    S := FloatToStr(R);
//    S := DotToComma(S);
//  end;
  Result := StrToFloat(S);
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetVAT(MatCode: string): string;
 const
   CCS = 'Provider=SQLOLEDB.1;Password=yoda2k;Persist Security Info=True;User ID=sa;Initial Catalog=Afroditi;Data Source=localhost';
 var
  SqlText : string;
  IniFileName: string;
  Ini : TIniFile;
  CS  : string;
  S   : string;
  VATCat : TDataset;
  VATVal : Double;
  TaxCat : string;
begin
  Result := GetStrDef(fiVAT);
  if (Result = '') or (Result = '0.00') then begin
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
      FCon := TADOConnection.Create(nil);
      FCon.Connected := False;
      FCon.LoginPrompt := False;
      FCon.ConnectionString := CS;
      FCon.Connected := True;
    finally
      Ini.Free;
    end;
    if DocDate < StrToDateTime('01/06/2016 00:00:00') then
      TaxCat := '8'
    else
      TaxCat := '0';
    SqlText := 'Select v.VATVal, m.String11 '                                                        + LB +
               'from clroot.InvVAT v join clroot.Material m with (nolock) on v.VATCtgr = m.VATCtgr'  + LB +
               'where m.Code = ' + MatCode +  LB +
               'and v.TaxCat = ' + TaxCat;
    VATCat := Select(SqlText);
    VATCat.Open;
    VATVal := VATCat.FieldByName('VATVal').AsFloat;
// If Material is changing VAT and DocDate is from 20/05 onwards, VAT becomes 13% instead of 24%.
    if ((VATCat.FieldByName('String11').AsString = '24->13a') and (DocDate >= 2019-05-20)) then
      VATVal := 13.0;

    Result := FloatToStr(VATVal);
    FreeAndNil(FCon);
    FreeAndNil(VATCat);
  end;
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetDiscount: Double;
var
  S : string;
begin
  S := GetStrDef(fiDisc, '0');
//  S := Utls.CommaToDot(S);
//  Result := StrToFloat(S, Utls.GlobalFormatSettings);
//  S := CommaToDot(S);
  S := DotToComma(S);
//  Result := StrToFloat(S, GlobalFormatSettings);
  s := StripPositiveToStr(s);
  Result := StrToFloat(S);
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetDiscount2: Double;
var
  S : string;
begin
  S := GetStrDef(fiDisc2, '0');
//  S      := Utls.CommaToDot(S);
//  Result := StrToFloat(S, Utls.GlobalFormatSettings);
//  S      := CommaToDot(S);
  S      := DotToComma(S);
//  Result := StrToFloat(S, GlobalFormatSettings);
  Result := StrToFloat(S);
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetDiscount3: Double;
var
  S : string;
begin
  S := GetStrDef(fiDisc3, '0');
//  S      := Utls.CommaToDot(S);
//  Result := StrToFloat(S, Utls.GlobalFormatSettings);
//  S      := CommaToDot(S);
  S      := DotToComma(S);
//  Result := StrToFloat(S, GlobalFormatSettings);
  Result := StrToFloat(S);
end;
(*----------------------------------------------------------------------------
function TPurchaseReader.GetSpecialTaxAlcohol: Double;
var
  S : string;
begin
  S := GetStrDef(fiSpecialTaxAlcohol, '0');
  S := Utls.CommaToDot(S);

  Result := StrToFloat(S, Utls.GlobalFormatSettings);
end;   *)
(*----------------------------------------------------------------------------
function TPurchaseReader.GetSpecialTaxRecycle: Double;
var
  S : string;
begin
  S := GetStrDef(fiSpecialTaxRecycle, '0');
  S      := Utls.CommaToDot(S);

  Result := StrToFloat(S, Utls.GlobalFormatSettings);

end;   *)



(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetLineValue: Double;
var
  S : string;
begin
  S := GetStrDef(fiLineValue, '0');
//  S := Utls.CommaToDot(S);
//  Result := StrToFloat(S, Utls.GlobalFormatSettings);
//  S := CommaToDot(S);
  S := DotToComma(S);
//  Result := StrToFloat(S, GlobalFormatSettings);
  Result := StrToFloat(S);
end;
(*----------------------------------------------------------------------------*)
function TPurchaseReader.GetMeasUnitAA: Integer;
var
  S : string;
begin
  S := GetStrDef(fiMeasUnit, '000');

  if (S <> '000') then
  begin
    S      := FDescriptor.MeasUnitMap.Values[S];
    Result := FManager.GetMaterialMeasureUnitAA(MatAA, S);
  end else
    Result := -1;

end;
(*----------------------------------------------------------------------------*)
procedure TPurchaseReader.AddToMaster(tblMaster: TDataset);
begin
  if (CanProcessDoc) then
  begin
    tblMaster.Append();

    try
      tblMaster.FieldByName('DocType'         ).Value := GetDocTypeMap();
      tblMaster.FieldByName('AFM'             ).Value := GetAFM();

      tblMaster.FieldByName('SupplierCode'    ).Value := SupCode;
      tblMaster.FieldByName('GLN'             ).Value := GlnId;

      tblMaster.FieldByName('Date'            ).Value := DocDate;
      tblMaster.FieldByName('RelDocId'        ).Value := RelDoc;

      tblMaster.FieldByName('PayType'         ).Value := GetPayType();

      tblMaster.FieldByName('Flag'            ).Value := True;
    except
      on E: Exception do
      begin
        CanProcessDoc := False;
        FManager.Log(Self, Format('  ERROR: (Exception) %s - Line: %d', [E.Message, LineIndex + 1]));
      end;
    end;

    tblMaster.Post();
  end;
end;
(*----------------------------------------------------------------------------*)
procedure TPurchaseReader.AddToDetail(tblMaster: TDataset; tblDetail: TDataset);
  {---------------------------------------------}
  { �������: �� ������ �������� ��� �� ����������� }
  procedure CancelDoc();
  begin
    tblMaster.Edit;
    tblMaster.FieldByName('Flag').Value := False;
    tblMaster.Post();

    CanProcessDoc := False;
  end;
  {---------------------------------------------}
  function GetMeasUnitAAForTEM(MatAA: integer): integer;
  const UOM = '���';
  begin
    Result := FManager.GetMaterialMeasureUnitAA(MatAA, UOM);
  end;
var
  S : string;
  ConversionRate : integer;
  ConvertedUnitOfMeasure : integer;
begin
  if CanProcessDoc then
  begin
    try
      S := GetCode();

// If GetMaterialCode is overridden in the descendant, the descendant's code is executed.
      if (GetMaterialCode(S, SupCode, MatCode, MatAA)) then
      begin
        if MatCode <> 'MULTI CODE' then
        begin
          tblDetail.Append();

          if fDescriptor.NeedsMeasUnitConversion = True then
            ConversionRate := GetMeasUnitRelation
          else
            ConversionRate := 1;

          tblDetail.FieldByName('MasterId'      ).Value := tblMaster.FieldByName('Id').Value;
          tblDetail.FieldByName('MatAA'         ).Value := MatAA;

          tblDetail.FieldByName('Code'          ).Value := MatCode;
          tblDetail.FieldByName('Barcode'       ).Value := GetBarcode();

          if ConversionRate = 1 then
          begin
            tblDetail.FieldByName('Qty'           ).Value := GetQty();
            tblDetail.FieldByName('Price'         ).Value := GetPrice();
            tblDetail.FieldByName('MatMeasUnitAA' ).Value := GetMeasUnitAA();
          end
          else
          if ConversionRate > 1 then
          begin
            tblDetail.FieldByName('Qty'           ).Value := GetQty() * ConversionRate;
            tblDetail.FieldByName('Price'         ).Value := GetPrice() / ConversionRate;
//            tblDetail.FieldByName('MatMeasUnitAA' ).Value := GetMeasUnitAA();
// I have to find the MeasUnitAA that corresponds to the Item unit of measure.
// So I force the query for the '���'.
            tblDetail.FieldByName('MatMeasUnitAA' ).Value := GetMeasUnitAAForTEM(MatAA);
          end;

          tblDetail.FieldByName('VAT'           ).Value := GetVAT(MatCode);
          tblDetail.FieldByName('Disc'          ).Value := GetDiscount();

          tblDetail.FieldByName('Disc2'          ).Value := GetDiscount2();
          tblDetail.FieldByName('Disc3'          ).Value := GetDiscount3();
//          tblDetail.FieldByName('SpecialTaxAlcohol'          ).Value := GetSpecialTaxAlcohol();
//          tblDetail.FieldByName('SpecialTaxRecycle'          ).Value := GetSpecialTaxRecycle();

          tblDetail.FieldByName('LineValue'     ).Value := GetLineValue();

          tblDetail.Post();
        end;

      { ��� �������� ��� �� ����� ��� ������� ��� ������ �� ����������
        ��� ��� �������� detail �������
        ��� �� ����������� ��� ������ ���, ������ �� tblMaster }
      end else begin
        CancelDoc();
      end;
    except
      on E: Exception do
      begin
        CanProcessDoc := False;
        CancelDoc();
        FManager.Log(Self, Format('ERROR: (Exception) %s - Line: %d', [E.Message, LineIndex + 1]));
      end;
    end;



  end;
end;
(*----------------------------------------------------------------------------*)
procedure TPurchaseReader.ProcessFile(tblMaster, tblDetail: TDataset);
var
  i            : Integer;

begin
  LineIndex     := -1;
  CanProcessDoc := False;
  DocDate       := SysUtils.Date();
  tblMaterial   := nil;
  LastSupCode   := '';

  if (not FDescriptor.IsMultiSupplier) then
  begin
    AFM           := FDescriptor.AFM;
    if not GetSupplierCode(AFM, SupCode) then
      Exit;
  end else begin
    AFM     := '';
    SupCode := '';
  end;

  LastDocNo := '';
  LineKind  := lkNone;

  if (FDescriptor.Kind = fkDelimited) then
    ValueList := TStringList.Create;

  try
    PrepareProcessFile();

    for i := 0 to DataList.Count - 1 do
    begin
      LineIndex := i;

      if CheckIsAborted then
        Exit;

      Line := Trim(DataList[i]);

      { split �� ��������� �� delimiter }
      if (FDescriptor.Kind = fkDelimited) then
      begin
        ValueList.Clear();
        if (Length(Line) > 0) then
//          Utls.Split(Line, FDescriptor.Delimiter, ValueList);
          Split(Line, FDescriptor.Delimiter, ValueList);
      end;

      { �� ����� reader ��� ��� ��� ����������� �� ����� �������, ��������... }
      if  (Length(Line) <= 0) and ((FDescriptor.SeparationMode <> smEmptyLine) or (FDescriptor.Schema = fsSameLine))  then
        Continue;

      LineKind  := GetLineKind(LineKind);

      { �� ������� �� master ������, ������ �� ���������� �� ������� �� �������������� � ��� �� ����������� }
      if LineKind = lkOnMasterLine then
      begin
        DocType       := GetDocType();
        CanProcessDoc := GetCanProcessDoc();

        if not CanProcessDoc then
          Continue;

        { ������� �� ���� ��� ����������� �� ����������� ��� ��� CheckMasterCanContinue() }
        RelDoc  := GetRelDocNum();
        GLN     := GetGLN();
        DocDate := GetDocDate();

        { �� ������ � ����������� ��� ��� ����������� master ������ }
         if FDescriptor.IsMultiSupplier then
        begin
          AFM     := GetAFM();

          if not GetSupplierCode(AFM, SupCode) then
          begin
            CanProcessDoc := False;
            Continue;
          end;

          if (LastSupCode <> SupCode)  then
          begin
            LastSupCode := SupCode;
            if Assigned(tblMaterial) then
            begin
              tblMaterial.Close;
              FreeAndNil(tblMaterial);
            end;
          end;
        end;


        { ��� ����� ���� � �� ��������� ��� IsMultiSupplier ���� ��� ������� � SupCode (�����������),
          ���� ��������� �� tblMaterial ��� �� ������� look-ups}
        if not Assigned(tblMaterial) then
          tblMaterial := FManager.SelectSupplierMaterialDataset(SupCode);

        { � CheckMasterCanContinue ����� ������ ���� ���� CanProcessDoc -
          ������� ������ �� ����
          1) ����� ��/���� 2) �� �� ���/�� ������� ��� 3) �������� ��  }
        if not CheckMasterCanContinue(i + 1, RelDoc, GetDocTypeMap) then
          Continue;


        if (CanProcessDoc) then
        begin
          AddToMaster(tblMaster);

          { ������������: fsSameLine ������ �� ������� ��� detail ������ }
          if (CanProcessDoc and (FDescriptor.Schema = fsSameLine)) then
            AddToDetail(tblMaster, tblDetail);
        end;

      { detail ������ }
      end else if LineKind = lkOnDetailLine then
      begin
        //if (CanProcessDoc and (FDescriptor.Schema <> fsSameLine)) then
        if (CanProcessDoc) then
          AddToDetail(tblMaster, tblDetail);
      end;

    end;

  finally
    DataList.Clear();
    FreeAndNil(tblMaterial);
  end;

end;

end.
