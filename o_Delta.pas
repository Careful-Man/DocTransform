unit o_Delta;

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

  ,JclFileUtils
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
  TDocBehaviour = (dbDAP, dbTIM, dbUndefined);

  TDeltaDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TDeltaReader = class(TPurchaseReader)
  const
    DAPMarker = 'D';
    TIMMarker = 'I';
 protected
   function  GetDocBehaviour: TDocBehaviour;
   function  GetLineMarker: string; override;
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   procedure LoadFromFile; override;
   function  GetDocType: string; override;
   function  GetVAT(MatCode: string): string; override;
   function  GetLineValue: Double; override;
   function  DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;


implementation


{ TDeltaDescriptor }
(*----------------------------------------------------------------------------*)
constructor TDeltaDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.�����';
  FFileName        := '�����\HEADER-EL094098834*.*';
//  FFileNameDetail  := 'CHIPITA\inv_lines*.txt';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'L';
  FAFM             := '099771194';
  FNeedsMapGln     := True;
//  FIsMultiSupplier := True;
//  FIsOEM           := False;

  FNeedsMapPayMode := True;
  FPayModeMap.Add('A=�������');
  FPayModeMap.Add('C=��� �������');

  FDocTypeMap.Add('ZIDA=���');
  FDocTypeMap.Add('ZITP=���');
  FDocTypeMap.Add('ZDA6=���');
  FDocTypeMap.Add('ZITD=���');
  FDocTypeMap.Add('ZIR0=���');
  FDocTypeMap.Add('ZDP7=���');
  FDocTypeMap.Add('ZIRB=���');


  FMeasUnitMap.Add('ST=���');


  FGLNMap.Add('0000000000001=1');     //    ������� 18
  FGLNMap.Add('0000000000002=2');     //    ��������� 1
  FGLNMap.Add('0000000000003=3');     //    ���������� 46
  FGLNMap.Add('0000000000005=5');     //    25 ������� 113-115
  FGLNMap.Add('0000000000006=6');     //    ������� 38 & ������
  FGLNMap.Add('0000000000000=6');    //    ������� 38 & ������
  FGLNMap.Add('0000000000007=7');     //    �������� 92
  FGLNMap.Add('0000000000008=8');     //    �������� 12
  FGLNMap.Add('0000000000009=9');     //    �������� 154
  FGLNMap.Add('0000000000010=10');    //    ��� ������
  FGLNMap.Add('0000000000012=12');    //    ������� 6
  FGLNMap.Add('0000000000013=13');    //    ��������� 14
  FGLNMap.Add('0000000000015=15');    //    ���������� 27 & ����
  FGLNMap.Add('0000000000017=17');    //    ������ 43
  FGLNMap.Add('0000000000019=19');    //    ��������������� 5
  FGLNMap.Add('0000000000020=20');    //    ��������� 6
  FGLNMap.Add('0000000000021=21');    //    �. ���������� 9 ������
  FGLNMap.Add('0000000000022=22');    //    ������� 80 ���������
  FGLNMap.Add('0000000000023=23');    //    �������� 37 ���������
  FGLNMap.Add('0000000000024=24');    //    ������ 109 ���������
  FGLNMap.Add('0000000000025=25');    //    ���������� 19 �����������
  FGLNMap.Add('0000000000026=26');    //    ������ ������




end;
(*----------------------------------------------------------------------------*)
procedure TDeltaDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate        ,1   ,4-1));   // OK
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,2-1));   // OK
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,3-1));   // OK
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,1-1));   // OK
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,19-1));  // OK
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,5-1));   // OK


  { detail }
  FItemList.Add(TFileItem.Create(itCode             ,2  ,3-1));  // OK
  FItemList.Add(TFileItem.Create(itQty              ,2  ,7-1));  // OK
//  FItemList.Add(TFileItem.Create(itPrice            ,2  ,16-1));
  FItemList.Add(TFileItem.Create(itVAT              ,2  ,10-1)); // OK   // Percent
  FItemList.Add(TFileItem.Create(itDisc             ,2  ,12-1)); // OK   // Percent
//  FItemList.Add(TFileItem.Create(itDisc2            ,2  ,27-1));
//  FItemList.Add(TFileItem.Create(itDisc3            ,2  ,33-1));
  FItemList.Add(TFileItem.Create(itLineValue        ,2  ,6-1));  // OK
  FItemList.Add(TFileItem.Create(itMeasUnit         ,2  ,9-1));  // OK
  FItemList.Add(TFileItem.Create(itMeasUnitRelation ,2  ,8-1));  // ??????????


end;



{ TDeltaReader }
(*----------------------------------------------------------------------------*)
constructor TDeltaReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.�����');
end;
(*----------------------------------------------------------------------------*)
function TDeltaReader.GetDocBehaviour: TDocBehaviour;
var
  Marker: string;

  function BehaviourMarker: string;
  begin
    Result := '';
    if (FDescriptor.SeparationMode = smMarker) then
    begin
      if (FDescriptor.Kind = fkDelimited) then
        Result := Trim(ValueList[0])
      else if (FDescriptor.Kind = fkFixedLength) then
        Result := Trim(DataList[LineIndex])[1];
    end;
    Result := MidString(Result, 2, 1);
  end;

begin
  Marker := BehaviourMarker;
  Result := dbUndefined;
  if Marker = DAPMarker then
    Result := dbDAP
  else if Marker = TIMMarker then
    Result := dbTIM;
end;
(*----------------------------------------------------------------------------*)
function TDeltaReader.GetLineMarker: string;
begin
  Result := '';
  if (FDescriptor.SeparationMode = smMarker) then
  begin
    if (FDescriptor.Kind = fkDelimited) then
      Result := Trim(ValueList[0])
    else if (FDescriptor.Kind = fkFixedLength) then
      Result := Trim(DataList[LineIndex])[1];
  end;
  Result := LeftString(Result, 1);
end;
(*----------------------------------------------------------------------------*)
function TDeltaReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

  function GetMatCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
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

  end;

begin
  Result := False;
  SupMatCode := TrimLeftZeroes(StripInt(SupMatCode));

  begin
  // ������������� ��� ���.���.����� �DV��C� ��.���.����.100% ���.1LT
    if (SupMatCode = '720349') then
      SupMatCode := '720452';

  // ��� ������� ���� ��� ����� ��������������� ��� �� ����� ���������
  // ��� ����� ��� �����������.

    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

    if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
  end;

end;
(*----------------------------------------------------------------------------*)
function TDeltaReader.GetDocType: string;
var DocType: string;
    DocBehaviour: TDocBehaviour;
begin
  DocType := GetStrDef(fiDocType);
  DocBehaviour := GetDocBehaviour;
// �� � ����������� ����� ��� ���� �� � ����� ����� ���, ��� ���� ���.
  if DocBehaviour = dbDAP then
  begin
    if (DocType = 'ZITP') or
       (DocType = 'ZDA6') or
       (DocType = 'ZITD')
     then Result := 'ZIDA'
  end
  else
  if DocBehaviour = dbTIM then
    Result := DocType;
end;
(*----------------------------------------------------------------------------*)
(* ��� ��� ����� ��� ���� ������ ����� ��� ������� �� ��� ������ -------------*)
function TDeltaReader.GetVAT(MatCode: string): string;
begin
  Result := FloatToStr(StripReal(GetStrDef(fiVAT)));
end;
(*----------------------------------------------------------------------------*)
function TDeltaReader.GetLineValue: Double;
var
  VATCategory: double;
  TotalValue: double;

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

begin
  TotalValue := InternalGetLineValue();
  VATCategory := StrToFloat(GetVAT(MatCode));
  TotalValue := TotalValue / (1+(VATCategory/100));
  Result := TotalValue;
end;
(*----------------------------------------------------------------------------*)
procedure TDeltaReader.LoadFromFile;
var
  DataListMaster : TStringList;
  DataListDetail : TStringList;
  DocChanger     : string;
  ALine          : string;
  i, j, p        : integer;
  JustFilePath   : string;
  JustHeaderName : string;
  JustLineName   : string;
  JustExtension  : string;
  sr             : TSearchRec;

  function DocExists(ALine: string): Boolean;
  var
    i: integer;
    p: integer;
    NewDocChanger: string;
    OldDocChanger: string;
  begin
    Result := False;
    p := pos(FDescriptor.Delimiter, ALine);
// �������� �� 'H' ����� ���� �� �������� ���� �� Headers ��� ��� ��� �� Lines.
    NewDocChanger := 'H' + LeftString(ALine, p-1);
    for i := 0 to DataList.Count - 1 do
    begin
      p := pos(FDescriptor.Delimiter, DataList[i]);
      OldDocChanger := LeftString(DataList[i], p-1);
      if NewDocChanger = OldDocChanger then begin
        Result := True;
        Exit;
      end;
    end;
  end;

begin
  JustFilePath := ExtractFilePath(FFileName);
  JustHeaderName := ExtractFileName(FFileName);
  JustExtension := ExtractFileExt(JustHeaderName);
  FileCopy(PChar(PathAddSeparator(JustFilePath) + JustHeaderName), PChar(PathAddSeparator(JustFilePath) + 'inv_header.dat'), True);
  FFileName := PathAddSeparator(JustFilePath) + 'inv_header.dat';

// ��� ���������� �� ����� ��� header file, ��� ���������� �� ����� ��� line file.
// ��� �� ���� ���� ������ ��� copy ��� ������� �� ���������������� wild card,
// ���� �� ������������ ���� ������ �����.
// ������ ������ �� ������������� �� FindFiles � �� FindFirst, ���� ���� ��� ������ ����.
  FFileNameDetail := PathAddSeparator(JustFilePath) + 'LINE-EL094098834*' + JustExtension;
  if FindFirst(FFileNameDetail, faAnyFile, sr) = 0 then
    FFileNameDetail := sr.Name;

  FileCopy(PChar(PathAddSeparator(JustFilePath) + FFileNameDetail), PChar(PathAddSeparator(JustFilePath) + 'inv_lines.dat'), True);
  FFileNameDetail := PathAddSeparator(JustFilePath) + 'inv_lines.dat';

  DataListMaster := TStringList.Create;
  DataListDetail := TStringList.Create;

  DataListMaster.LoadFromFile(FFileName);
  if (FDescriptor.IsOem) then
//    DataListMaster.Text := Utls.OemToAnsi(DataList.Text)
    DataListMaster.Text := OemToAnsi(DataList.Text)
  else if (FDescriptor.IsUnicode) then
    DataListMaster.Text := UTF8ToANSI(DataList.Text);

  DataListDetail.LoadFromFile(FFileNameDetail);
  if (FDescriptor.IsOem) then
//    DataListDetail.Text := Utls.OemToAnsi(DataList.Text)
    DataListDetail.Text := OemToAnsi(DataList.Text)
  else if (FDescriptor.IsUnicode) then
    DataListDetail.Text := UTF8ToANSI(DataList.Text);

  for i := 0 to DataListMaster.Count - 1 do
  begin
    ALine := DataListMaster.Strings[i];
    if not DocExists(ALine) then
    begin
      DataList.Add('H' + ALine);
      p := pos(FDescriptor.Delimiter, ALine);
      DocChanger := LeftString(ALine, p-1);
      for j := 0 to DataListDetail.Count - 1 do
      begin
        ALine := DataListDetail.Strings[j];
        p := pos(FDescriptor.Delimiter, ALine);
        if LeftString(ALine, p-1) = DocChanger then
          DataList.Add('L' + ALine);
      end;
    end;
  end;
  DataList.SaveToFile(PathAddSeparator(JustFilePath) + 'DataList.dat');

  FTotal := DataList.Count;

  FreeAndNil(DataListMaster);
  FreeAndNil(DataListDetail);
end;
(*----------------------------------------------------------------------------*)
function TDeltaReader.DocStrToDate(S: string): TDate;
begin
  // 20120912

  Result := EncodeDate(StrToInt(Copy(S, 1, 4)),
                       StrToInt(Copy(S, 5, 2)),
                       StrToInt(Copy(S, 7, 2)));
end;




initialization
  FileDescriptors.Add(TDeltaDescriptor.Create);

end.

