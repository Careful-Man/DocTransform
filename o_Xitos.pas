unit o_Xitos;

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
  ,Math
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
  TXitosDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TXitosReader = class(TPurchaseReader)
 protected
   function GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function GetLineValue: Double; override;
   function GetDocNo: string; override;
   function DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;



implementation




{ TXitosDescriptor }
(*----------------------------------------------------------------------------*)
constructor TXitosDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.�����';
  FFileName        := '�����\*.txt';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := '0';
  FDetailMarker    := '1';
  FAFM             := '094131153';

  FIsMultiSupplier := False;

  FNeedsMapPayMode := True;

  FPayModeMap.Add('1=�������');
  FPayModeMap.Add('4=��� �������');

  FDocTypeMap.Add('40=���');
  FDocTypeMap.Add('41=���');
  FDocTypeMap.Add('42=���');
  FDocTypeMap.Add('44=���');
  FDocTypeMap.Add('45=���');

  FNeedsMapGln     := True;

  FGLNMap.Add('2=1');     //    ������� 18
  FGLNMap.Add('3=5');     //    25 ������� 113-115
  FGLNMap.Add('4=8');     //    �������� 12
  FGLNMap.Add('5=12');    //    ������� 6
  FGLNMap.Add('6=13');    //    ��������� 14
  FGLNMap.Add('7=15');    //    ���������� 27 & ����
  FGLNMap.Add('8=19');    //    ��������������� 5
  FGLNMap.Add('9=20');    //    ��������� 6
  FGLNMap.Add('10=21');   //    �. ���������� 9 ������
  FGLNMap.Add('11=22');   //    ������� 80
  FGLNMap.Add('12=23');   //    �������� 37
  FGLNMap.Add('13=24');   //    ������ 109
  FGLNMap.Add('14=25');   //    ���������� 19
  FGLNMap.Add('15=2');    //    ��������� 1
  FGLNMap.Add('16=3');    //    ���������� 46
  FGLNMap.Add('17=7');    //    �������� 92
  FGLNMap.Add('18=6');    //    ������� 38
  FGLNMap.Add('19=9');    //    �������� 154
  FGLNMap.Add('20=10');   //    ��� ������
  FGLNMap.Add('21=17');   //    ������ 43
  FGLNMap.Add('22=26');    //    ������ ������
  FGLNMap.Add('1=99');    //    �������� 109


  FMeasUnitMap.Add('1=���');
  FMeasUnitMap.Add('2=���');
  FMeasUnitMap.Add('3=���');

end;
(*----------------------------------------------------------------------------
To ������ ��� ����� ����� ��� ������ master ��� ���������� �� detail.
� ������ �������� �� ���� ����������  0;
���� detail ������ �������� �� 1;
��� ������� ������ �� �������� spaces
----------------------------------------------------------------------------*)
procedure TXitosDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate,    1, 4));  // ��
  FItemList.Add(TFileItem.Create(itDocType, 1, 1));  // Needs mapping
  FItemList.Add(TFileItem.Create(itDocId,   1, 3));  // ��
  FItemList.Add(TFileItem.Create(itGLN,     1, 20)); // Needs mapping  or 16
  FItemList.Add(TFileItem.Create(itPayType, 1, 5));


  // itRelDoc = itDocType + itDocId

  { detail }
  FItemList.Add(TFileItem.Create(itCode, 2, 1));        // ����� lookup select
  FItemList.Add(TFileItem.Create(itQty, 2, 4));
  FItemList.Add(TFileItem.Create(itPrice, 2, 5));
  FItemList.Add(TFileItem.Create(itVAT, 2, 6));  // percent
  FItemList.Add(TFileItem.Create(itDisc, 2, 7));   // disc value
  FItemList.Add(TFileItem.Create(itLineValue, 2, 8));
  FItemList.Add(TFileItem.Create(itMeasUnit, 2, 9));
end;





{ TXitosReader }
(*----------------------------------------------------------------------------*)
constructor TXitosReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.�����');
end;
(*----------------------------------------------------------------------------*)
function TXitosReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

  function GetMatCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
  begin
    Result  := False;

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

var OriginalSupMatCode : string;

begin
  Result := False;
  OriginalSupMatCode := SupMatCode;

// ������������� ������� ��� ������ ������ ���� �� ���
  if (SupMatCode = '321918') or (SupMatCode = '341916') or (SupMatCode = '355918') then
    SupMatCode  := '341917';

// ������������� ������� ��� ������� ����� �/� ���.�� VACUUM
  if (SupMatCode = '441618') or (SupMatCode = '341611') then
    SupMatCode  := '441614';

// ������������� ������� ��� ������ ����. �/� �����
  if (SupMatCode = '441625') then
    SupMatCode  := '441626';

// ������������� ������� ��� ������� ������ �/� ���.
  if (SupMatCode = '451262') then
    SupMatCode  := '441262';

// ������������� ������� ��� ������� ����. �/� ����
  if (SupMatCode = '451393') then
    SupMatCode  := '451395';


// ������������� ������� ���
  if (SupMatCode = '490460') then
    SupMatCode  := '490452';

// ������������� ������� ��� ���� ���������� ��������� ���.��
  if (SupMatCode = '501201012') or (SupMatCode = '501202') then
    SupMatCode  := '501201011';

// ������������� ������� ��� ���� ���������� ������ ������ ���.��
  if (SupMatCode = '501446012') then
    SupMatCode  := '501446011';


  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);
  if not Result then
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                   [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
end;
(*----------------------------------------------------------------------------*)
(* ����� ����������� �� ������ �� �������������� ��� ����������.              *)
(*----------------------------------------------------------------------------*)
(* � �������� ��� ����� �� ����� ���� ������� ��� ��� ���� ��� ������ ����.  *)
(* � ����������� ����� : (����� ���� ������� - ���) (�.�.  ���������������)   *)
function TXitosReader.GetLineValue: Double;

  function InternalGetLineValue: double;
  var
    S : string;
  begin
    S := GetStrDef(fiLineValue, '0');
//    S := Utls.CommaToDot(S);
//    Result := StrToFloat(S, Utls.GlobalFormatSettings);
    S := DotToComma(S);
    Result := StrToFloat(S);
  end;

var
  VATCategory: double;
  TotalValue: double;
begin
  TotalValue := InternalGetLineValue();
  VATCategory := StrToFloat(GetVAT(MatCode));
  TotalValue := TotalValue / (1+(VATCategory/100));
  Result := TotalValue;
end;
(*----------------------------------------------------------------------------*)
function TXitosReader.GetDocNo: string;
var
  s: string;
begin
  s := GetStrDef(fiDocChanger);
  Result := TrimLeftZeroes(RightString(s, 6));
end;
(*----------------------------------------------------------------------------*)
function TXitosReader.DocStrToDate(S: string): TDate;
begin
  // 01/11/16

   Result := EncodeDate(StrToInt(Copy(S, 7, 2))+2000,
                       StrToInt(Copy(S, 4, 2)),
                       StrToInt(Copy(S, 1, 2)));
end;



initialization
  FileDescriptors.Add(TXitosDescriptor.Create);

end.
