unit o_Amvrosiadis;

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
  ,o_Descriptors
  ,o_Managers
  ,o_Purchases
  ,uStringHandlingRoutines
  ;

type
(*----------------------------------------------------------------------------
O περιγραφέας θα πρέπει να έχει καταστάσεις
  NoLine
  HeaderLine
  DetailLine
  SkipLine
και ο αναγνώστης να του περνάει κάθε γραμμή και να τον συμβουλεύεται

*)
  TAmvrosiadisDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TAmvrosiadisReader = class(TPurchaseReader)
 protected
   function  GetLineMarker(): string; override;
   //function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   procedure LoadFromFile(); override;
   //function  GetGLN(): string; override;
   function  GetDocNo: string; override;
   //function  GetPayType: string; override;
   function  DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;


implementation


{ TAmvrosiadisDescriptor }
(*----------------------------------------------------------------------------*)
constructor TAmvrosiadisDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.Amvrosiadis';
  FFileName        := 'ΑΜΒΡΟΣΙΑΔΗΣ\inv_header*.txt';
//  FFileNameDetail  := 'Amvrosiadis\inv_lines*.txt';
  FKind            := fkDelimited;
  FDelimiter       := #9;
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '081932139';
//  FNeedsMapGln     := True;
//  FIsMultiSupplier := True;

  //FNeedsMapPayMode := True;
  //FPayModeMap.Add('xx=ΜΕΤΡΗΤΑ');          //Υ ΜΟΝΟ ΕΠΙ ΠΙΣΤΩΣΕΙ  = 30
  //FPayModeMap.Add('30=ΕΠΙ ΠΙΣΤΩΣΗ');

  FDocTypeMap.Add('ΧΧΧ=ΔΑΠ');        //Υ ΔΕΝ ΕΧΕΙ ΑΚΟΜΑ
  FDocTypeMap.Add('ΧΧΧ=ΤΙΜ');        //Υ ΔΕΝ ΕΧΕΙ ΑΚΟΜΑ
  FDocTypeMap.Add('3=ΤΔΑ');
  FDocTypeMap.Add('4=ΠΕΠ');
  FDocTypeMap.Add('6=ΠΕΚ');
  FDocTypeMap.Add('???=ΠΕΔ');


  FMeasUnitMap.Add('1=ΤΕΜ');
  FMeasUnitMap.Add('7=ΚΙΛ');
  FMeasUnitMap.Add('ΧΧΧ=ΛΙΤ');
  FMeasUnitMap.Add('ΧΧΧ=ΜΕΤ');
  FMeasUnitMap.Add('ΧΧΧ=ΚΙΒ');


end;
(*----------------------------------------------------------------------------*)
procedure TAmvrosiadisDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate        ,1   ,12-1));  //ok
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,9-1));   //ok
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,11-1));  //ok
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,1-1));   //ok
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,6-1));   //ok
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,22-1));  //ok


  { detail }
  FItemList.Add(TFileItem.Create(itCode             ,2  ,3-1)); //ok
  FItemList.Add(TFileItem.Create(itQty              ,2  ,8-1)); //ok
  FItemList.Add(TFileItem.Create(itPrice            ,2  ,9-1)); //ok
  FItemList.Add(TFileItem.Create(itVAT              ,2  ,24-1)); //ok
  FItemList.Add(TFileItem.Create(itDisc             ,2  ,10-1)); // 10 = allow_percent1
  FItemList.Add(TFileItem.Create(itDisc2            ,2  ,11-1)); // 11 = allow_amount1
//  FItemList.Add(TFileItem.Create(itDisc3            ,2  ,12-1)); //unused
  FItemList.Add(TFileItem.Create(itLineValue        ,2  ,28-1)); //ok
  FItemList.Add(TFileItem.Create(itMeasUnit         ,2  ,6-1)); //ok
  //FItemList.Add(TFileItem.Create(itMeasUnitRelation ,2  ,14-1)); //*  // Τεμάχια ανά συσκευασία παράδοσης


end;



{ TAmvrosiadisReader }
(*----------------------------------------------------------------------------*)
constructor TAmvrosiadisReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.Amvrosiadis');
end;
(*----------------------------------------------------------------------------*)
function TAmvrosiadisReader.GetLineMarker: string;
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
(*----------------------------------------------------------------------------*
function TAmvrosiadisReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

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
  SupMatCode := StripInt(SupMatCode);


  // Αντικατάσταση για 7DAYS ΤΣΟΥΡΕΚΙ ΚΛΑΣΙΚΟ 380ΓΡ (ΛΤ 2,50Ε)
    if (SupMatCode = '76611') then
      SupMatCode := '76652';

  // Αντικατάσταση για
    if (SupMatCode = '52641') then
      SupMatCode := '52644';

  // Αντικατάσταση για
    if (SupMatCode = '57625') then
      SupMatCode := '57626';

  // Αντικατάσταση για
    if (SupMatCode = '71811') then
      SupMatCode := '71816';


    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

    if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
//  end;

end;
(*----------------------------------------------------------------------------*
function TAmvrosiadisReader.GetGLN: string;
var
  s: string;
  w: string;
begin
  s := GetStrDef(fiGLN);
  w := MidString(s, 6, 2);
  if w = '00' then
    w := RightStr(s, 2);
  Result := w;
end;
(*----------------------------------------------------------------------------*)
function TAmvrosiadisReader.GetDocNo: string;
begin
  Result := GetStrDef(fiDocId);
end;
(*----------------------------------------------------------------------------*
function TAmvrosiadisReader.GetPayType: string;
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
    Result :=  'ΕΠΙ ΠΙΣΤΩΣΗ';
  end;
end;
(*----------------------------------------------------------------------------*)
(* Διαβάζω από μία γραμμή του Master το DocChanger.
   Ψάχνω το DocChanger μέσα στο Detail και κάθε γραμμή που βρίσκω την προσθέτω
   στο ίδιο αρχείο. Ουσιαστικά κάνω επαναδημιουργία του αρχείου όπως θα έπρεπε
   να είναι εξ' αρχής.

//y  *** SOS! Υπάρχει hard-coded o delimiter στο παρακάτω block.
//y  *** Θα πρέπει να τον αντικαταστήσω εάν είναι διαφορετικός.
*)
procedure TAmvrosiadisReader.LoadFromFile;
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
  // Έχουμε πάρει μόνο το όνομα χωρίς την προέκταση.
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
    p := pos(#9, ALine);
    DocChanger := LeftString(ALine, p-1);
    for j := 0 to DataListDetail.Count - 1 do
    begin
      ALine := DataListDetail.Strings[j];
      p := pos(#9, ALine);
      if LeftString(ALine, p-1) = DocChanger then
        DataList.Add('D' + ALine);
    end;
  end;

  FTotal := DataList.Count;

  FreeAndNil(DataListMaster);
  FreeAndNil(DataListDetail);
end;
(*----------------------------------------------------------------------------*)
function TAmvrosiadisReader.DocStrToDate(S: string): TDate;
begin
  // 20120912

  Result := EncodeDate(StrToInt(Copy(S, 1, 4)),
                       StrToInt(Copy(S, 5, 2)),
                       StrToInt(Copy(S, 7, 2)));
end;




initialization
  FileDescriptors.Add(TAmvrosiadisDescriptor.Create);

end.



