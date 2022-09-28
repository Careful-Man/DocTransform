unit o_Moumtzis;

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
  TMoumtzisDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TMoumtzisReader = class(TPurchaseReader)
 protected
   function GetLineMarker(): string; override;
   function GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function GetLineValue: Double; override;
   function GetPayType: string; override;
   function DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;



implementation




{ TMoumtzisDescriptor }
(*----------------------------------------------------------------------------*)
constructor TMoumtzisDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.��������';
  FFileName        := '��������\*.txt';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '117887290';

  FNeedsMapPayMode := True;
  FPayModeMap.Add('1=�������');
  FPayModeMap.Add('������� 30 ������=��� �������');
  FPayModeMap.Add('3=��� �������'); // �� ������������


  FDocTypeMap.Add('���������=���');
  FDocTypeMap.Add('���������-��=���');
  FDocTypeMap.Add('��������� ���������-��=���');
  FDocTypeMap.Add('��������� ��������� - ��������=���');
  FDocTypeMap.Add('��������� ���������=���');
  FDocTypeMap.Add('������� �� �������������� ���������� (��)=���');



  FMeasUnitMap.Add('�������=���');


  FNeedsMapGln     := True;

  FGLNMap.Add('03=1');
  FGLNMap.Add('12=2');
  FGLNMap.Add('11=3');
  FGLNMap.Add('02=5');
  FGLNMap.Add('19=6');
  FGLNMap.Add('01=7');
  FGLNMap.Add('05=8');
  FGLNMap.Add('13=9');
//  FGLNMap.Add('009=10');
  FGLNMap.Add('06=12');
  FGLNMap.Add('04=13');
  FGLNMap.Add('08=15');
  FGLNMap.Add('09=17');
  FGLNMap.Add('16=19');
  FGLNMap.Add('15=20');
  FGLNMap.Add('17=21');
  FGLNMap.Add('18=22');
  FGLNMap.Add('10=23');
  FGLNMap.Add('07=24'); //14
  FGLNMap.Add('14=24'); //14
  FGLNMap.Add('20=25'); //14
  FGLNMap.Add('21=26'); //14

end;
(*----------------------------------------------------------------------------*)
procedure TMoumtzisDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate        ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,4-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,5-1));
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,6-1));
{
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,4-1));
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,5-1));
}
  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  ,2-1));
  FItemList.Add(TFileItem.Create(itQty          ,2  ,5-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,6-1));
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,7-1));
  FItemList.Add(TFileItem.Create(itDisc         ,2  ,8-1)); // Percent
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,11-1));
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,12-1));

end;





{ TMoumtzisReader }
(*----------------------------------------------------------------------------*)
constructor TMoumtzisReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.��������');
end;
(*----------------------------------------------------------------------------*)
function TMoumtzisReader.GetLineMarker: string;
begin
  Result := DataList[LineIndex][1];
end;

function TMoumtzisReader.GetLineValue: Double;
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
function TMoumtzisReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string;
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
//  SupMatCode := StripInt(SupMatCode);

  begin
  // ������������� ��� ���/��� �������� ������ �������
    if (SupMatCode = '1-01-0001') then
      SupMatCode := '1-01-0022';

  // ������������� ��� ���/��� ���������
    if (SupMatCode = '1-01-0003') then
      SupMatCode := '1-01-0030';

  // ������������� ��� ���/��� ���������
    if (SupMatCode = '1-01-0004') then
      SupMatCode := '1-01-0031';

  // ������������� ��� ���/��� ���������
    if (SupMatCode = '1-01-0005') then
      SupMatCode := '1-01-0021';

  // ������������� ��� ���/��� �������
    if (SupMatCode = '1-01-0006') then
      SupMatCode := '1-01-0023';

  // ������������� ��� ���/��� ��������
    if (SupMatCode = '1-01-0008') then
      SupMatCode := '1-01-0025';

  // ������������� ��� ���/��� �������
    if (SupMatCode = '1-01-0009') then
      SupMatCode := '1-01-0026';

  // ������������� ��� ���/��� ������ �������
    if (SupMatCode = '1-01-0010') then
      SupMatCode := '1-01-0022';

  // ������������� ��� ���/��� ��������
    if (SupMatCode = '1-01-0011') then
      SupMatCode := '1-01-0024';

  // ������������� ��� ���/��� �����������
    if (SupMatCode = '1-01-0014') then
      SupMatCode := '1-01-0028';

  // ������������� ��� ���/��� ����������� 500��.
    if (SupMatCode = '1-01-0015') then
      SupMatCode := '1-01-0029';

  // ������������� ��� ���/��� ��������� ������ ��.
    if (SupMatCode = '1-01-0016') then
      SupMatCode := '1-01-0032';

  // ������������� ��� ���������
    if (SupMatCode = '1-03-0005') then
      SupMatCode := '1-03-0032';

  // ������������� ��� ������ ��������� 70-80 ����.
    if (SupMatCode = '1-03-0020') then
      SupMatCode := '1-03-0031';


    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

    if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
  end;
end;
(*----------------------------------------------------------------------------*)
function TMoumtzisReader.GetPayType: string;
begin
  Result := '������� 30 ������';
end;
(*----------------------------------------------------------------------------*)
function TMoumtzisReader.DocStrToDate(S: string): TDate;
var ADay, AMonth, AYear : word;
    p : integer;
begin
  S := StripDate(S);

  // 04/01/2016   16/01/2017

  // �� ����� ���� ��� �� ����� �� ����, �� ������� ����� �����.
  AYear := StrToInt(RightString(S, 4));
// ��� �o string ��������� �� ��������� ������� ��� ����� ���� �� ��� ������.
  S := LeftString(S, Length(S)-5);
  p := pos('/', S);
  ADay := StrToInt(LeftString(S, p-1));
  AMonth := StrToInt(RightString(S, Length(S)-p));
  Result := EncodeDate(AYear, AMonth, ADay);
end;
(*----------------------------------------------------------------------------*)



initialization
  FileDescriptors.Add(TMoumtzisDescriptor.Create);

end.
