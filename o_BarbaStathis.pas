unit o_BarbaStathis;

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
O περιγραφέας θα πρέπει να έχει καταστάσεις
  NoLine
  HeaderLine
  DetailLine
  SkipLine
και ο αναγνώστης να του περνάει κάθε γραμμή και να τον συμβουλεύεται

*)
  TDocBehaviour = (dbDAP, dbTIM, dbUndefined);

  TBarbaStathisDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TBarbaStathisReader = class(TPurchaseReader)
 protected
   procedure LoadFromFile; override;
   function  GetLineMarker: string; override;
   function GetDocNo: string; override;
   function  GetRelDocNum: string; override;
   function GetCode: string; override;
   function GetQty: Double; override;
   function GetPrice: Double; override;
   function  GetVAT(MatCode: string): string; override;
   function  GetLineValue: Double; override;
   function  DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;


implementation


{ TDeltaDescriptor }
(*----------------------------------------------------------------------------*)
constructor TBarbaStathisDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ΜΠΑΡΜΠΑ-ΣΤΑΘΗΣ';
  FFileName        := 'ΜΠΑΡΜΠΑ-ΣΤΑΘΗΣ\K4HEADER*.txt';
//  FFileNameDetail  := 'CHIPITA\inv_lines*.txt';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'L';
  FAFM             := '999863856';
  FNeedsMapGln     := True;
//  FIsMultiSupplier := True;

//  FIsOEM       := True;
//  FIsUnicode   := True;

  FNeedsMapPayMode := True;
  FPayModeMap.Add('A=ΜΕΤΡΗΤΑ');
  FPayModeMap.Add('C=ΕΠΙ ΠΙΣΤΩΣΗ');
  FPayModeMap.Add('=ΕΠΙ ΠΙΣΤΩΣΗ');

  FDocTypeMap.Add('ZDA4=ΔΑΠ'); // ***
  FDocTypeMap.Add('ΖF01=ΔΑΠ'); // ***
  FDocTypeMap.Add('ZTIM=ΤΙΜ'); // ***
  FDocTypeMap.Add('ZTD4=ΤΔΑ'); // ***    xx
  FDocTypeMap.Add('ZITD=ΤΔΑ'); // ***    xx
  FDocTypeMap.Add('ZRED=ΠΕΠ'); // ***
  FDocTypeMap.Add('ZIR0=ΠΕΠ'); // ***    xx
  FDocTypeMap.Add('ZRE=ΠΕΠ');  // ***
  FDocTypeMap.Add('ZCR1=ΠΕΚ'); // ***
  FDocTypeMap.Add('ZDRB=ΤΧΤ'); // ***


  FMeasUnitMap.Add('ST=ΤΕΜ');


  FGLNMap.Add('0000001000000=1');     //**    ΜΑΡΑΣΛΗ 18
  FGLNMap.Add('0000002000000=2');     //**    ΧΑΙΡΙΑΝΩΝ 1
  FGLNMap.Add('0000003000000=3');     //**    ΠΕΡΙΚΛΕΟΥΣ 46
  FGLNMap.Add('0000005000000=5');     //**    25 ΜΑΡΤΙΟΥ 113-115
  FGLNMap.Add('0000006000000=6');     //**    ΚΡΩΜΝΗΣ 38 & ΠΟΥΛΑΝ
  FGLNMap.Add('0000007000000=7');     //**    ΚΑΡΑΚΑΣΗ 92
  FGLNMap.Add('0000008000000=8');     //**    ΚΗΦΙΣΙΑΣ 12
  FGLNMap.Add('0000009000000=9');     //**    ΛΑΜΠΡΑΚΗ 154
  FGLNMap.Add('0000010000000=10');    //**    ΝΕΑ ΠΛΑΓΙΑ
  FGLNMap.Add('0000012000000=12');    //**    ΕΓΝΑΤΙΑ 6
  FGLNMap.Add('0000013000000=13');    //**    ΒΕΝΙΖΕΛΟΥ 14
  FGLNMap.Add('0000015000000=15');    //**    ΝΙΚΟΠΟΛΕΩΣ 27 & ΧΙΟΥ
  FGLNMap.Add('0000017000000=17');    //**    ΙΘΑΚΗΣ 43
  FGLNMap.Add('0000019000000=19');    //**    ΠΑΡΑΣΚΕΥΟΠΟΥΛΟΥ 5
  FGLNMap.Add('0000020000000=20');    //**    ΕΠΤΑΛΟΦΟΥ 6
  FGLNMap.Add('0000021000000=21');    //**    Μ. ΑΛΕΞΑΝΔΡΟΥ 9 ΠΥΛΑΙΑ
  FGLNMap.Add('0000022000000=22');    //**    ΑΙΓΑΙΟΥ 80 ΚΑΛΑΜΑΡΙΑ
  FGLNMap.Add('0000023000000=23');    //**    ΒΙΘΥΝΙΑΣ 37 ΚΑΛΑΜΑΡΙΑ
  FGLNMap.Add('0000024000000=24');    //**    ΠΟΝΤΟΥ 109 ΚΑΛΑΜΑΡΙΑ
  FGLNMap.Add('0000025000000=25');    //**    ΧΑΛΚΙΔΙΚΗΣ 19 ΘΕΣΣΑΛΟΝΙΚΗ
  FGLNMap.Add('0000026000000=26');    //**    ΤΕΡΖΗΣ ΠΥΛΑΙΑ
  FGLNMap.Add('0000000000099=99');    //**    ΚΕΝΤΡΙΚΗ ΑΠΟΘΗΚΗ
  FGLNMap.Add('0000099000000=99');    //**    ΚΕΝΤΡΙΚΗ ΑΠΟΘΗΚΗ




end;
(*----------------------------------------------------------------------------*)
procedure TBarbaStathisDescriptor.AddFileItems;
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
  FItemList.Add(TFileItem.Create(itPrice            ,2  ,6-1));  // Χωρίς ΦΠΑ (πάντα)
  FItemList.Add(TFileItem.Create(itVAT              ,2  ,10-1)); // OK   // Percent
//  FItemList.Add(TFileItem.Create(itDisc             ,2  ,12-1)); // OK   // Percent
  FItemList.Add(TFileItem.Create(itDisc             ,2  ,13-1)); // OK   // Value
//  FItemList.Add(TFileItem.Create(itDisc2            ,2  ,27-1));
//  FItemList.Add(TFileItem.Create(itDisc3            ,2  ,33-1));
  FItemList.Add(TFileItem.Create(itLineValue        ,2  ,6-1));  // OK
  FItemList.Add(TFileItem.Create(itMeasUnit         ,2  ,9-1));  // OK
  FItemList.Add(TFileItem.Create(itMeasUnitRelation ,2  ,8-1));  // ??????????


end;



{ TBarbaStathisReader }
(*----------------------------------------------------------------------------*)
constructor TBarbaStathisReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ΜΠΑΡΜΠΑ-ΣΤΑΘΗΣ');
end;
(*----------------------------------------------------------------------------*)
(* Διαβάζω από μία γραμμή του Master το DocChanger.
   Ψάχνω το DocChanger μέσα στο Detail και κάθε γραμμή που βρίσκω την προσθέτω
   στο ίδιο αρχείο. Ουσιαστικά κάνω επαναδημιουργία του αρχείου όπως θα έπρεπε
   να είναι εξ' αρχής.
   Σε σχέση με την Chipita, εδώ έχουμε διαφορετικά ονόματα αρχείων.
   Αυτό που μπορούμε να κάνουμε είναι να αντιγράφουμε τα αρχεία σε άλλα αρχεία
   με ονόματα που μας βολεύουν και να δουλεύουμε με τα νέα αρχεία, ακριβώς
   όπως κάνω με την Chipita.
*)
procedure TBarbaStathisReader.LoadFromFile;
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
// Προσθέτω το 'H' γιατί θέλω να συγκρίνω μόνο τα Headers και όχι και τα Lines.
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

// Ενώ γνωρίζουμε το όνομα του header file, δεν γνωρίζουμε το όνομα του line file.
// Για το λόγο αυτό πρέπει στο copy που κάνουμε να χρησιμοποιήσουμε wild card,
// ώστε να αντιγράψουμε κάθε πιθανό όνομα.
// Πρέπει λοιπόν να χρησιμοποιήσω το FindFiles ή το FindFirst, αφού μόνο ένα αρχείο θέλω.
  FFileNameDetail := PathAddSeparator(JustFilePath) + 'K4LINE-EL094098834*' + JustExtension;
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
function TBarbaStathisReader.GetLineMarker: string;
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
function TBarbaStathisReader.GetDocNo: string;
var
  s: string;
begin
  s := RightString(GetStrDef(fiDocID), 7);
  Result := TrimLeftZeroes(s);
end;
(*----------------------------------------------------------------------------*)
function TBarbaStathisReader.GetRelDocNum: string;
var
  s: string;
begin
  s := inherited;
  Result := RightString(s, 7);
  while Result[1] = '0' do
  begin
    if (Length(Result) = 1) then
      Exit;
    Delete(Result, 1, 1);
  end;
end;
(*----------------------------------------------------------------------------*)
function TBarbaStathisReader.GetCode: string;
var
  s: string;
begin
  s := GetStrDef(fiCode);
  Result := TrimLeftZeroes(s);
end;
(*----------------------------------------------------------------------------*)
function TBarbaStathisReader.GetQty: Double;
var
  S : string;
begin
  S := GetStrDef(fiQty, '0');
//  S := Utls.CommaToDot(S);
//  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  S := DotToComma(S);
//  Result := abs(StrToFloat(S));
  Result := abs(StripReal(s));
end;
(*----------------------------------------------------------------------------*)
function TBarbaStathisReader.GetPrice: Double;

  function InternalGetLineValue: double;
  var
    S : string;
  begin
    S := GetStrDef(fiLineValue, '0');
    Result := abs(StripReal(s));
  end;

var
  S : string;
  Price : Double;
  LineValue : Double;
  Quantity : Double;
  DiscountValue : Double;
  sVAT : string;
  aVAT : Double;
begin
  LineValue := InternalGetLineValue;
  Quantity := GetQty;
  DiscountValue := GetDiscount;
  sVAT := GetVAT(MatCode);
  aVAT := StrToFloat(sVAT);
// Πρέπει να αφαιρέσουμε το ΦΠΑ και να προσθέσουμε την έκπτωση στο Price
//  Price := LineValue / Quantity / (1+(aVAT/100));
  Price := (LineValue / (1+(aVAT/100)) + DiscountValue) / Quantity;
  Result := Price;
end;
(*----------------------------------------------------------------------------*)
(* Για τον ΜΠΑΡΜΠΑ ΣΤΑΘΗ δεν κάνω τίποτα γιατί μου στέλνει το ΦΠΑ έτοιμο -----*)
function TBarbaStathisReader.GetVAT(MatCode: string): string;
begin
  Result := FloatToStr(StripReal(GetStrDef(fiVAT)));
end;
(*----------------------------------------------------------------------------*)
function TBarbaStathisReader.GetLineValue: Double;

  function InternalGetLineValue: double;
  var
    S : string;
  begin
    S := GetStrDef(fiLineValue, '0');
    Result := abs(StripReal(s));
  end;

var
  F, T : double;
  S : string;
  NetValue : double;
  TotalValue : double;
begin
  T := InternalGetLineValue();
  F := StrToFloat(GetVAT(MatCode));
  (* Αν π.χ. ο ΦΠΑ είναι 13%, θα γίνει διαίρεση δια 1 + 0,13 => 1,13          *)
  T := T / (1+(F/100));  // Πρέπει να αφαιρέσουμε το ΦΠΑ από το LineValue
  Result := T;
end;

(*----------------------------------------------------------------------------*)
function TBarbaStathisReader.DocStrToDate(S: string): TDate;
begin
  // 20120912

  Result := EncodeDate(StrToInt(Copy(S, 1, 4)),
                       StrToInt(Copy(S, 5, 2)),
                       StrToInt(Copy(S, 7, 2)));
end;




initialization
  FileDescriptors.Add(TBarbaStathisDescriptor.Create);

end.

