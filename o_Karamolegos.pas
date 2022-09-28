unit o_Karamolegos;

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
(*----------------------------------------------------------------------------*)
  TKaramolegosDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TKaramolegosReader = class(TPurchaseReader)
 protected
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function  DocStrToDate(S: string): TDate; override;
   function  GetLineMarker(): string; override;
   function  GetDiscount: double; override;
   function  GetLineValue: double; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;





implementation

{ TKaramolegosDescriptor }

(*----------------------------------------------------------------------------*)
constructor TKaramolegosDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.Karamolegos';
  FFileName        := '������������\*_*.txt';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := '0';
  FDetailMarker    := ' ';
  FAFM             := '094276540';


  FDocTypeMap.Add('001=���');
  FDocTypeMap.Add('019=���');
  FDocTypeMap.Add('002=���');
  FDocTypeMap.Add('020=���');
  FDocTypeMap.Add('022=���');
  FDocTypeMap.Add('026=���');
  FDocTypeMap.Add('021=���');
  FDocTypeMap.Add('013=���');
  FDocTypeMap.Add('027=���');
  FDocTypeMap.Add('003=���');
  FDocTypeMap.Add('135=���');
  FDocTypeMap.Add('028=���');
  FDocTypeMap.Add('029=���');
  FDocTypeMap.Add('030=���');
//  FDocTypeMap.Add('024=
//  FDocTypeMap.Add('025=
  FDocTypeMap.Add('130=���');
//  FDocTypeMap.Add('103=
//  FDocTypeMap.Add('109=
//  FDocTypeMap.Add('102=
//  FDocTypeMap.Add('100=
//  FDocTypeMap.Add('104=
//  FDocTypeMap.Add('112=


  FPayModeMap.Add('01=��� �������');
  FPayModeMap.Add('02=��� �������');
//  FPayModeMap.Add('02=�������');
//W  FPayModeMap.Add('14=�������');
  // ��� �������

  FMeasUnitMap.Add('1=���');
  FMeasUnitMap.Add('2=���');

end;
(*----------------------------------------------------------------------------*)
procedure TKaramolegosDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate,    1, 84, 8));
  FItemList.Add(TFileItem.Create(itDocType, 1, 66, 3));
  FItemList.Add(TFileItem.Create(itDocId,   1, 72, 12));
  FItemList.Add(TFileItem.Create(itGLN,     1, 121, 13)); // GLN
  FItemList.Add(TFileItem.Create(itPayType, 1, 134, 1));  // ����� ����� ��� ������� ���� ����� �����������.

  { detail }
  FItemList.Add(TFileItem.Create(itCode,      2, 15, 10));  // ����� lookup select
//  FItemList.Add(TFileItem.Create(itBarcode,   2, 25, 14));
  FItemList.Add(TFileItem.Create(itQty,       2, 109, 11));
  FItemList.Add(TFileItem.Create(itMeasUnit,  2, 120, 1));
  FItemList.Add(TFileItem.Create(itPrice,     2, 130, 16));
  FItemList.Add(TFileItem.Create(itDisc,      2, 188, 16)); // disc value
  FItemList.Add(TFileItem.Create(itLineValue, 2, 204, 16)); // net value
  FItemList.Add(TFileItem.Create(itVAT,       2, 236, 3));
end;







{ TKaramolegosReader }
(*----------------------------------------------------------------------------*)
constructor TKaramolegosReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.Karamolegos');
end;
(*----------------------------------------------------------------------------*)
function TKaramolegosReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 2011 / 10 / 01

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
function TKaramolegosReader.GetDiscount: double;
begin
//  Result := 0.00;

// ��� ��� GetDocType
  if (DocType = '019') or (DocType = '020') then
    Result := 100  // ��� ����� �����, ����� � ������� ����� ������.
                   // ������� ���� ����� ���� ��� LineValue = 0.00
                   // �� �������� �� ��������� GetQty * GetPrice
  else
    Result := inherited GetDiscount;

end;
(*----------------------------------------------------------------------------*)
function TKaramolegosReader.GetLineMarker: string;
begin
  Result := DataList[LineIndex][1];
end;
(*----------------------------------------------------------------------------*)
function TKaramolegosReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
var AVat: string;

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

{ ��� �� ����������� ����� ��� ������� ������������� ��� �� �� �� ��������� }
  if GetDocTypeMap = '���' then
  begin
    AVat := IntToStr(StrToInt(GetVAT(MatCode)));
    if AVat = '13' then
      SupMatCode := '��13'
    else
    if AVat = '24' then
      SupMatCode := '��24';
  end;

{  if SupMatCode = '��13' then
    SupMatCode := '000235'
  else
  if SupMatCode = '��24' then
    SupMatCode := '000349'
  else}
{ ��� ��� ����������� ��� ������� �� ����������� Stand ��� ������ }
{ ���� � ��������� ����� �� ������������� �� stand ���� ����� ��� 883 - �� '461017' }

  // STAND
  if (SupMatCode = '878') or (SupMatCode = '879') or
     (SupMatCode = '883') or (SupMatCode = '885') then
    SupMatCode := '883'
//  begin
//    MatCode := 'MULTI CODE';
//    FManager.Log(Self, Format('MULTI CODE ERROR:---------SupCode: %10s, Date1: %10s, RelDoc: %5s, %-10s, SupMatCode: %-10s',
//                 [SupCode, Utls.DateToStrSQL(DocDate, False), DocType, RelDoc, SupMatCode]));
//    Result := True;
//  end
  else

  begin
    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

    if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
  end;

end;
(*----------------------------------------------------------------------------*)
function TKaramolegosReader.GetLineValue: double;
begin
//  Result := 0.00;

// ��� ��� GetDocType
  if (DocType = '019') or (DocType = '020') then
    Result := 0.00
  else
    Result := inherited GetLineValue;

end;
(*----------------------------------------------------------------------------*)
initialization
  FileDescriptors.Add(TKaramolegosDescriptor.Create);

end.
