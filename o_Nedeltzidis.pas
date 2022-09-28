(*
  �������� �� �.�.
  ��� ��������� ����� �� ��� ����� ��� ����� ���� �� �������.
  ���� ��������� ����� �� �������� ���� ��� �.�. ��� ������.

  �������� �� �������� 1.000,50 ���� ��� ������������� �������� ��� �����������.
*)

unit o_Nedeltzidis;

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
  TNedeltzidisDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TNedeltzidisReader = class(TPurchaseReader)
 protected
   //function  ResolveGLN: Boolean; override;
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function  GetMeasUnitAA: Integer; override;
   function  DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;





implementation

{ TNedeltzidisDescriptor }

(*----------------------------------------------------------------------------*)
constructor TNedeltzidisDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.Nedeltzidis';
  FFileName        := '�����������\*123��������.txt';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '099772640';
  FNeedsMapGln     := False;

//  FNeedsMapGln     := True;

{
  FDocTypeMap.Add('001=���');
  FDocTypeMap.Add('002=���');
  FDocTypeMap.Add('003=���');
}
  FDocTypeMap.Add('���=���');
  FDocTypeMap.Add('��0=���');
  FDocTypeMap.Add('���=���');
  FDocTypeMap.Add('��0=���');
  FDocTypeMap.Add('���=���');

  // ��� �������

  FMeasUnitMap.Add('���=���');
  FMeasUnitMap.Add('TEM=���');
  FMeasUnitMap.Add('���=���');
  FMeasUnitMap.Add('01=���');
  FMeasUnitMap.Add('���=���');
  FMeasUnitMap.Add('KIB=���');

{
  FGLNMap.Add('������� 18-20 & ����������� 10=1');                    // �������
  FGLNMap.Add('��������� 1 & ������� ���������=2');                   // ���������
  FGLNMap.Add('���������� 46 & ���������-��������=3');                // ����������
  FGLNMap.Add('������� 113 - 115  �������=5');                        // �������
  FGLNMap.Add('������� 38 & ����������� �������������=6');            // �������
  FGLNMap.Add('�������� 92 ���� ������=7');                           // ��������
  FGLNMap.Add('�������� 12& ������ -  �������=8');                    // �������
  FGLNMap.Add('��.�������� 154 - ��� ������=9');                      // ��������
  FGLNMap.Add('�.������ - ����������=10');                            // ������
  FGLNMap.Add('�������� 6 - �����������=12');                         // �������
  FGLNMap.Add('��.��������� 14 & ����������� �����=13');              // �����
  FGLNMap.Add('���������� 27 & ���� ����� ��������=15');              // ��������
  FGLNMap.Add('���������� 4  ������� ��������� �����������=16');      // ��������
  FGLNMap.Add('������ 43 �������=17');                                // ������
  FGLNMap.Add('��������������� 5 ���������=19');                      // ���������������
  FGLNMap.Add('��������� 6 �.������=20');                             // ���������
  FGLNMap.Add('���.���������� 9 ������=21');                          // ������
  FGLNMap.Add('���.���������� 9 ������ ���=21');                      // ������
  FGLNMap.Add('�.���������� 9 ������=21');                            // ������
  FGLNMap.Add('������� 80 - ���������=22');                           // �������
  FGLNMap.Add('������� 80 ���������=22');                             // �������
  FGLNMap.Add('�������� 37 ���������=23');                            // ��������
  FGLNMap.Add('������ 109 & ����� 101 ���������=24');                 // ������
  FGLNMap.Add('������ 109 & ����� 101=24');                           // ������
  FGLNMap.Add('������ 101 & �����=24');                               // ������
  FGLNMap.Add('�������� ������� ������=99');                          // ��������
  FGLNMap.Add('14� ���.���.���� ���/�����-��������� �� 60 267=99');   // ��������
  FGLNMap.Add('14� ���.�O ���/�����-��������� �� 60 267 TK57001=99'); // ��������
}

end;
(*----------------------------------------------------------------------------*)
procedure TNedeltzidisDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate,              1, 81, 8));
//  FItemList.Add(TFileItem.Create(itDocType,           1, 15, 3));
  FItemList.Add(TFileItem.Create(itDocType,           1, 68, 3));
  FItemList.Add(TFileItem.Create(itDocId,             1, 71, 7));
  FItemList.Add(TFileItem.Create(itGLN,               1, 265, 10));    // GLN
//  FItemList.Add(TFileItem.Create(itGLN,               1, 265, 50));    // GLN
  FItemList.Add(TFileItem.Create(itPayType,           1, 0, 0));

  { detail }
  FItemList.Add(TFileItem.Create(itCode,              2, 15, 15));   // ����� lookup select
//  FItemList.Add(TFileItem.Create(itBarcode,           2, 0, 0));
  FItemList.Add(TFileItem.Create(itQty,               2, 30, 12));
  FItemList.Add(TFileItem.Create(itPrice,             2, 54, 12));
  FItemList.Add(TFileItem.Create(itVAT,               2, 138, 12));  // percent
  FItemList.Add(TFileItem.Create(itDisc,              2, 78, 12));   // disc value
  FItemList.Add(TFileItem.Create(itDisc2,             2, 90, 12));   // disc2 value
  FItemList.Add(TFileItem.Create(itDisc3,             2, 102, 12));  // disc3 value
  FItemList.Add(TFileItem.Create(itLineValue,         2, 126, 12));  // ����� ��������� �� ���������
  FItemList.Add(TFileItem.Create(itMeasUnit,          2, 162, 3));
end;







{ TNedeltzidisReader }
(*----------------------------------------------------------------------------*)
constructor TNedeltzidisReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.Nedeltzidis');
end;
(*----------------------------------------------------------------------------
function TNedeltzidisReader.ResolveGLN: Boolean;
var
  Value: string;
begin
  if (FDescriptor.GLNMap.IndexOfName(GLN) = -1) then
    Result := False
  else begin
    Value  := FDescriptor.GLNMap.Values[GLN];
    Result := TryStrToInt(Value, GlnId);
  end;
end;  *)
(*----------------------------------------------------------------------------*)
function TNedeltzidisReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

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

  { ������� �� ����������� ��� ��������� ������ �������. }
  if (SupMatCode = '41.023') or (SupMatCode = '53.052') then begin
    MatCode := 'MULTI CODE';
//    FManager.Log(Self, Format('MULTI CODE ERROR:---------SupCode: %10s, Date1: %10s, RelDoc: %5s, %-10s, SupMatCode: %-10s',
//                 [SupCode, Utls.DateToStrSQL(DocDate, False), DocType, RelDoc, SupMatCode]));
    FManager.Log(Self, Format('MULTI CODE ERROR:---------SupCode: %10s, Date1: %10s, RelDoc: %5s, %-10s, SupMatCode: %-10s',
                 [SupCode, DateToStrSQL(DocDate, False), DocType, RelDoc, SupMatCode]));
    Result := True;
  end

  else

  begin

  // ������������� ������� ��� ������� ������ �������� 250 ��.
//    if (SupMatCode = '54.062') then
//      SupMatCode := '54.012';

  // ������������� ������� ��� �������������� ������ �������
//    if (SupMatCode = '54.017') then
//      SupMatCode := '54.013';

  // ������������� ������� ��� ���� ����� ������� �������
    if (SupMatCode = '41.025') then
      SupMatCode := '41.014';

  // ������������� ������� ��� ���� ����� ������� �������
    if (SupMatCode = '41.026') then
      SupMatCode := '41.015';

  // ������������� ������� ��� ���� ����� ���� �������
    if (SupMatCode = '41.027') then
      SupMatCode := '41.016';

  // ������������� ������� ��� �� stand.
    if (SupMatCode = '90.008') or (SupMatCode = '00.075') or (SupMatCode = '00.117')
                               or (SupMatCode = '00.142') or (SupMatCode = '00.191')
                               or (SupMatCode = '00.241') or (SupMatCode = '60.243')
                               or (SupMatCode = '60.535') or (SupMatCode = '60.777') then
      SupMatCode := '00.189';
    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);
    if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
  end;

end;
(*----------------------------------------------------------------------------*)
function TNedeltzidisReader.GetMeasUnitAA: Integer;
var
  S : string;
begin
  S := GetStrDef(fiMeasUnit, '000');

  if (S <> '000') then
  begin
    S      := FDescriptor.MeasUnitMap.Values[S];
    if S = '' then
      S := '���';
    Result := FManager.GetMaterialMeasureUnitAA(MatAA, S);
  end else
    Result := -1;

end;
(*----------------------------------------------------------------------------*)
function TNedeltzidisReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 24112011

  Y := Copy(S, 5, 4);
  M := Trim(Copy(S, 3, 2));
  D := Trim(Copy(S, 1, 2));
  Result := EncodeDate(
                       StrToInt(Y),
                       StrToInt(M),
                       StrToInt(D)
                       );
end;




initialization
  FileDescriptors.Add(TNedeltzidisDescriptor.Create);

end.
