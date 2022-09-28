(*
  ������ ������� ���� ���� �� format ��� excel, ������ �� ��������
  ��� ������ � ��� ����������� format ����������� ��� �������.

  ������ �� ������ ��� ����� ��� ��������� ��� ��� ��/���.
*)
unit o_Georgiadis;

interface

uses
   Windows
  ,SysUtils
  ,Classes
  ,Controls
  ,Forms
  ,Dialogs
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
  TGeorgiadisDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TGeorgiadisReader = class(TPurchaseReader)
 protected
   //function  ResolveGLN: Boolean; override;
   //function  GetDocDate: TDate; override;
   function GetGLN(): string; override;
//   function GetRelDocNum: string; override;
   function GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function GetDiscount: double; override;
   function GetLineValue: Double; override;
   function GetVAT(MatCode: string): string; override;
   function DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;


implementation


{ TFarmaKoukakiDescriptor }
(*----------------------------------------------------------------------------*)
constructor TGeorgiadisDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.����������';
  FFileName        := '����������\��������_���������*.csv';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  FAFM             := '082757287';
  FNeedsMapGln     := True;
//  FIsMultiSupplier := True;

  FNeedsMapPayMode := True;

  FPayModeMap.Add('�������=��� �������');

  FDocTypeMap.Add('41=���');
  FDocTypeMap.Add('42=���');
  FDocTypeMap.Add('45=���');
  FDocTypeMap.Add('4100=���');
  FDocTypeMap.Add('4101=���');
  FDocTypeMap.Add('4102=���');
  FDocTypeMap.Add('4103=���');
  FDocTypeMap.Add('4104=���');
  FDocTypeMap.Add('4105=���');
  FDocTypeMap.Add('4106=���');
  FDocTypeMap.Add('4107=���');
  FDocTypeMap.Add('4108=���');
  FDocTypeMap.Add('4109=���');
  FDocTypeMap.Add('4110=���');
  FDocTypeMap.Add('4111=���');
  FDocTypeMap.Add('4112=���');
  FDocTypeMap.Add('4113=���');
  FDocTypeMap.Add('4114=���');
  FDocTypeMap.Add('4115=���');
  FDocTypeMap.Add('4120=���');
  FDocTypeMap.Add('41-R=���');
  FDocTypeMap.Add('41-�=���');

  FDocTypeMap.Add('62=���');
  FDocTypeMap.Add('6020=���');
  FDocTypeMap.Add('6200=���');
  FDocTypeMap.Add('6201=���');
  FDocTypeMap.Add('6202=���');
  FDocTypeMap.Add('6203=���');
  FDocTypeMap.Add('6204=���');
  FDocTypeMap.Add('6205=���');
  FDocTypeMap.Add('6206=���');
  FDocTypeMap.Add('6207=���');
  FDocTypeMap.Add('6208=���');
  FDocTypeMap.Add('6209=���');
  FDocTypeMap.Add('6210=���');
  FDocTypeMap.Add('6211=���');
  FDocTypeMap.Add('6212=���');
  FDocTypeMap.Add('6213=���');
  FDocTypeMap.Add('6214=���');
  FDocTypeMap.Add('6215=���');
  FDocTypeMap.Add('62-R=���');

  FDocTypeMap.Add('61=���');
  FDocTypeMap.Add('6101=���');
  FDocTypeMap.Add('6102=���');
  FDocTypeMap.Add('6103=���');
  FDocTypeMap.Add('6104=���');
  FDocTypeMap.Add('6105=���');
  FDocTypeMap.Add('6106=���');
  FDocTypeMap.Add('6107=���');
  FDocTypeMap.Add('6108=���');
  FDocTypeMap.Add('6109=���');
  FDocTypeMap.Add('6110=���');
  FDocTypeMap.Add('6111=���');
  FDocTypeMap.Add('6112=���');
  FDocTypeMap.Add('6113=���');
  FDocTypeMap.Add('6114=���');
  FDocTypeMap.Add('6115=���');
  FDocTypeMap.Add('6120=���');
  FDocTypeMap.Add('61-R=���');

  FDocTypeMap.Add('63=���');
  FDocTypeMap.Add('6300=���');
  FDocTypeMap.Add('6301=���');
  FDocTypeMap.Add('6302=���');
  FDocTypeMap.Add('6303=���');
  FDocTypeMap.Add('6304=���');
  FDocTypeMap.Add('6305=���');
  FDocTypeMap.Add('6306=���');
  FDocTypeMap.Add('6307=���');
  FDocTypeMap.Add('6308=���');
  FDocTypeMap.Add('6309=���');
  FDocTypeMap.Add('6310=���');
  FDocTypeMap.Add('6311=���');
  FDocTypeMap.Add('6312=���');
  FDocTypeMap.Add('6313=���');
  FDocTypeMap.Add('6314=���');
  FDocTypeMap.Add('6315=���');
  FDocTypeMap.Add('6320=���');
  FDocTypeMap.Add('63-R=���');
  FDocTypeMap.Add('66=���');

  FDocTypeMap.Add('64=���');

  FMeasUnitMap.Add('���=���');
  FMeasUnitMap.Add('���=���');
  FMeasUnitMap.Add('���=���');

  FGLNMap.Add('35.071=1');    //    ������� 18
  FGLNMap.Add('40.473=2');    //    ��������� 1
  FGLNMap.Add('40.476=3');    //    ���������� 46
  FGLNMap.Add('40.481=5');    //    25 ������� 113-115
  FGLNMap.Add('40.477=6');    //    ������� 38 & ������
  FGLNMap.Add('40.479=7');    //    �������� 92
  FGLNMap.Add('35.072=8');    //    �������� 12
  FGLNMap.Add('40.480=9');    //    �������� 154
  FGLNMap.Add('40.088=10');   //    ��� ������
  FGLNMap.Add('35.112=13');   //    ��������� 14
  FGLNMap.Add('35.091=12');   //    ������� 6
  FGLNMap.Add('03.013=13');   //    ��������� 14
  FGLNMap.Add('22.112=13');   //    ��������� 14
  FGLNMap.Add('35.131=15');   //    ���������� 27 & ����
  FGLNMap.Add('40.478=17');   //    ������ 43
  FGLNMap.Add('40.472=19');   //    ��������������� 5
  FGLNMap.Add('35.073=20');   //    ��������� 6
  FGLNMap.Add('35.047=21');   //    �. ���������� 9 ������
  FGLNMap.Add('35.108=21');   //    �. ���������� 9 ������ // *** �������
  FGLNMap.Add('40.471=22');   //    �������
//  FGLNMap.Add('00=99');     //    14��� ������������-���������
  FGLNMap.Add('40.474=23');   //    �������� 37
  FGLNMap.Add('40.475=24');   //    ������
  FGLNMap.Add('����� ���=24');//    ������
  FGLNMap.Add('35.132=25');   //    ����������
  FGLNMap.Add('35.087=26');   //    ������ ������
  FGLNMap.Add('35.109=26');   //    ������ ������

end;
(*----------------------------------------------------------------------------*)
procedure TGeorgiadisDescriptor.AddFileItems;
begin
  inherited;

  { master }
//  FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,4-1));    // GLN
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,5-1));

  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  , 6-1));
//  FItemList.Add(TFileItem.Create(itBarcode      ,2  , 7-1));
  FItemList.Add(TFileItem.Create(itQty          ,2  , 9-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,10-1));
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,11-1));
  FItemList.Add(TFileItem.Create(itDisc         ,2  ,12-1)); // Value
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,13-1));
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,14-1));

end;


{ TGeorgiadisReader }
(*----------------------------------------------------------------------------*)
constructor TGeorgiadisReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.����������');
end;
(*----------------------------------------------------------------------------*)
function TGeorgiadisReader.GetGLN: string;
begin
  if GetDocType = '64' then
    Result := '����� ���'
  else
    Result := GetStrDef(fiGLN);
end;
(*----------------------------------------------------------------------------*)
{function TGeorgiadisReader.GetRelDocNum: string;
begin
  Result := GetDocType + GetDocNo;
end;}
(*----------------------------------------------------------------------------*)
function TGeorgiadisReader.GetDiscount: double;
begin
// ��� �� ����������� ����� ���, � ������� ����� 100%.
  if (DocType = '41') or
     (DocType = '42') or
     (DocType = '45') or
     (DocType = '4100') or
     (DocType = '4101') or
     (DocType = '4102') or
     (DocType = '4103') or
     (DocType = '4104') or
     (DocType = '4105') or
     (DocType = '4106') or
     (DocType = '4107') or
     (DocType = '4108') or
     (DocType = '4109') or
     (DocType = '4110') or
     (DocType = '4111') or
     (DocType = '4112') or
     (DocType = '4113') or
     (DocType = '4114') or
     (DocType = '4115') or
     (DocType = '4120') or
     (DocType = '41-R') or
     (DocType = '41-�') then
    Result := 100  // ��� ����� �����, ����� � ������� ����� ������.
                   // ������� ���� ����� ���� ��� LineValue = 0.00
                   // �� �������� �� ��������� GetQty * GetPrice
  else
    Result := inherited GetDiscount;
end;
(*----------------------------------------------------------------------------*)
function TGeorgiadisReader.GetLineValue: Double;
var
  S : string;
begin
  S := GetStrDef(fiLineValue, '0');
//  S := Utls.CommaToDot(S);
//  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  S := DotToComma(S);
  Result := abs(StrToFloat(S));
end;
(*----------------------------------------------------------------------------*)
function TGeorgiadisReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string;
  out MatAA: Integer): Boolean;

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
//  SupMatCode := StripInt(SupMatCode); // ���� �������� �� ������ !!!

  if (SupMatCode = '08.02.001') then
    SupMatCode := '70001900';
// ����.������ HIGH PROTEIN ������� 237�� ������
  if (SupMatCode = '62002030') then
    SupMatCode := '2832';
  if (SupMatCode = '63000013') then
// �����.���� ���������� 3��� (��� ���=2032)
    SupMatCode := '10.04.026';

  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

  if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
  FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                 [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
end;
(*----------------------------------------------------------------------------*)
(* ��� ��� ��������� ��� ���� ������ ����� ��� ������� �� ��� ������ ---------*)
function TGeorgiadisReader.GetVAT(MatCode: string): string;

begin
    // ��������� �� string '���-24'
 // Result := FloatToStr(Abs(StripReal(GetStrDef(fiVAT))));    //yannis commented


  // ���������� �� Abs ����� ������� �� "-".


  Result := Copy(GetStrDef(fiVAT), 5, 2);  //yannis code

  end;






(*----------------------------------------------------------------------------*)
function TGeorgiadisReader.DocStrToDate(S: string): TDate;
var ADay, AMonth, AYear : word;
    p : integer;
    ss : string;
begin
  // 1/2/2017
  p := pos('/', s);
  ADay   := StrToInt(LeftString(s, p-1));
  ss := RightString(s, Length(s) - p);
  p := pos('/', ss);
  AMonth := StrToInt(LeftString(ss, p-1));
  AYear  := StrToInt(RightString(s, 4));

  Result := EncodeDate(AYear, AMonth, ADay);
end;
(*----------------------------------------------------------------------------*)






initialization
  FileDescriptors.Add(TGeorgiadisDescriptor.Create);

end.
