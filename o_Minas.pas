(*
  Επειδή αλλάζει κάθε φορά το format του excel, πρέπει να προβλέψω
  την ύπαρξη ή όχι διαφορετικό format ημαρομηνίας και αριθμών.

  Πρέπει να αφαιρώ την ημέρα της εβδομάδας από την ημ/νία.
*)
unit o_Minas;

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
  TMinasDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TMinasReader = class(TPurchaseReader)
 protected
   function GetVAT(MatCode: string): string; override;
   function GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function DocStrToDate(S: string): TDate; override;
   function GetPayType: string; override;
//   function StripInt(ToStrip: string):string;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;



implementation




{ TMinasDescriptor }
(*----------------------------------------------------------------------------*)
constructor TMinasDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ΜΗΝΑΣ';
  FFileName        := 'ΜΗΝΑΣ\*.csv';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  FAFM             := '801589520';
  FNeedsMapGln     := True;
//  FIsMultiSupplier := True;

  FNeedsMapPayMode := True;
  FPayModeMap.Add('1000=ΜΕΤΡΗΤΑ');
  FPayModeMap.Add('1003=ΕΠΙ ΠΙΣΤΩΣΗ');
  FPayModeMap.Add('1010=ΕΠΙ ΠΙΣΤΩΣΗ');

  FDocTypeMap.Add('6041=ΔΑΠ');
  FDocTypeMap.Add('6061=ΤΙΜ');
  FDocTypeMap.Add('6062=ΤΔΑ');
  FDocTypeMap.Add('6063=ΠΕΠ');
  FDocTypeMap.Add('6066=ΠΕΠ');
  FDocTypeMap.Add('6064=ΠΕΚ');


  FMeasUnitMap.Add('101=ΤΕΜ');
  FMeasUnitMap.Add('150=ΚΙΛ');


  FGLNMap.Add('01=1');    //    ΜΑΡΑΣΛΗ 18
  FGLNMap.Add('02=2');    //    ΧΑΙΡΙΑΝΩΝ 1
  FGLNMap.Add('03=3');    //    ΠΕΡΙΚΛΕΟΥΣ 46
  FGLNMap.Add('04=7');    //    ΚΑΡΑΚΑΣΗ 92
  FGLNMap.Add('05=6');    //    ΚΡΩΜΝΗΣ 38 & ΠΟΥΛΑΝ
  FGLNMap.Add('06=8');    //    ΚΗΦΙΣΙΑΣ 12
  FGLNMap.Add('07=9');    //    ΛΑΜΠΡΑΚΗ 154
  FGLNMap.Add('08=10');   //    ΝΕΑ ΠΛΑΓΙΑ
  FGLNMap.Add('09=5');    //    ΜΑΡΤΙΟΥ
  FGLNMap.Add('10=12');   //    ΕΓΝΑΤΙΑ
  FGLNMap.Add('11=13');   //    ΒΕΝΙΖΕΛΟΥ 14
  FGLNMap.Add('12=15');   //    ΝΙΚΟΠΟΛΕΩΣ 27 & ΧΙΟΥ
  FGLNMap.Add('13=17');   //    ΙΘΑΚΗΣ 43
  FGLNMap.Add('14=19');   //    ΠΑΡΑΣΚΕΥΟΠΟΥΛΟΥ 5
  FGLNMap.Add('15=20');   //    ΕΠΤΑΛΟΦΟΥ 6
  FGLNMap.Add('16=21');   //    Μ. ΑΛΕΞΑΝΔΡΟΥ 9 ΠΥΛΑΙΑ
  FGLNMap.Add('17=22');   //    ΑΙΓΑΙΟΥ
  FGLNMap.Add('18=23');   //    ΒΙΘΥΝΙΑΣ 37
  FGLNMap.Add('19=24');   //    ΠΟΝΤΟΥ
  FGLNMap.Add('20=26');   //    ΤΕΡΖΗΣ ΠΥΛΑΙΑ
  FGLNMap.Add('21=25');   //    ΧΑΛΚΙΔΙΚΗΣ
  FGLNMap.Add('99=99');   //    ΚΕΝΤΡΙΚΟ ???

end;
(*----------------------------------------------------------------------------*)
procedure TMinasDescriptor.AddFileItems;
begin
  inherited;

  { master }
//  FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,4-1));    // GLN
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,24-1));

  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  , 9-1));      // Παλιός κωδικός, από 1/1/13 νέος κωδικός.
  FItemList.Add(TFileItem.Create(itQty          ,2  ,12-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,13-1));
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,20-1)); // Category
  FItemList.Add(TFileItem.Create(itDisc         ,2  ,14-1)); // Percent
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,16-1)); // Καθαρή αξία ** και το 17 είναι το ίδιο ??
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,11-1));

end;


{ TMinasReader }
(*----------------------------------------------------------------------------*)
constructor TMinasReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ΜΗΝΑΣ');
end;
(*----------------------------------------------------------------------------*)
function TMinasReader.GetVAT(MatCode: string): string;
var
  VATCode: integer;
begin
  VATCode := StrToInt(GetStrDef(fiVAT));
  case VATCode of
    1130: Result := '13';
    1240: Result := '13';
  end;
end;
(*----------------------------------------------------------------------------*)
function TMinasReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

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

// Αντικατάσταση για ΡΟΛΟ ΚΟΤΟΠΟΥΛΟ ΝΩΠΟ ΕΛΛΗΝΙΚΟ
  if (SupMatCode = '1032016') then
    SupMatCode := '102500';

  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

  if not Result then
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                   [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));

end;
(*----------------------------------------------------------------------------*)
function TMinasReader.DocStrToDate(S: string): TDate;
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
function TMinasReader.GetPayType: string;
begin
  Result :=  'ΕΠΙ ΠΙΣΤΩΣΗ';
end;

(*----------------------------------------------------------------------------*)






initialization
  FileDescriptors.Add(TMinasDescriptor.Create);

end.
