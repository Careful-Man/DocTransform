(*
  Επειδή αλλάζει κάθε φορά το format του excel, πρέπει να προβλέψω
  την ύπαρξη ή όχι διαφορετικό format ημαρομηνίας και αριθμών.

  Πρέπει να αφαιρώ την ημέρα της εβδομάδας από την ημ/νία.
*)
unit o_FarmesXoriou;

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
  TFarmesXoriouDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TFarmesXoriouReader = class(TPurchaseReader)
 protected
   //function  ResolveGLN: Boolean; override;
   //function  GetDocDate: TDate; override;

//   function GetGLN(): string; override;
//   function GetDocType: string; override;
//   function GetDocNo: string; override;
//   function GetRelDocNum: string; override;
   function GetQty: Double; override;
   function GetLineValue: Double; override;
   function GetVAT(MatCode: string): string; override;
//   function GetMeasUnitAA: integer; override;
//   function GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function DocStrToDate(S: string): TDate; override;
   function GetPayType: string; override;
//   function StripInt(ToStrip: string):string;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;



implementation




{ TFarmesXoriouDescriptor }
(*----------------------------------------------------------------------------*)
constructor TFarmesXoriouDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ΦΑΡΜΕΣ-ΧΩΡΙΟΥ';
  FFileName        := 'ΦΑΡΜΕΣ ΧΩΡΙΟΥ\*.csv';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  FAFM             := '800842383';
  FNeedsMapGln     := True;
//  FIsMultiSupplier := True;

//  FNeedsMapPayMode := True;
//  FPayModeMap.Add('1000=ΜΕΤΡΗΤΑ');
//  FPayModeMap.Add('1003=ΕΠΙ ΠΙΣΤΩΣΗ');
//  FPayModeMap.Add('1010=ΕΠΙ ΠΙΣΤΩΣΗ');


  FDocTypeMap.Add('Τιμολόγιο Δελτίο Αποστολής Πωλήσων=ΤΔΑ');
  FDocTypeMap.Add('Πιστωτικό Τιμολ.Δελτ.Επιστρ.Πωλήσεων=ΠΕΠ');

(*
  FDocTypeMap.Add('ΤΔ=ΤΔΑ');
  FDocTypeMap.Add('ΠΙ=ΠΕΠ');
*)

//  FMeasUnitMap.Add('101=ΤΕΜ');
  FMeasUnitMap.Add('Κιλά=ΚΙΛ');
  FMeasUnitMap.Add('Τεμ.=ΤΕΜ');

      // AX mappings
  FGLNMap.Add('01=1');
  FGLNMap.Add('Μαρασλή 18=1');
  FGLNMap.Add('Χαιριανών 1=2');
  FGLNMap.Add('Περικλέους 45=3');
  FGLNMap.Add('03=5');
  FGLNMap.Add('3=5');
  FGLNMap.Add('Κρώμνης 38=6');
  FGLNMap.Add('Καρακάση 92=7');
  FGLNMap.Add('02=8');
  FGLNMap.Add('2=8');
  FGLNMap.Add('Λαμπράκη 154=9');
  FGLNMap.Add('Εγνατίας 6=12');
  FGLNMap.Add('04=13');
  FGLNMap.Add('Ελ.Βενιζέλου 14=13');
  FGLNMap.Add('Νικοπόλεως 27 & Χίου=15');
  FGLNMap.Add('5=15');
  FGLNMap.Add('Ιθάκης 43=17');
  FGLNMap.Add('Παρασκευοπούλου 5 & Καλαβρύτων=19');
  FGLNMap.Add('6=19');
  FGLNMap.Add('07=20');
  FGLNMap.Add('Επταλόφου 6=20');
  FGLNMap.Add('Μ.Αλεξάνδρου 9=21');
  FGLNMap.Add('8=21');
  FGLNMap.Add('Αγαίου 80=22');
  FGLNMap.Add('9=22');
  FGLNMap.Add('Βιθυνίας 37=23');
  FGLNMap.Add('Πόντου 109=24');
  FGLNMap.Add('12=25');
  FGLNMap.Add('Εγνατίας 112=26');


//  FGLNMap.Add('Υπ/μα Μαρασλή 18, Μαρτίου=1');                  //    ΜΑΡΑΣΛΗ 18
//  FGLNMap.Add('Υπ/μα Χαιριανών 1, Καλαμαριά=2');               //    ΧΑΙΡΙΑΝΩΝ 1
//  FGLNMap.Add('Υπ/μα Περικλέους 45, Βυζάντιο=3');              //    ΠΕΡΙΚΛΕΟΥΣ 46
//  FGLNMap.Add('Υπ/μα Μαρτίου 113-115, Μαρτίου=5');             //    ΜΑΡΤΙΟΥ
//  FGLNMap.Add('Υπ/μα Κρώμνης 38, Καραμπουρνάκι=6');            //    ΚΡΩΜΝΗΣ 38 & ΠΟΥΛΑΝ
//  FGLNMap.Add('Υπ/μα Καρακάση 92, Κάτω Τούμπα=7');             //    ΚΑΡΑΚΑΣΗ 92
//  FGLNMap.Add('Υπ/μα Κηφισία 12, Κηφισιά=8');                  //    ΚΗΦΙΣΙΑΣ 12
//  FGLNMap.Add('Υπ/μα Λαμπράκη 154, ’νω Τούμπα=9');             //    ΛΑΜΠΡΑΚΗ 154
////  FGLNMap.Add('08=10');                                //    ΝΕΑ ΠΛΑΓΙΑ
//  FGLNMap.Add('Υπ/μα Εγνατίας 6, Πλ. Δημοκρατίας=12');         //    ΕΓΝΑΤΙΑ
//  FGLNMap.Add('Υπ/μα Ελ. Βενιζέλου 14, Θέρμη=13');             //    ΒΕΝΙΖΕΛΟΥ 14
//  FGLNMap.Add('Υπ/μα Νικοπόλεως 27 & Χίου, Νικόπολη=15');      //    ΝΙΚΟΠΟΛΕΩΣ 27 & ΧΙΟΥ
//  FGLNMap.Add('Υπ/μα Ιθάκης 43, Εύοσμος=17');                  //    ΙΘΑΚΗΣ 43
//  FGLNMap.Add('Υπ/μα Παρ/λου 5 & Καλαβρύτων, Καλαμαριά=19');   //    ΠΑΡΑΣΚΕΥΟΠΟΥΛΟΥ 5
//  FGLNMap.Add('Υπ/μα Επταλόφου 6, Κάτω Τούμπα=20');            //    ΕΠΤΑΛΟΦΟΥ 6
//  FGLNMap.Add('Υπ/μα Μ.Αλεξάνδρου 9, Πυλαία=21');              //    Μ. ΑΛΕΞΑΝΔΡΟΥ 9 ΠΥΛΑΙΑ
//  FGLNMap.Add('Υπ/μα Αιγαίου 80, Βυζάντιο=22');                //    ΑΙΓΑΙΟΥ
//  FGLNMap.Add('Υπ/μα Βιθυνίας 37, Καλαμαριά=23');              //    ΒΙΘΥΝΙΑΣ 37
//  FGLNMap.Add('Υπ/μα Πόντου 109 & Θήχης 1, Καλαμαριά=24');     //    ΠΟΝΤΟΥ
//  FGLNMap.Add('Υπ/μα Χαλκιδικής 19, Μπότσαρη=25');             //    ΧΑΛΚΙΔΙΚΗΣ
//  FGLNMap.Add('Υπ/μα Εγνατίας 112, Πυλαία=26');                //    ΤΕΡΖΗΣ ΠΥΛΑΙΑ
//  FGLNMap.Add('14ο χλμ Ε.Ο Θεσσαλονίκης-Μουδανιών=99');        //    ΚΕΝΤΡΙΚΟ
end;
(*----------------------------------------------------------------------------*)
procedure TFarmesXoriouDescriptor.AddFileItems;
begin
  inherited;

  { master }
//  FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1)); //*   ok
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,3-1)); //*   ok
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,2-1)); //*   ok
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,2-1)); //*    check this out
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,4-1)); //*     changed

  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  , 5-1)); //* changed
  FItemList.Add(TFileItem.Create(itQty          ,2  , 8-1)); //* changed
  FItemList.Add(TFileItem.Create(itPrice        ,2  , 9-1)); //* changed
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,13-1)); //* // Percent  // changed but different VAT type
//  FItemList.Add(TFileItem.Create(itDisc         ,2  ,14-1)); // Percent
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,10-1)); //*- // Καθαρή αξία ** και το 17 είναι το ίδιο ??
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,7-1)); //* changed



(*
  { master }
//  FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,9-1));    // GLN

  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  , 4-1));
  FItemList.Add(TFileItem.Create(itQty          ,2  ,11-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,12-1));
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,16-1)); // Percent
//  FItemList.Add(TFileItem.Create(itDisc         ,2  ,14-1)); // Percent
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,13-1)); // Καθαρή αξία ** και το 17 είναι το ίδιο ??
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,10-1));
*)
end;


{ TMinasReader }
(*----------------------------------------------------------------------------*)
constructor TFarmesXoriouReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ΦΑΡΜΕΣ-ΧΩΡΙΟΥ');
end;
(*----------------------------------------------------------------------------*)
//function TFarmesXoriouReader.GetGLN: string;
//begin
//  Result := GetStrDef(fiGLN);
//  if Result = '' then
//    Result := '  ';
//end;
(*----------------------------------------------------------------------------*)
//function TFarmesXoriouReader.GetDocType: string;
//var
//  s: string;
//begin
//  s := GetStrDef(fiDocType);
//  Result := Copy(s, Length(s)-3+1, 3);
//end;
(*----------------------------------------------------------------------------*)
//function TFarmesXoriouReader.GetDocNo: string;
//var
//  s: string;
//begin
//  s := GetStrDef(fiDocChanger);
//  Result := TrimLeftZeroes(Copy(s, 5, 6));
//end;
(*----------------------------------------------------------------------------*)
//function TFarmesXoriouReader.GetRelDocNum: string;
//begin
//  Result := GetDocNo;
//end;
(*----------------------------------------------------------------------------*)
function TFarmesXoriouReader.GetQty: Double;
var
  S : string;
begin
  S := GetStrDef(fiQty, '0');
//
//
//  //**  S := Utls.CommaToDot(S);
//  //**  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
//  //**  S := CommaToDot(S);
//
//  S := DotToComma(S);
//  //**  Result := abs(StrToFloat(S, GlobalFormatSettings));
  Result := abs(StrToFloat(S));
end;
(*----------------------------------------------------------------------------*)
function TFarmesXoriouReader.GetLineValue: Double;
var
  S : string;
begin
  S := GetStrDef(fiLineValue, '0');

  //**  S := Utls.CommaToDot(S);
  //**  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  //**  S := CommaToDot(S);

  S := DotToComma(S);
  //**  Result := abs(StrToFloat(S, GlobalFormatSettings));
  Result := abs(StrToFloat(S));
end;

(*----------------------------------------------------------------------------*)
function TFarmesXoriouReader.GetVAT(MatCode: string): string;
begin
Result := FloatToStr(StripReal(GetStrDef(fiVAT)));
end;

 (*ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ---------)
  (*
function TFarmaKoukakiReader.GetVAT(MatCode: string): string;
begin
  // Εμφανίζει το string 'ΦΠΑ 13% Νέος Συντελεστής'
  Result := FloatToStr(StripReal(GetStrDef(fiVAT)));
end;*)
(*ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ---------)
function TFarmesXoriouReader.GetVAT(MatCode: string): string;
var
  VATCode: integer;
begin
  VATCode := StrToInt(GetStrDef(fiVAT));
  case VATCode of
    7013: Result := '13';
  end;
end;
 (//ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ*)


(*----------------------------------------------------------------------------*)
//function TFarmesXoriouReader.GetMeasUnitAA: integer;
//var
//  S : string;
//begin
//  S := GetStrDef(fiMeasUnit, 'Τεμάχιο');
//
//  if (S <> '000') then
//  begin
//    S      := FDescriptor.MeasUnitMap.Values[S];
//    Result := FManager.GetMaterialMeasureUnitAA(MatAA, S);
//  end else
//    Result := -1;
//
//end;
(*----------------------------------------------------------------------------*)
//function TFarmesXoriouReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
//
//  function GetMatCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
//  begin
//    Result := False;
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
//begin
//  Result := False;
//
//// Αντικατάσταση για ΧΥΜΟΣ ΠΟΡΤΟΚΑΛΙ  500ml (Επιστροφή)
//  if (SupMatCode = '0151') then
//    SupMatCode := '0152';
//
//  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);
//
//  if not Result then
////    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
////                   [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
//
//end;
(*----------------------------------------------------------------------------*)
function TFarmesXoriouReader.DocStrToDate(S: string): TDate;
var ADay, AMonth, AYear : word;
    p : integer;
begin
  S := StripDate(S);
  // 01/09/2020

  // Σε όποια θέση και να είναι το έτος, το διαβάζω πάντα σωστά.
  AYear := StrToInt(RightString(S, 4));
//  ShowMessage(Copy(S, 6, 4));
// Από τo string αφαιρούμε το τελευταίο κομμάτι του έτους μαζί με την κάθετο.
// Τώρα έχω το 01/09
  S := LeftString(S, Length(S)-5);
  p := pos('/', S);
  ADay := StrToInt(LeftString(S, p-1));
//  ShowMessage(LeftString(S, Length(S)-p));
  AMonth := StrToInt(RightString(S, Length(S)-p));
//  ShowMessage(RightString(S, Length(S)-p));

  Result := EncodeDate(AYear, AMonth, ADay);
end;
(*----------------------------------------------------------------------------*)
function TFarmesXoriouReader.GetPayType: string;
begin
  Result :=  'ΕΠΙ ΠΙΣΤΩΣΗ';
end;

(*----------------------------------------------------------------------------*)






initialization
  FileDescriptors.Add(TFarmesXoriouDescriptor.Create);

end.
