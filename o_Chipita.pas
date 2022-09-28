unit o_Chipita;

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
O περιγραφέας θα πρέπει να έχει καταστάσεις
  NoLine
  HeaderLine
  DetailLine
  SkipLine
και ο αναγνώστης να του περνάει κάθε γραμμή και να τον συμβουλεύεται

*)
  TChipitaDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TChipitaReader = class(TPurchaseReader)
 protected
   function  GetLineMarker(): string; override;
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   procedure LoadFromFile(); override;
   function  GetGLN(): string; override;
   function  GetDocNo: string; override;
   function  GetPayType: string; override;
   function  DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;


implementation


{ TChipitaDescriptor }
(*----------------------------------------------------------------------------*)
constructor TChipitaDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.CHIPITA';
  FFileName        := 'CHIPITA\inv_header*.txt';
//  FFileNameDetail  := 'CHIPITA\inv_lines*.txt';
  FKind            := fkDelimited;
  FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '996688362';
//  FNeedsMapGln     := True;
//  FIsMultiSupplier := True;

  FNeedsMapPayMode := True;
  FPayModeMap.Add('10=ΜΕΤΡΗΤΑ');
  FPayModeMap.Add('20=ΕΠΙ ΠΙΣΤΩΣΗ');

  FDocTypeMap.Add('1=ΔΑΠ');
  FDocTypeMap.Add('2=ΤΙΜ');
  FDocTypeMap.Add('3=ΤΔΑ');
  FDocTypeMap.Add('4=ΠΕΠ');
  FDocTypeMap.Add('6=ΠΕΚ');
  FDocTypeMap.Add('7=ΠΕΔ');
  FDocTypeMap.Add('11=ΠΕΚ');


  FMeasUnitMap.Add('1=ΤΕΜ');
  FMeasUnitMap.Add('3=ΚΙΒ');
  FMeasUnitMap.Add('4=ΛΙΤ');
  FMeasUnitMap.Add('5=ΜΕΤ');
  FMeasUnitMap.Add('6=ΚΙΒ');


end;
(*----------------------------------------------------------------------------*)
procedure TChipitaDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate        ,1   ,14-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,11-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,13-1));
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,24-1));   // GLN
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,25-1));


  { detail }
  FItemList.Add(TFileItem.Create(itCode             ,2  ,3-1));  //*
  FItemList.Add(TFileItem.Create(itQty              ,2  ,11-1)); //*
  FItemList.Add(TFileItem.Create(itPrice            ,2  ,16-1)); //*  // Αν πρόκειται για ΚΙΒ, εννοεί τιμή ΚΙΒ
  FItemList.Add(TFileItem.Create(itVAT              ,2  ,59-1)); //*
  FItemList.Add(TFileItem.Create(itDisc             ,2  ,21-1)); //*     // Value
  FItemList.Add(TFileItem.Create(itDisc2            ,2  ,27-1)); //*     // Value
  FItemList.Add(TFileItem.Create(itDisc3            ,2  ,33-1)); //*     // Value
  FItemList.Add(TFileItem.Create(itLineValue        ,2  ,57-1)); //*  // Αναφέρεται ως 56 αλλά δείχνει να είναι στο 57
  FItemList.Add(TFileItem.Create(itMeasUnit         ,2  ,12-1)); //*
  FItemList.Add(TFileItem.Create(itMeasUnitRelation ,2  ,14-1)); //*  // Τεμάχια ανά συσκευασία παράδοσης


end;



{ TChipitaReader }
(*----------------------------------------------------------------------------*)
constructor TChipitaReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.CHIPITA');
end;
(*----------------------------------------------------------------------------*)
function TChipitaReader.GetLineMarker: string;
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
function TChipitaReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

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

  { Θέλουμε να προβλέψουμε την περίπτωση έίδους ΣΥΛΛΟΓΗ. }
//  if (SupMatCode = '13392') or (SupMatCode = '67991') or (SupMatCode = '59090')
//  or (SupMatCode = '59583') or (SupMatCode = '78913') or (SupMatCode = '78914') then
//  begin
//    MatCode := 'MULTI CODE';
//    FManager.Log(Self, Format('MULTI CODE ERROR:---------SupCode: %10s, Date1: %10s, RelDoc: %5s, %-10s, SupMatCode: %-10s',
//                 [SupCode, DateToStrSQL(DocDate, False), DocType, RelDoc, SupMatCode]));
//    FManager.Log(Self, Format('MULTI CODE ERROR:--------- SupMatCode: %-10s',
//                 [SupMatCode]));
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
//    Result := True;
//  end

//  else

//  begin
  // Αντικατάσταση για CHIPICAO ΚΡ.ΚΑΚΑΟ 60ΓΡ  (ΝΕΟΣ)
//    if (SupMatCode = '50642') then
//      SupMatCode := '50648';

  // Αντικατάσταση για CHIPICAO ΚΡ.ΚΑΚΑΟ 60ΓΡ  (ΝΕΟΣ)
//    if (SupMatCode = '50648') then
//      SupMatCode := '50648';

  // Αντικατάσταση για CHIPICAO ΚΡ.ΚΑΚΑΟ 60ΓΡ  (ΝΕΟΣ)
//    if (SupMatCode = '50648') then
//      SupMatCode := '50642';

  // Αντικατάσταση για EXTRA ΤΥΡΟΓΑΡΙΔΑΚΙΑ 90ΓΡ+40% (ΛΤ 1Ε)
//    if (SupMatCode = '30132') then
//      SupMatCode := '30135';

  // Αντικατάσταση για EXTRA SNACK ΦΥΣΤΙΚΙ 125ΓΡ (Λ.Τ 1Ε)
//    if (SupMatCode = '30145') then
//      SupMatCode := '30140';

  // Αντικατάσταση για ΕΧΤRΑ ΤΥΡΟΓΑΡΙΔΑΚΙΑ PROMO 60ΓΡ
//    if (SupMatCode = '32133') then
//      SupMatCode := '32131';

  // Αντικατάσταση για CHIPICAO ΚΡ.ΜΙΝΙ ΚΑΚΑΟ 60ΓΡ (ΛΤ 0,50Ε)
    if (SupMatCode = '32761') then
      SupMatCode := '32763';

  // Αντικατάσταση για TSIPERS CHIPS ΡΙΓΑΝΗ 120ΓΡ (ΛΤ 1Ε)
//    if (SupMatCode = '34755') then
//      SupMatCode := '34753';

  // Αντικατάσταση για TSIPERS CHIPS ΚΛΑΣΙΚΗ 120ΓΡ (ΛΤ 1Ε)
//    if (SupMatCode = '34765') then
//      SupMatCode := '34763';

  // Αντικατάσταση για TSIPERS CHIPS BBQ 120ΓΡ (ΛΤ 1Ε)
    if (SupMatCode = '34773') then
      SupMatCode := '34771';

  // Αντικατάσταση για CHIPITA CΗΙΡS ΦΥΛ.BBQ 120ΓΡ (ΛΤ 1Ε)
//    if (SupMatCode = '35768') then
//      SupMatCode := '35763';

  // Αντικατάσταση για TSIPERS CHIPS ΚΛΑΣΙΚΗ 120ΓΡ (ΛΤ 1Ε)
//    if (SupMatCode = '37751') then
//      SupMatCode := '34765';

  // Αντικατάσταση για 7DΑΥS ΚΡ.SUPER MAX ΠΡΑΛINA 150ΓΡ(Λ.Τ.1Ε)
//    if (SupMatCode = '51019') then
//      SupMatCode := '53216';

  // Αντικατάσταση για CHIPICAO ΚΡ.ΜΙΝΙ ΚΑΚΑΟ 60ΓΡ (ΛΤ 0,50Ε)
    if (SupMatCode = '52113') then
      SupMatCode := '59916';

  // Αντικατάσταση για CHIPICAO ΚΡ.ΜΙΝΙ ΚΑΚΑΟ 60ΓΡ (ΛΤ 0,50Ε)
  // Στις 17/02 κατήργησα την αντικατάσταση γιατί η Κατερίνα είχε ανοίξει τον κωδικό.
//    if (SupMatCode = '55507') then
//      SupMatCode := '59813';

  // Αντικατάσταση για MOLTO ΚΡ.ΦΟΥΝΤ CREAM & COOKIES 110ΓΡ (Λ.Τ.1Ε)
    if (SupMatCode = '53000') then
      SupMatCode := '53029';

//  // Αντικατάσταση για MOLTO ΚΡ.ΦΟΥΝΤ CREAM & COOKIES 110ΓΡ (Λ.Τ.1Ε)
//    if (SupMatCode = '53033') then
//      SupMatCode := '53039';

  // Αντικατάσταση για MOLTO ΚΡ.DOUBLE ΒΑΝ-ΦΡΑ 80ΓΡ+40% (Λ.Τ.1Ε)
    if (SupMatCode = '53060') then
      SupMatCode := '53887';

  // Αντικατάσταση για 7DAYS ΚΡ.ΠΡΑΛΙΝΑ 70ΓΡ+20% ΔΩΡΕΑΝ ΠΡΟΙΟΝ (Λ.Τ.0,50Ε)
    if (SupMatCode = '53995') then
      SupMatCode := '53539';

//  // Αντικατάσταση για MOLTO SUPER MAX ΠΡΑΛΙΝΑ 160ΓΡ (ΛΤ 1,50Ε)
//    if (SupMatCode = '53806') then
//      SupMatCode := '53886';

  // Αντικατάσταση για MOLTO ΚΡ.DOUBLE ΚΑΚ-ΒΑΝ 80ΓΡ+40% (Λ.Τ 1Ε)
    if (SupMatCode = '53813') then
      SupMatCode := '53816';

//  // Αντικατάσταση για MOLTO ΚΡ.ΒΑΝΙΛΙΑ CREAM & COOKIES 110ΓΡ (Λ.Τ.1Ε)
//    if (SupMatCode = '53875') then
//      SupMatCode := '53039';

//  // Αντικατάσταση για CHIPICAO MINI CR.COC. SP.BOB (60G)15P/C
//    if (SupMatCode = '54281') then
//      SupMatCode := '55507';

  // Αντικατάσταση για CHIPICAO ΚΡ.ΚΑΚΑΟ 60ΓΡ
    if (SupMatCode = '55631') then
      SupMatCode := '55630';

  // Αντικατάσταση για CHIPICAO ΜΙΝΙ ΚΡ.ΚΑΚΑΟ 60ΓΡ
    if (SupMatCode = '55668') then
      SupMatCode := '55507';

  // Αντικατάσταση για 7DAYS ΒΑΚΕ RΟLLS ΑΛΑΤΙ 80ΓΡ
    if (SupMatCode = '64404') then
      SupMatCode := '64006';

  // Αντικατάσταση για 7D BAKE ROLLS ΣΚΟΡΔΟ (80G)14Τ/Κ
    if (SupMatCode = '64424') then
      SupMatCode := '64026';

  // Αντικατάσταση για 7DAYS ΒΑΚΕ RΟLLS ΣΚΟΡΔΟ-ΠΑΡΜ 80ΓΡ
    if (SupMatCode = '64444') then
      SupMatCode := '64046';

  // Αντικατάσταση για 7D BAKE ROLLS BARBEQUE (80G)14Τ/Κ
    if (SupMatCode = '64484') then
      SupMatCode := '64086';

  // Αντικατάσταση για FRAULISA ΒΑΣΗ ΚΑΚΑΟ 3ΠΛΗ 400ΓΡ
    if (SupMatCode = '70103') then
      SupMatCode := '70113';

  // Αντικατάσταση για FRAULISA ΒΑΣΗ ΒΑΝΙΛΙΑ 3ΠΛΗ 400ΓΡ
    if (SupMatCode = '70112') then
      SupMatCode := '70102';

  // Αντικατάσταση για CHIPICAO ΓΕΜΙΣΤΑ ΜΠΙΣΚΟΤΑ 50ΓΡ
    if (SupMatCode = '71765') then
      SupMatCode := '71974';

  // Αντικατάσταση για CHIPICAO ΜΠΙΣΚΟΤΟ 50ΓΡ (ΛΤ  0,50Ε)
    if (SupMatCode = '71974') then
      SupMatCode := '79750';

  // Αντικατάσταση για 7DAYS ΤΣΟΥΡΕΚΙ ΚΛΑΣΙΚΟ (380G)5Τ/Κ
    if (SupMatCode = '76107') then
      SupMatCode := '76611';

  // Αντικατάσταση για 7DAYS ΤΣΟΥΡΕΚΙ ΚΛΑΣΙΚΟ 380ΓΡ (ΛΤ 2,50Ε)
    if (SupMatCode = '76108') then
      SupMatCode := '76612';

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

  // Αντικατάσταση για FINETI DIPS HAZELNUT +TOY (45G) 8P/D
//    if (SupMatCode = '14868') then
//      SupMatCode := '14862';

    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

    if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
//  end;

end;
(*----------------------------------------------------------------------------*)
function TChipitaReader.GetGLN: string;
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
function TChipitaReader.GetDocNo: string;
begin
  Result := GetStrDef(fiDocId);
end;
(*----------------------------------------------------------------------------*)
function TChipitaReader.GetPayType: string;
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
procedure TChipitaReader.LoadFromFile;
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
    p := pos('#', ALine);
    DocChanger := LeftString(ALine, p-1);
    for j := 0 to DataListDetail.Count - 1 do
    begin
      ALine := DataListDetail.Strings[j];
      p := pos('#', ALine);
      if LeftString(ALine, p-1) = DocChanger then
        DataList.Add('D' + ALine);
    end;
  end;

  FTotal := DataList.Count;

  FreeAndNil(DataListMaster);
  FreeAndNil(DataListDetail);
end;
(*----------------------------------------------------------------------------*)
function TChipitaReader.DocStrToDate(S: string): TDate;
begin
  // 20120912

  Result := EncodeDate(StrToInt(Copy(S, 1, 4)),
                       StrToInt(Copy(S, 5, 2)),
                       StrToInt(Copy(S, 7, 2)));
end;




initialization
  FileDescriptors.Add(TChipitaDescriptor.Create);

end.



