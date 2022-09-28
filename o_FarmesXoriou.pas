(*
  ������ ������� ���� ���� �� format ��� excel, ������ �� ��������
  ��� ������ � ��� ����������� format ����������� ��� �������.

  ������ �� ������ ��� ����� ��� ��������� ��� ��� ��/���.
*)
unit o_FarmesXoriou;

interface

uses
   Windows
  ,SysUtils
  ,Classes
  ,Controls
  ,Forms
  ,Contnrs
  ,Db
  ,Variants
  ,StrUtils
//  ,tpk_Utls
  ,o_Descriptors
  ,o_Managers
  ,o_Purchases
  ,uStringHandlingRoutines
  ;

type
(*----------------------------------------------------------------------------
O ����������� �� ������ �� ���� �����������
  NoLine
  HeaderLine
  DetailLine
  SkipLine
��� � ���������� �� ��� ������� ���� ������ ��� �� ��� �������������

*)
  TFarmesXoriouDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TFarmesXoriouReader = class(TPurchaseReader)
 protected
   //function  ResolveGLN: Boolean; override;
   //function  GetDocDate: TDate; override;

//   function GetGLN(): string; override;
//   function GetDocType: string; override;
//   function GetDocNo: string; override;
//   function GetRelDocNum: string; override;
   function GetQty: Double; override;
   function GetLineValue: Double; override;
   function GetVAT(MatCode: string): string; override;
//   function GetMeasUnitAA: integer; override;
//   function GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function DocStrToDate(S: string): TDate; override;
   function GetPayType: string; override;
//   function StripInt(ToStrip: string):string;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;



implementation




{ TFarmesXoriouDescriptor }
(*----------------------------------------------------------------------------*)
constructor TFarmesXoriouDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.������-������';
  FFileName        := '������ ������\*.csv';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  FAFM             := '800842383';
  FNeedsMapGln     := True;
//  FIsMultiSupplier := True;

//  FNeedsMapPayMode := True;
//  FPayModeMap.Add('1000=�������');
//  FPayModeMap.Add('1003=��� �������');
//  FPayModeMap.Add('1010=��� �������');


  FDocTypeMap.Add('��������� ������ ��������� �������=���');
  FDocTypeMap.Add('��������� �����.����.������.��������=���');

(*
  FDocTypeMap.Add('��=���');
  FDocTypeMap.Add('��=���');
*)

//  FMeasUnitMap.Add('101=���');
  FMeasUnitMap.Add('����=���');
  FMeasUnitMap.Add('���.=���');

      // AX mappings
  FGLNMap.Add('01=1');
  FGLNMap.Add('������� 18=1');
  FGLNMap.Add('��������� 1=2');
  FGLNMap.Add('���������� 45=3');
  FGLNMap.Add('03=5');
  FGLNMap.Add('3=5');
  FGLNMap.Add('������� 38=6');
  FGLNMap.Add('�������� 92=7');
  FGLNMap.Add('02=8');
  FGLNMap.Add('2=8');
  FGLNMap.Add('�������� 154=9');
  FGLNMap.Add('�������� 6=12');
  FGLNMap.Add('04=13');
  FGLNMap.Add('��.��������� 14=13');
  FGLNMap.Add('���������� 27 & ����=15');
  FGLNMap.Add('5=15');
  FGLNMap.Add('������ 43=17');
  FGLNMap.Add('��������������� 5 & ����������=19');
  FGLNMap.Add('6=19');
  FGLNMap.Add('07=20');
  FGLNMap.Add('��������� 6=20');
  FGLNMap.Add('�.���������� 9=21');
  FGLNMap.Add('8=21');
  FGLNMap.Add('������ 80=22');
  FGLNMap.Add('9=22');
  FGLNMap.Add('�������� 37=23');
  FGLNMap.Add('������ 109=24');
  FGLNMap.Add('12=25');
  FGLNMap.Add('�������� 112=26');


//  FGLNMap.Add('��/�� ������� 18, �������=1');                  //    ������� 18
//  FGLNMap.Add('��/�� ��������� 1, ���������=2');               //    ��������� 1
//  FGLNMap.Add('��/�� ���������� 45, ��������=3');              //    ���������� 46
//  FGLNMap.Add('��/�� ������� 113-115, �������=5');             //    �������
//  FGLNMap.Add('��/�� ������� 38, �������������=6');            //    ������� 38 & ������
//  FGLNMap.Add('��/�� �������� 92, ���� ������=7');             //    �������� 92
//  FGLNMap.Add('��/�� ������� 12, �������=8');                  //    �������� 12
//  FGLNMap.Add('��/�� �������� 154, ��� ������=9');             //    �������� 154
////  FGLNMap.Add('08=10');                                //    ��� ������
//  FGLNMap.Add('��/�� �������� 6, ��. �����������=12');         //    �������
//  FGLNMap.Add('��/�� ��. ��������� 14, �����=13');             //    ��������� 14
//  FGLNMap.Add('��/�� ���������� 27 & ����, ��������=15');      //    ���������� 27 & ����
//  FGLNMap.Add('��/�� ������ 43, �������=17');                  //    ������ 43
//  FGLNMap.Add('��/�� ���/��� 5 & ����������, ���������=19');   //    ��������������� 5
//  FGLNMap.Add('��/�� ��������� 6, ���� ������=20');            //    ��������� 6
//  FGLNMap.Add('��/�� �.���������� 9, ������=21');              //    �. ���������� 9 ������
//  FGLNMap.Add('��/�� ������� 80, ��������=22');                //    �������
//  FGLNMap.Add('��/�� �������� 37, ���������=23');              //    �������� 37
//  FGLNMap.Add('��/�� ������ 109 & ����� 1, ���������=24');     //    ������
//  FGLNMap.Add('��/�� ���������� 19, ��������=25');             //    ����������
//  FGLNMap.Add('��/�� �������� 112, ������=26');                //    ������ ������
//  FGLNMap.Add('14� ��� �.� ������������-���������=99');        //    ��������
end;
(*----------------------------------------------------------------------------*)
procedure TFarmesXoriouDescriptor.AddFileItems;
begin
  inherited;

  { master }
//  FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1)); //*   ok
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,3-1)); //*   ok
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,2-1)); //*   ok
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,2-1)); //*    check this out
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,4-1)); //*     changed

  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  , 5-1)); //* changed
  FItemList.Add(TFileItem.Create(itQty          ,2  , 8-1)); //* changed
  FItemList.Add(TFileItem.Create(itPrice        ,2  , 9-1)); //* changed
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,13-1)); //* // Percent  // changed but different VAT type
//  FItemList.Add(TFileItem.Create(itDisc         ,2  ,14-1)); // Percent
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,10-1)); //*- // ������ ���� ** ��� �� 17 ����� �� ���� ??
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,7-1)); //* changed



(*
  { master }
//  FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,9-1));    // GLN

  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  , 4-1));
  FItemList.Add(TFileItem.Create(itQty          ,2  ,11-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,12-1));
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,16-1)); // Percent
//  FItemList.Add(TFileItem.Create(itDisc         ,2  ,14-1)); // Percent
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,13-1)); // ������ ���� ** ��� �� 17 ����� �� ���� ??
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,10-1));
*)
end;


{ TMinasReader }
(*----------------------------------------------------------------------------*)
constructor TFarmesXoriouReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.������-������');
end;
(*----------------------------------------------------------------------------*)
//function TFarmesXoriouReader.GetGLN: string;
//begin
//  Result := GetStrDef(fiGLN);
//  if Result = '' then
//    Result := '  ';
//end;
(*----------------------------------------------------------------------------*)
//function TFarmesXoriouReader.GetDocType: string;
//var
//  s: string;
//begin
//  s := GetStrDef(fiDocType);
//  Result := Copy(s, Length(s)-3+1, 3);
//end;
(*----------------------------------------------------------------------------*)
//function TFarmesXoriouReader.GetDocNo: string;
//var
//  s: string;
//begin
//  s := GetStrDef(fiDocChanger);
//  Result := TrimLeftZeroes(Copy(s, 5, 6));
//end;
(*----------------------------------------------------------------------------*)
//function TFarmesXoriouReader.GetRelDocNum: string;
//begin
//  Result := GetDocNo;
//end;
(*----------------------------------------------------------------------------*)
function TFarmesXoriouReader.GetQty: Double;
var
  S : string;
begin
  S := GetStrDef(fiQty, '0');
//
//
//  //**  S := Utls.CommaToDot(S);
//  //**  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
//  //**  S := CommaToDot(S);
//
//  S := DotToComma(S);
//  //**  Result := abs(StrToFloat(S, GlobalFormatSettings));
  Result := abs(StrToFloat(S));
end;
(*----------------------------------------------------------------------------*)
function TFarmesXoriouReader.GetLineValue: Double;
var
  S : string;
begin
  S := GetStrDef(fiLineValue, '0');

  //**  S := Utls.CommaToDot(S);
  //**  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  //**  S := CommaToDot(S);

  S := DotToComma(S);
  //**  Result := abs(StrToFloat(S, GlobalFormatSettings));
  Result := abs(StrToFloat(S));
end;

(*----------------------------------------------------------------------------*)
function TFarmesXoriouReader.GetVAT(MatCode: string): string;
begin
Result := FloatToStr(StripReal(GetStrDef(fiVAT)));
end;

 (*ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ---------)
  (*
function TFarmaKoukakiReader.GetVAT(MatCode: string): string;
begin
  // ��������� �� string '��� 13% ���� �����������'
  Result := FloatToStr(StripReal(GetStrDef(fiVAT)));
end;*)
(*ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ---------)
function TFarmesXoriouReader.GetVAT(MatCode: string): string;
var
  VATCode: integer;
begin
  VATCode := StrToInt(GetStrDef(fiVAT));
  case VATCode of
    7013: Result := '13';
  end;
end;
 (//ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ*)


(*----------------------------------------------------------------------------*)
//function TFarmesXoriouReader.GetMeasUnitAA: integer;
//var
//  S : string;
//begin
//  S := GetStrDef(fiMeasUnit, '�������');
//
//  if (S <> '000') then
//  begin
//    S      := FDescriptor.MeasUnitMap.Values[S];
//    Result := FManager.GetMaterialMeasureUnitAA(MatAA, S);
//  end else
//    Result := -1;
//
//end;
(*----------------------------------------------------------------------------*)
//function TFarmesXoriouReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
//
//  function GetMatCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
//  begin
//    Result := False;
//
//    MatCode := '';
//    MatAA   := -1;
//
//  //  if tblMaterial.Locate('SupMatCode', SupMatCode, []) then
//    if tblMaterial.Locate('SupMatCode;SupCode', VarArrayOf([SupMatCode, SupCode]), []) then
//    begin
//      MatCode := tblMaterial.FieldByName('MatCode').AsString;
//      MatAA   := tblMaterial.FieldByName('MatAA').AsInteger;
//
//      Result := True;
//    end;
//
//  end;
//
//begin
//  Result := False;
//
//// ������������� ��� ����� ���������  500ml (���������)
//  if (SupMatCode = '0151') then
//    SupMatCode := '0152';
//
//  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);
//
//  if not Result then
////    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
////                   [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
//
//end;
(*----------------------------------------------------------------------------*)
function TFarmesXoriouReader.DocStrToDate(S: string): TDate;
var ADay, AMonth, AYear : word;
    p : integer;
begin
  S := StripDate(S);
  // 01/09/2020

  // �� ����� ���� ��� �� ����� �� ����, �� ������� ����� �����.
  AYear := StrToInt(RightString(S, 4));
//  ShowMessage(Copy(S, 6, 4));
// ��� �o string ��������� �� ��������� ������� ��� ����� ���� �� ��� ������.
// ���� ��� �� 01/09
  S := LeftString(S, Length(S)-5);
  p := pos('/', S);
  ADay := StrToInt(LeftString(S, p-1));
//  ShowMessage(LeftString(S, Length(S)-p));
  AMonth := StrToInt(RightString(S, Length(S)-p));
//  ShowMessage(RightString(S, Length(S)-p));

  Result := EncodeDate(AYear, AMonth, ADay);
end;
(*----------------------------------------------------------------------------*)
function TFarmesXoriouReader.GetPayType: string;
begin
  Result :=  '��� �������';
end;

(*----------------------------------------------------------------------------*)






initialization
  FileDescriptors.Add(TFarmesXoriouDescriptor.Create);

end.
