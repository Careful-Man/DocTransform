unit o_Kolios;

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
  TKoliosDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TKoliosReader = class(TPurchaseReader)
 protected
   function  GetLineMarker(): string; override;
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   procedure LoadFromFile(); override;
   function  GetGLN(): string; override;
   function  GetDocNo: string; override;
   function  GetPayType: string; override;
   function  DocStrToDate(S: string): TDate; override;
   function  GetQty: Double; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;


implementation


{ TChipitaDescriptor }
(*----------------------------------------------------------------------------*)
constructor TKoliosDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ΚΟΛΙΟΣ';
  FFileName        := 'ΚΟΛΙΟΣ\inv_header*.txt';
//  FFileNameDetail  := 'CHIPITA\inv_lines*.txt';
  FKind            := fkDelimited;
  FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '092443755';

//  FIsMultiSupplier := True;

 // ΑΠΟΘΗΚΕΥΤΙΚΟΙ ΧΩΡΟΙ
 // FNeedsMapGln     := True;


  FNeedsMapPayMode := True;
  FPayModeMap.Add('10=ΜΕΤΡΗΤΑ');
  FPayModeMap.Add('20=ΕΠΙ ΠΙΣΤΩΣΗ');

  FDocTypeMap.Add('1=ΔΑΠ');
  FDocTypeMap.Add('2=ΤΙΜ');
  FDocTypeMap.Add('3=ΤΔΑ');
  FDocTypeMap.Add('4=ΠΕΠ');
  FDocTypeMap.Add('6=ΠΕΚ');
  FDocTypeMap.Add('7=ΠΕΔ');


  FMeasUnitMap.Add('1=ΤΕΜ');
  FMeasUnitMap.Add('3=ΚΙΒ');
  FMeasUnitMap.Add('4=ΛΙΤ');
  FMeasUnitMap.Add('5=ΜΕΤ');
  FMeasUnitMap.Add('6=ΚΙΒ');


end;
(*----------------------------------------------------------------------------*)
procedure TKoliosDescriptor.AddFileItems;
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
  FItemList.Add(TFileItem.Create(itCode             ,2  ,3-1));  //ok
  FItemList.Add(TFileItem.Create(itQty              ,2  ,11-1)); //ok
  FItemList.Add(TFileItem.Create(itPrice            ,2  ,16-1)); //ok  // Αν πρόκειται για ΚΙΒ, εννοεί τιμή ΚΙΒ
  FItemList.Add(TFileItem.Create(itVAT              ,2  ,59-1)); //ok
  FItemList.Add(TFileItem.Create(itDisc             ,2  ,54-1)); //ok ποσό έκπτωσης
//  FItemList.Add(TFileItem.Create(itDisc2            ,2  ,89-1)); //*
//  FItemList.Add(TFileItem.Create(itDisc3            ,2  ,33-1)); //*
  FItemList.Add(TFileItem.Create(itLineValue        ,2  ,57-1)); //Αναφέρεται ως 56 αλλά δείχνει να είναι στο 57
  FItemList.Add(TFileItem.Create(itMeasUnit         ,2  ,12-1)); //ok
  FItemList.Add(TFileItem.Create(itMeasUnitRelation ,2  ,14-1)); //ok


end;



{ TChipitaReader }
(*----------------------------------------------------------------------------*)
constructor TKoliosReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ΚΟΛΙΟΣ');
end;
(*----------------------------------------------------------------------------*)
function TKoliosReader.GetLineMarker: string;
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
function TKoliosReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

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

  // Αντικατάσταση κωδικών ΚΟΛΙΟΣ
    if (SupMatCode = '7408536') then
      SupMatCode := '7408535';

    if (SupMatCode = '7401836') then
      SupMatCode := '7401835';

    if (SupMatCode = '6000464') then
      SupMatCode := '6000465';

    if (SupMatCode = '8105987') then
      SupMatCode := '8105986';

    if (SupMatCode = '6375219') then
      SupMatCode := '6375218';

    if (SupMatCode = '9230031') then
      SupMatCode := '9230030';

    if (SupMatCode = '6000797') then
      SupMatCode := '6000796';

    if (SupMatCode = '6010797') then
      SupMatCode := '6010796';

    if (SupMatCode = '6001494') then
      SupMatCode := '6001495';

    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);
  // Αντικατάσταση κωδικών ΚΟΛΙΟΣ τέλος

    if not Result then
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));

end;
(*----------------------------------------------------------------------------*)
function TKoliosReader.GetGLN: string;
var
  s: string;
  w: string;
begin
  s := GetStrDef(fiGLN);
  w := RightStr(s, 2);
  Result := w;
end;
(*----------------------------------------------------------------------------*)
function TKoliosReader.GetDocNo: string;
begin
  Result := GetStrDef(fiDocId);
end;
(*----------------------------------------------------------------------------*)
function TKoliosReader.GetPayType: string;
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
procedure TKoliosReader.LoadFromFile;
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

  ////y Loop through DataListMaster and remove all empty lines
      for I := DataListMaster.count - 1 downto 0 do
  begin
    if Trim(DataListMaster[I]) = '' then
      DataListMaster.Delete(I);
    end;
  ////y


  if (FDescriptor.IsOem) then
//    DataListMaster.Text := Utls.OemToAnsi(DataList.Text)
    DataListMaster.Text := OemToAnsi(DataList.Text)
  else if (FDescriptor.IsUnicode) then
    DataListMaster.Text := UTF8ToANSI(DataList.Text);

    ///y  print statement to check DataListMaster
 //FManager.Log(Self, DataListMaster.Text);     // πρεπει να αφαιρεσω τις κενες γραμμες στα headers
   ///


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

//
     //   FManager.Log(Self, DataList.Text);   //yyy
//

  FTotal := DataList.Count;

  FreeAndNil(DataListMaster);
  FreeAndNil(DataListDetail);
end;
(*----------------------------------------------------------------------------*)
function TKoliosReader.GetQty: Double;

//y Ο Κολιός χρησιμοποιεί ως κυρίος μ.μ. για ζυγιζόμενα τα γραμμάρια, ενώ εμείς μόνο Κιλά.
//  Πρέπει να μετατρέπω γραμμάρια σε κιλά όποτε μ.μ. = 2
var
  S : string;
  W : string;

begin
  S := GetStrDef(fiQty);
  W := GetStrDef(fiMeasUnit);


  if W = '2' then
      Result := abs(StrToFloat(S)/1000)
  else
      Result := abs(StrToFloat(S));

end;
(*----------------------------------------------------------------------------*)
function TKoliosReader.DocStrToDate(S: string): TDate;
begin
  // 20120912

  Result := EncodeDate(StrToInt(Copy(S, 1, 4)),
                       StrToInt(Copy(S, 5, 2)),
                       StrToInt(Copy(S, 7, 2)));
end;




initialization
  FileDescriptors.Add(TKoliosDescriptor.Create);

end.



