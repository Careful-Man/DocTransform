// ���� �� ���������� ��� �� ������ �� ���.
// ���� �� ����������� �� ���������� �� ��� ���� ������.
// ����������� ��� ���������� :
// TFileKind        - fkFixedLength
// TFileSchema      - fsHeaderDetail
// TSeparationMode  - smEmptyLine

// TInfoType (Data) -
// AFM              - OK
// Date             - OK
// DocType          - OK
// DocId            - OK
// DocChanger       -
// GLN              - OK
// PayType          -
// RelDoc           XXX
// SupCode          - OK
// AlterDoc         -

// Code             - OK
// BarCode          -
// Qty              - OK
// Price            - OK
// VAT              XXX
// Disc             - OK
// Disc2            -
// Disc3            -
// LineValue        - OK
// MeasUnit         - OK
// MeasUnitRelation -


unit o_CocaCola;

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
  ,IniFiles
  ,Variants
  ,StrUtils
//  ,tpk_Utls
  ,uStringHandlingRoutines
  ,o_Descriptors
  ,o_Managers
  ,o_Purchases
//  ,FmxUtils

  ;


type
(*----------------------------------------------------------------------------*)
  TCocaColaDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TCocaColaReader = class(TPurchaseReader)
 protected
//   procedure MergeFiles(FileList : TStringList); override;
   function  DocStrToDate(S: string): TDate; override;
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function  GetLineValue: Double; override;
   function  GetPrice: Double; override;
//   function  GetLineValue: Double; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;

var ASupMatCode : string;

implementation


{ TCocaColaDescriptor }

(*----------------------------------------------------------------------------*)
constructor TCocaColaDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.CocaCola';
  FFileName        := 'Coca_Cola\INVOIC_COCA_COLA.txt';
//  FFileMask        := 'Coca_Cola\INVOIC_GR_AFRODITI_*.txt';
  FFileMask        := 'INVOIC_GR_AFRODITI_*.dat';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smEmptyLine;
  FNeedsFileMerge  := True;
//  FMasterMarker    := 'H';
//  FDetailMarker    := 'D';
  FAFM             := '094277965';
  FIsMultiSupplier := False;

  FNeedsMapGln     := True;

//  FIsOem           := True;
  FIsUniCode       := True;


  FDocTypeMap.Add('F2=���');
  FDocTypeMap.Add('ZTRR=���');
  FDocTypeMap.Add('ZROC=��');

  FDocTypeMap.Add('��-��=���');
  FDocTypeMap.Add('��=���');

  // ��� �������

  FMeasUnitMap.Add('CS=���');
  FMeasUnitMap.Add('PC=���');
  FMeasUnitMap.Add('PCE=���');
  FMeasUnitMap.Add('EA=���');
//  FMeasUnitMap.Add('PACK=PACK');
//  FMeasUnitMap.Add('PAL=PALLET');

  FGLNMap.Add('3003006564=1');     // �������
  FGLNMap.Add('3003009760=2');     // ���������
  FGLNMap.Add('3003010413=3');     // ����������
  FGLNMap.Add('3003011533=5');     // �������
  FGLNMap.Add('3003010699=6');     // �������
  FGLNMap.Add('3003010580=7');     // ��������
  FGLNMap.Add('3003010983=8');     // �������
  FGLNMap.Add('3003011032=9');     // ��������
  FGLNMap.Add('3000119773=10');    // ������
  FGLNMap.Add('3003011580=12');    // �������
  FGLNMap.Add('3003011840=13');    // �����
  FGLNMap.Add('3003011986=15');    // ��������
  FGLNMap.Add('3000108002=16');    // ��������
  FGLNMap.Add('3000111337=17');    // ������
  FGLNMap.Add('3000119889=19');    // ���������������
  FGLNMap.Add('3000120095=20');    // ���������
  FGLNMap.Add('3000126966=21');    // ������
  FGLNMap.Add('3005009233=22');    // �������
  FGLNMap.Add('3005013258=23');    // ��������
  FGLNMap.Add('3005200140=24');    // ������
  FGLNMap.Add('3005238955=25');    // ����������
  FGLNMap.Add('3005246266=26');    // ������ ������
  FGLNMap.Add('3003010168=99');    // ��������
  FGLNMap.Add('3005008839=99');    // ��������

end;
(*----------------------------------------------------------------------------*)
procedure TCocaColaDescriptor.AddFileItems;
begin
  inherited;

  { master }

  FItemList.Add(TFileItem.Create(itDate       ,1    ,17   ,8));
  FItemList.Add(TFileItem.Create(itDocType    ,1    ,1    ,6));
  FItemList.Add(TFileItem.Create(itDocId      ,1    ,10   ,7));
  FItemList.Add(TFileItem.Create(itGLN        ,1    ,29   ,10));    // GLN
  //FItemList.Add(TFileItem.Create(itPayType    ,1    ,0    ,0));



  { detail }
  FItemList.Add(TFileItem.Create(itCode       ,2    ,1    ,15));        // ����� lookup select
  //FItemList.Add(TFileItem.Create(itBarcode, 2, 13, 14));
  FItemList.Add(TFileItem.Create(itQty        ,2    ,30   ,14));
  FItemList.Add(TFileItem.Create(itPrice      ,2    ,44   ,14));
//  FItemList.Add(TFileItem.Create(itVAT        ,2    ,92   ,2));  // percent
  FItemList.Add(TFileItem.Create(itDisc       ,2    ,58   ,14));   // disc value
  FItemList.Add(TFileItem.Create(itLineValue  ,2    ,72   ,14));   // incl. VAT
  FItemList.Add(TFileItem.Create(itMeasUnit   ,2    ,86   ,14));
end;







{ TCocaColaReader }
(*----------------------------------------------------------------------------*)
constructor TCocaColaReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.CocaCola');
end;
(*----------------------------------------------------------------------------*)
function TCocaColaReader.GetMaterialCode(SupMatCode, SupCode: string;
  out MatCode: string; out MatAA: Integer): Boolean;

  function GetMatCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
  begin
    Result := False;

    MatCode := '';
    MatAA   := -1;

  //  if tblMaterial.Locate('SupMatCode', SupMatCode, []) then
    if tblMaterial.Locate('SupMatCode;SupCode', VarArrayOf([SupMatCode, SupCode]), []) then
    begin
      MatCode := tblMaterial.FieldByName('MatCode').AsString;
      MatAA   := tblMaterial.FieldByName('MatAA').AsInteger;

      Result := True;
    end;

  end;

begin
  Result := False;

  // ������������� ��� ���� ���� 500ML.
    if (SupMatCode = '1003906') then
      SupMatCode := '1003907';

  // ������������� ��� ����� ������ 330ML.
    if (SupMatCode = '1359602') then
      SupMatCode := '1359602';

  // ������������� ��� 500 PET 6X4 COCA COLA GR.
    if (SupMatCode = '2137501') then
      SupMatCode := '1382805';

  // ������������� ��� 500 PET 6X4 COCA COLA GR.
    if (SupMatCode = '425527') then
      SupMatCode := '425505';

  // ������������� ��� 330 CAN 4X6 SPRITE.
    if (SupMatCode = '459106') then
      SupMatCode := '459131';

  // ������������� ��� FUZE TEA LEMON 300MLX4.
    if (SupMatCode = '1747601') then
      SupMatCode := '1747603';

  // ������������� ��� COCA COLA ZERO 4X500ML.
    if (SupMatCode = '1035602') then
      SupMatCode := '1035612';

  // ������������� ��� ??????.
    if (SupMatCode = '425505') then
      SupMatCode := '1035611';

  // ������������� ��� ??????.
    if (SupMatCode = '517482') then
      SupMatCode := '517483';


    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

    if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
end;
(*----------------------------------------------------------------------------*)
(* ����� ����������� �� ������ �� �������������� ��� ����������.              *)
(*----------------------------------------------------------------------------*)
(* � Coca Cola ��� ����� �� ����� ���� ������� ��� ��� ���� ��� ������ ����.  *)
(* � ����������� ����� : (����� ���� ������� - ���) (�.�.  ���������������)   *)
function TCocaColaReader.GetLineValue: Double;

  (* ���� �� function �� ����������� ��� �������� ��� ��� ���������� ��� �����*)
  function InternalGetLineValue: double;
  var
    S : string;
  begin
    S := GetStrDef(fiLineValue, '0');
//    S := Utls.CommaToDot(S);
//    Result := StrToFloat(S, Utls.GlobalFormatSettings);
//    S := CommaToDot(S);
    S := DotToComma(S);
//    Result := StrToFloat(S, GlobalFormatSettings);
    Result := StrToFloat(S);
  end;

var
  F, T : double;
begin
  T := InternalGetLineValue();
  F := StrToFloat(GetVAT(MatCode));
  (* �� �.�. � ��� ����� 23%, �� ����� �������� ��� 1 + 0,23 => 1,23          *)
  T := T / (1+(F/100));
  Result := T;
end;
(*----------------------------------------------------------------------------*)
(* � ����������� ����� : (������ ���� ������� + �������) / ��������           *)
function TCocaColaReader.GetPrice: Double;

  function GetHistoryPrice(MatAA: integer): Double;
  const
    // Password=yoda2k
    CCS = 'Provider=SQLOLEDB.1;Password=1;Persist Security Info=True;User ID=sa;Initial Catalog=Afroditi;Data Source=localhost';
  var
    SqlText     : string;
    IniFileName : string;
    Ini         : TIniFile;
    CS          : string;
    S           : string;
    Prices      : TDataset;
    APrice      : Double;
  begin
//    IniFileName := Utls.AppPath + 'Main.ini';
    SetLength(S, 4096);
    SetLength(S, GetModuleFileName(HInstance, PChar(S), Length(S)));
    GetModuleFileName(HInstance, PChar(S), Length(S));
    IniFileName := ExtractFilePath(S) + 'Main.ini';
    Ini  := TIniFile.Create(IniFileName);
    try
      CS := Ini.ReadString('Main', 'ConnectionString', '');
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

  function InternalGetLineValue: double;
  var
    S : string;
  begin
    S := GetStrDef(fiLineValue, '0');
//    S := Utls.CommaToDot(S);
//    Result := StrToFloat(S, Utls.GlobalFormatSettings);
//    S := CommaToDot(S);
    S := DotToComma(S);
//    Result := StrToFloat(S, GlobalFormatSettings);
    Result := StrToFloat(S);
  end;

  function InternalGetPrice: double;
  var
    S : string;
  begin
    S := GetStrDef(fiPrice, '0');
//    S := Utls.CommaToDot(S);
//    Result := StrToFloat(S, Utls.GlobalFormatSettings);
//    S := CommaToDot(S);
    S := DotToComma(S);
//    Result := StrToFloat(S, GlobalFormatSettings);
    Result := StrToFloat(S);
  end;

var
  LineValue, Discount, Quantity, Price : double;
  S : string;
  C : boolean;
  HistoryPrice : Double;
begin
  LineValue := InternalGetLineValue();
  Price     := InternalGetPrice();
  if (LineValue <> 0) or (Price <> 0) then
  begin
    LineValue := GetLineValue();
    Discount  := GetDiscount();
    Quantity  := GetQty();

    Result := (LineValue + Discount) / Quantity;

  end
  // �� � ���� ������ ����� 0 ��������� ��� ����.
  // �������� ��� �������� ����� ��� �� ������ ���� �� ������ �� ����� � ����.
  // � ����� ���� ����� � ��� �������� ���� ������.
  else if (LineValue = 0) and (Price = 0) then
  begin
    FManager.Log(Self, '���� !!!');


//    C := GetMaterialCode(ASupMatCode, SupCode, MatCode, MatAA);
(* '��� �� MatCode, ��� ���������� �� �� ��������. *)

    HistoryPrice := GetHistoryPrice(MatAA);
    S := FloatToStr(HistoryPrice);
//    S := Utls.CommaToDot(S);
//    S := CommaToDot(S);
    S := DotToComma(S);
    // ������������ ��� ��� �������� ���� ������.
//    Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
//    Result := abs(StrToFloat(S, GlobalFormatSettings));
    Result := abs(StrToFloat(S));
  end
  else if (LineValue <> 0) and (Price = 0) then



    Result := 0;
end;
(*----------------------------------------------------------------------------*)
function TCocaColaReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 20110809

  Y := Copy(S, 1, 4);
  M := Trim(Copy(S, 5, 2));
  D := Trim(Copy(S, 7, 2));
  Result := EncodeDate(
                       StrToInt(Y),
                       StrToInt(M),
                       StrToInt(D)
                       );
end;
(*----------------------------------------------------------------------------*)

initialization
  FileDescriptors.Add(TCocaColaDescriptor.Create);

end.
