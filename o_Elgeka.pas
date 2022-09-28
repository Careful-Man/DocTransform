unit o_Elgeka;

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
  TElgekaDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TElgekaReader = class(TPurchaseReader)
 protected
   function  GetLineMarker(): string; override;
//   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   procedure LoadFromFile(); override;
   function  GetMeasUnitAA: Integer; override;
//   function  GetGLN(): string; override;
   function  GetDocNo: string; override;
   function  GetPayType: string; override;
//   function  GetRelDocNum: string; override;
   function  DocStrToDate(S: string): TDate; override;
   function  GetPrice: double; override;    // added by yy
   function  GetQty: double; override;      // added by yy
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;


implementation


{ TElgekaDescriptor }
(*----------------------------------------------------------------------------*)
constructor TElgekaDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.������';
  FFileName        := '������\inv_header*.txt';
//  FFileNameDetail  := '������\inv_lines*.txt';
  FKind            := fkDelimited;
  FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '094069931';
//  FNeedsMapGln     := True;
//  FIsMultiSupplier := True;

  FNeedsMeasUnitConversion := True;
//  FNeedsMeasUnitConversion := False;

  FNeedsMapPayMode := True;
  FPayModeMap.Add('10=�������');
  FPayModeMap.Add('20=��� �������');
  FPayModeMap.Add('30=��� �������');

  FDocTypeMap.Add('1=���');
  FDocTypeMap.Add('2=���');
  FDocTypeMap.Add('3=���');
  FDocTypeMap.Add('4=���');
  FDocTypeMap.Add('6=���');
  FDocTypeMap.Add('7=���');


    FMeasUnitMap.Add('1=���');
    FMeasUnitMap.Add('3=���');
    FMeasUnitMap.Add('4=���');
    FMeasUnitMap.Add('5=���');
    FMeasUnitMap.Add('6=���');


end;
(*----------------------------------------------------------------------------*)
procedure TElgekaDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate        ,1   ,14-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,11-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,13-1));
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,10-1));   // GLN
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,25-1));


  { detail }
  FItemList.Add(TFileItem.Create(itCode             ,2  ,3-1));  //*
//  FItemList.Add(TFileItem.Create(itBarcode          ,2  ,4-1));  //   BarCode
  FItemList.Add(TFileItem.Create(itQty              ,2  ,11-1)); //*
  FItemList.Add(TFileItem.Create(itPrice            ,2  ,16-1)); //*
  FItemList.Add(TFileItem.Create(itVAT              ,2  ,59-1)); //*
  FItemList.Add(TFileItem.Create(itDisc             ,2  ,21-1)); //*     // Value
  FItemList.Add(TFileItem.Create(itDisc2            ,2  ,27-1)); //*     // Value
  FItemList.Add(TFileItem.Create(itDisc3            ,2  ,33-1)); //*     // Value
  FItemList.Add(TFileItem.Create(itLineValue        ,2  ,57-1)); //*  // ���������� �� 56 ���� ������� �� ����� ��� 57
  FItemList.Add(TFileItem.Create(itMeasUnit         ,2  ,12-1)); //*
  FItemList.Add(TFileItem.Create(itMeasUnitRelation ,2  ,14-1)); //*


end;



{ TElgekaReader }
(*----------------------------------------------------------------------------*)
constructor TElgekaReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.������');
end;
(*----------------------------------------------------------------------------*)
function TElgekaReader.GetLineMarker: string;
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
//function TElgekaReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
//
//  function GetMatCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
//  begin
//    Result  := False;
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
////var OriginalSupMatCode : string;
//
//begin
//  Result := False;
//
////  OriginalSupMatCode := SupMatCode;
//// ������������� ������� ��� �� stand
//  if (SupMatCode = '1413153') then
//    SupMatCode  := '461017';
//
//  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);
//
//  if not Result then
//{    if SupMatCode = OriginalSupMatCode then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]))
//    else
//    if SupMatCode <> OriginalSupMatCode then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s, or %s',
//                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode, OriginalSupMatCode]));
//  ASupMatCode := SupMatCode;}
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
//end;
(*----------------------------------------------------------------------------*)
function TElgekaReader.GetMeasUnitAA: Integer;
var
  S : string;

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
  S := GetStrDef(fiMeasUnit, '000');

  if (S <> '000') then
  begin
    S      := FDescriptor.MeasUnitMap.Values[S];
    if S = '' then
      S := '���';
// ��� �������� �������� ��� ������, ���' ��� ��� ��� ������ ���, ����� ������� ���.
// � ���������� �� ����� : 106153, 102070, 102514, 107017, 107034.
    if (GetCode = '1412116') or (GetCode = '1414112') or (GetCode = '1414118') or (GetCode = '1418123')
    or (GetCode = '1412122')
    then
      S := '���';

    Result := FManager.GetMaterialMeasureUnitAA(MatAA, S);
  end else
    Result := -1;

end;
(*----------------------------------------------------------------------------*)
(*function TElgekaReader.GetGLN: string;
begin
  Result := GetStrDef(fiGLN);
  Result := MidString(Result, 6, 2);
end;*)
(*----------------------------------------------------------------------------*)
function TElgekaReader.GetDocNo: string;
begin
  Result := GetStrDef(fiDocId);
end;
(*----------------------------------------------------------------------------*)
function TElgekaReader.GetPayType: string;
begin
  if (FDescriptor.NeedsMapPayMode) then
  begin
    Result := GetStrDef(fiPayType);
    if Result = '' then
      Result := '20';
    if (FDescriptor.PayModeMap.IndexOfName(Result) = -1) then
      raise Exception.CreateFmt('Invalid PayType. Map not found: %s', [Result]);

    Result :=  FDescriptor.PayModeMap.Values[Result];
  end else begin
    Result :=  '��� �������';
  end;
end;
(*----------------------------------------------------------------------------*)
{function TElgekaReader.GetRelDocNum: string;
begin
//  Result := GetDocType + GetDocNo;
  Result := itDocType + itDocId;
end;}
(*----------------------------------------------------------------------------*)
(* ������� ��� ��� ������ ��� Master �� DocChanger.
   ����� �� DocChanger ���� ��� Detail ��� ���� ������ ��� ������ ��� ��������
   ��� ���� ������. ���������� ���� ��������������� ��� ������� ���� �� ������
   �� ����� ��' �����.

   //y  *** SOS! ������� hard-coded o delimiter ��� �������� block.
   //y  *** �� ������ �� ��� ������������� ��� ����� ������������.
*)
procedure TElgekaReader.LoadFromFile;
var
  DataListMaster : TStringList;
  DataListDetail : TStringList;
  DocChanger     : string;
  ALine          : string;
  i, j, p        : integer;
  JustName       : string;
  JustExtension  : string;
begin
  JustName := ExtractFileName(FFileName);
  JustExtension := ExtractFileExt(JustName);
  p := pos('.', JustName);
  // ������ ����� ���� �� ����� ����� ��� ���������.
  JustName := LeftString(JustName, p-1);
  JustName := RightString(JustName, Length(JustName) - Length('inv_header'));
  FFileNameDetail := FInputPath + 'inv_lines' + JustName + JustExtension;

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
    DataList.Add('H' + ALine);
    p := pos('#', ALine);
    DocChanger := LeftString(ALine, p-1);
    for j := 0 to DataListDetail.Count - 1 do
    begin
      ALine := DataListDetail.Strings[j];
      p := pos('#', ALine);
      if trim(LeftString(ALine, p-1)) = DocChanger then
        DataList.Add('D' + ALine);
    end;

  end;

  FTotal := DataList.Count;

  FreeAndNil(DataListMaster);
  FreeAndNil(DataListDetail);
end;
(*----------------------------------------------------------------------------*)
function TElgekaReader.DocStrToDate(S: string): TDate;
begin
  // 20120912

  Result := EncodeDate(StrToInt(Copy(S, 1, 4)),
                       StrToInt(Copy(S, 5, 2)),
                       StrToInt(Copy(S, 7, 2)));
end;

(*----------------------------------------------------------------------------*)
// FOLLOWING BLOCK ADDED BY ME //YY
(*----------------------------------------------------------------------------*)
function TElgekaReader.GetQty: Double;
var
  S : string;
  C : string;    //yy

begin
  S := GetStrDef(fiQty, '0');
  S := DotToComma(S);
  C := GetStrDef(fiCode);         //yy

  if C = '1412105' then           //yy   ������� ��� �� �� 107032 ��� � ������ �� ������� ��� 10�
  Result := StrToFloat(S) * 10    //yy   ����� �� ������ ������� �������� �� ������ ����� ��� EDI
  else                            //yy   ����� ������ � ����� �� �������� ���� ���� �� �� ����
  Result := StrToFloat(S);
end;

(*----------------------------------------------------------------------------*)
// FOLLOWING BLOCK ADDED BY ME //YY
(*----------------------------------------------------------------------------*)

function TElgekaReader.GetPrice: double;
var
  S : string;
  C : string;    //yy

begin
  S := GetStrDef(fiPrice, '0');
  S := DotToComma(S);
  C := GetStrDef(fiCode);           //yy


  if C = '1412105'  then            //yy  ������� ��� �� �� 107032 ��� � ������ �� ������� ��� 10�
  Result := StrToFloat(S) / 10      //yy  ����� �� ������ ������� �������� �� ������ ����� ��� EDI
  else                              //yy  ����� ������ � ����� �� �������� ���� ���� �� �� ����
  Result := StrToFloat(S)

end;

(*----------------------------------------------------------------------------*)

initialization
  FileDescriptors.Add(TElgekaDescriptor.Create);

end.

