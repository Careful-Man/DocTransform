(*
  Επειδή αλλάζει κάθε φορά το format του excel, πρέπει να προβλέψω
  την ύπαρξη ή όχι διαφορετικό format ημαρομηνίας και αριθμών.

  Πρέπει να αφαιρώ την ημέρα της εβδομάδας από την ημ/νία.
*)
unit o_Georgiadis;

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
O περιγραφέας θα πρέπει να έχει καταστάσεις
  NoLine
  HeaderLine
  DetailLine
  SkipLine
και ο αναγνώστης να του περνάει κάθε γραμμή και να τον συμβουλεύεται

*)
  TGeorgiadisDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TGeorgiadisReader = class(TPurchaseReader)
 protected
   //function  ResolveGLN: Boolean; override;
   //function  GetDocDate: TDate; override;
   function GetGLN(): string; override;
//   function GetRelDocNum: string; override;
   function GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function GetDiscount: double; override;
   function GetLineValue: Double; override;
   function GetVAT(MatCode: string): string; override;
   function DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;


implementation


{ TFarmaKoukakiDescriptor }
(*----------------------------------------------------------------------------*)
constructor TGeorgiadisDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ΓΕΩΡΓΙΑΔΗΣ';
  FFileName        := 'ΓΕΩΡΓΙΑΔΗΣ\ΑΦΡΟΔΙΤΗ_ΤΙΜΟΛΟΓΙΑ*.csv';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  FAFM             := '082757287';
  FNeedsMapGln     := True;
//  FIsMultiSupplier := True;

  FNeedsMapPayMode := True;

  FPayModeMap.Add('ΠΙΣΤΩΣΗ=ΕΠΙ ΠΙΣΤΩΣΗ');

  FDocTypeMap.Add('41=ΔΑΠ');
  FDocTypeMap.Add('42=ΔΑΠ');
  FDocTypeMap.Add('45=ΔΑΠ');
  FDocTypeMap.Add('4100=ΔΑΠ');
  FDocTypeMap.Add('4101=ΔΑΠ');
  FDocTypeMap.Add('4102=ΔΑΠ');
  FDocTypeMap.Add('4103=ΔΑΠ');
  FDocTypeMap.Add('4104=ΔΑΠ');
  FDocTypeMap.Add('4105=ΔΑΠ');
  FDocTypeMap.Add('4106=ΔΑΠ');
  FDocTypeMap.Add('4107=ΔΑΠ');
  FDocTypeMap.Add('4108=ΔΑΠ');
  FDocTypeMap.Add('4109=ΔΑΠ');
  FDocTypeMap.Add('4110=ΔΑΠ');
  FDocTypeMap.Add('4111=ΔΑΠ');
  FDocTypeMap.Add('4112=ΔΑΠ');
  FDocTypeMap.Add('4113=ΔΑΠ');
  FDocTypeMap.Add('4114=ΔΑΠ');
  FDocTypeMap.Add('4115=ΔΑΠ');
  FDocTypeMap.Add('4120=ΔΑΠ');
  FDocTypeMap.Add('41-R=ΔΑΠ');
  FDocTypeMap.Add('41-Τ=ΔΑΠ');

  FDocTypeMap.Add('62=ΤΔΑ');
  FDocTypeMap.Add('6020=ΤΔΑ');
  FDocTypeMap.Add('6200=ΤΔΑ');
  FDocTypeMap.Add('6201=ΤΔΑ');
  FDocTypeMap.Add('6202=ΤΔΑ');
  FDocTypeMap.Add('6203=ΤΔΑ');
  FDocTypeMap.Add('6204=ΤΔΑ');
  FDocTypeMap.Add('6205=ΤΔΑ');
  FDocTypeMap.Add('6206=ΤΔΑ');
  FDocTypeMap.Add('6207=ΤΔΑ');
  FDocTypeMap.Add('6208=ΤΔΑ');
  FDocTypeMap.Add('6209=ΤΔΑ');
  FDocTypeMap.Add('6210=ΤΔΑ');
  FDocTypeMap.Add('6211=ΤΔΑ');
  FDocTypeMap.Add('6212=ΤΔΑ');
  FDocTypeMap.Add('6213=ΤΔΑ');
  FDocTypeMap.Add('6214=ΤΔΑ');
  FDocTypeMap.Add('6215=ΤΔΑ');
  FDocTypeMap.Add('62-R=ΤΔΑ');

  FDocTypeMap.Add('61=ΤΙΜ');
  FDocTypeMap.Add('6101=ΤΙΜ');
  FDocTypeMap.Add('6102=ΤΙΜ');
  FDocTypeMap.Add('6103=ΤΙΜ');
  FDocTypeMap.Add('6104=ΤΙΜ');
  FDocTypeMap.Add('6105=ΤΙΜ');
  FDocTypeMap.Add('6106=ΤΙΜ');
  FDocTypeMap.Add('6107=ΤΙΜ');
  FDocTypeMap.Add('6108=ΤΙΜ');
  FDocTypeMap.Add('6109=ΤΙΜ');
  FDocTypeMap.Add('6110=ΤΙΜ');
  FDocTypeMap.Add('6111=ΤΙΜ');
  FDocTypeMap.Add('6112=ΤΙΜ');
  FDocTypeMap.Add('6113=ΤΙΜ');
  FDocTypeMap.Add('6114=ΤΙΜ');
  FDocTypeMap.Add('6115=ΤΙΜ');
  FDocTypeMap.Add('6120=ΤΙΜ');
  FDocTypeMap.Add('61-R=ΤΙΜ');

  FDocTypeMap.Add('63=ΠΕΠ');
  FDocTypeMap.Add('6300=ΠΕΠ');
  FDocTypeMap.Add('6301=ΠΕΠ');
  FDocTypeMap.Add('6302=ΠΕΠ');
  FDocTypeMap.Add('6303=ΠΕΠ');
  FDocTypeMap.Add('6304=ΠΕΠ');
  FDocTypeMap.Add('6305=ΠΕΠ');
  FDocTypeMap.Add('6306=ΠΕΠ');
  FDocTypeMap.Add('6307=ΠΕΠ');
  FDocTypeMap.Add('6308=ΠΕΠ');
  FDocTypeMap.Add('6309=ΠΕΠ');
  FDocTypeMap.Add('6310=ΠΕΠ');
  FDocTypeMap.Add('6311=ΠΕΠ');
  FDocTypeMap.Add('6312=ΠΕΠ');
  FDocTypeMap.Add('6313=ΠΕΠ');
  FDocTypeMap.Add('6314=ΠΕΠ');
  FDocTypeMap.Add('6315=ΠΕΠ');
  FDocTypeMap.Add('6320=ΠΕΠ');
  FDocTypeMap.Add('63-R=ΠΕΠ');
  FDocTypeMap.Add('66=ΠΕΠ');

  FDocTypeMap.Add('64=ΠΕΚ');

  FMeasUnitMap.Add('ΚΙΒ=ΚΙΒ');
  FMeasUnitMap.Add('ΚΙΛ=ΚΙΛ');
  FMeasUnitMap.Add('ΤΕΜ=ΤΕΜ');

  FGLNMap.Add('35.071=1');    //    ΜΑΡΑΣΛΗ 18
  FGLNMap.Add('40.473=2');    //    ΧΑΙΡΙΑΝΩΝ 1
  FGLNMap.Add('40.476=3');    //    ΠΕΡΙΚΛΕΟΥΣ 46
  FGLNMap.Add('40.481=5');    //    25 ΜΑΡΤΙΟΥ 113-115
  FGLNMap.Add('40.477=6');    //    ΚΡΩΜΝΗΣ 38 & ΠΟΥΛΑΝ
  FGLNMap.Add('40.479=7');    //    ΚΑΡΑΚΑΣΗ 92
  FGLNMap.Add('35.072=8');    //    ΚΗΦΙΣΙΑΣ 12
  FGLNMap.Add('40.480=9');    //    ΛΑΜΠΡΑΚΗ 154
  FGLNMap.Add('40.088=10');   //    ΝΕΑ ΠΛΑΓΙΑ
  FGLNMap.Add('35.112=13');   //    ΒΕΝΙΖΕΛΟΥ 14
  FGLNMap.Add('35.091=12');   //    ΕΓΝΑΤΙΑ 6
  FGLNMap.Add('03.013=13');   //    ΒΕΝΙΖΕΛΟΥ 14
  FGLNMap.Add('22.112=13');   //    ΒΕΝΙΖΕΛΟΥ 14
  FGLNMap.Add('35.131=15');   //    ΝΙΚΟΠΟΛΕΩΣ 27 & ΧΙΟΥ
  FGLNMap.Add('40.478=17');   //    ΙΘΑΚΗΣ 43
  FGLNMap.Add('40.472=19');   //    ΠΑΡΑΣΚΕΥΟΠΟΥΛΟΥ 5
  FGLNMap.Add('35.073=20');   //    ΕΠΤΑΛΟΦΟΥ 6
  FGLNMap.Add('35.047=21');   //    Μ. ΑΛΕΞΑΝΔΡΟΥ 9 ΠΥΛΑΙΑ
  FGLNMap.Add('35.108=21');   //    Μ. ΑΛΕΞΑΝΔΡΟΥ 9 ΠΥΛΑΙΑ // *** Δεύτερο
  FGLNMap.Add('40.471=22');   //    ΑΙΓΑΙΟΥ
//  FGLNMap.Add('00=99');     //    14ΧΛΜ ΘΕΣΣΑΛΟΝΙΚΗΣ-ΜΟΥΔΑΝΙΩΝ
  FGLNMap.Add('40.474=23');   //    ΒΙΘΥΝΙΑΣ 37
  FGLNMap.Add('40.475=24');   //    ΠΟΝΤΟΥ
  FGLNMap.Add('Αφορά ΠΕΚ=24');//    ΠΟΝΤΟΥ
  FGLNMap.Add('35.132=25');   //    ΧΑΛΚΙΔΙΚΗΣ
  FGLNMap.Add('35.087=26');   //    ΤΕΡΖΗΣ ΠΥΛΑΙΑ
  FGLNMap.Add('35.109=26');   //    ΤΕΡΖΗΣ ΠΥΛΑΙΑ

end;
(*----------------------------------------------------------------------------*)
procedure TGeorgiadisDescriptor.AddFileItems;
begin
  inherited;

  { master }
//  FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,4-1));    // GLN
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,5-1));

  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  , 6-1));
//  FItemList.Add(TFileItem.Create(itBarcode      ,2  , 7-1));
  FItemList.Add(TFileItem.Create(itQty          ,2  , 9-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,10-1));
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,11-1));
  FItemList.Add(TFileItem.Create(itDisc         ,2  ,12-1)); // Value
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,13-1));
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,14-1));

end;


{ TGeorgiadisReader }
(*----------------------------------------------------------------------------*)
constructor TGeorgiadisReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ΓΕΩΡΓΙΑΔΗΣ');
end;
(*----------------------------------------------------------------------------*)
function TGeorgiadisReader.GetGLN: string;
begin
  if GetDocType = '64' then
    Result := 'Αφορά ΠΕΚ'
  else
    Result := GetStrDef(fiGLN);
end;
(*----------------------------------------------------------------------------*)
{function TGeorgiadisReader.GetRelDocNum: string;
begin
  Result := GetDocType + GetDocNo;
end;}
(*----------------------------------------------------------------------------*)
function TGeorgiadisReader.GetDiscount: double;
begin
// Εάν το παραστατικό είναι ΔΑΠ, η έκπτωση είναι 100%.
  if (DocType = '41') or
     (DocType = '42') or
     (DocType = '45') or
     (DocType = '4100') or
     (DocType = '4101') or
     (DocType = '4102') or
     (DocType = '4103') or
     (DocType = '4104') or
     (DocType = '4105') or
     (DocType = '4106') or
     (DocType = '4107') or
     (DocType = '4108') or
     (DocType = '4109') or
     (DocType = '4110') or
     (DocType = '4111') or
     (DocType = '4112') or
     (DocType = '4113') or
     (DocType = '4114') or
     (DocType = '4115') or
     (DocType = '4120') or
     (DocType = '41-R') or
     (DocType = '41-Τ') then
    Result := 100  // Δεν είναι σωστό, γιατί η έκπτωση είναι αξιακή.
                   // Σώνεται όμως γιατί βάζω και LineValue = 0.00
                   // Θα μπορούσα να υπολογίσω GetQty * GetPrice
  else
    Result := inherited GetDiscount;
end;
(*----------------------------------------------------------------------------*)
function TGeorgiadisReader.GetLineValue: Double;
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
function TGeorgiadisReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string;
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
//  SupMatCode := StripInt(SupMatCode); // Έχει κωδικούς με τελεία !!!

  if (SupMatCode = '08.02.001') then
    SupMatCode := '70001900';
// ΕΠΙΔ.ΓΙΑΟΥΡ HIGH PROTEIN ΦΡΑΟΥΛΑ 237ΓΡ ΜΕΒΓΑΛ
  if (SupMatCode = '62002030') then
    SupMatCode := '2832';
  if (SupMatCode = '63000013') then
// ΗΜΙΣΚ.ΤΥΡΙ ΜΑΚΕΔΟΝΙΚΟ 3ΧΛΜ (κωδ ζυγ=2032)
    SupMatCode := '10.04.026';

  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

  if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
  FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                 [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
end;
(*----------------------------------------------------------------------------*)
(* Για τον ΓΕΩΡΓΙΑΔΗ δεν κάνω τίποτα γιατί μου στέλνει το ΦΠΑ έτοιμο ---------*)
function TGeorgiadisReader.GetVAT(MatCode: string): string;

begin
    // Εμφανίζει το string 'ΦΠΑ-24'
 // Result := FloatToStr(Abs(StripReal(GetStrDef(fiVAT))));    //yannis commented


  // Χρειάζομαι το Abs γιατί κρατάει το "-".


  Result := Copy(GetStrDef(fiVAT), 5, 2);  //yannis code

  end;






(*----------------------------------------------------------------------------*)
function TGeorgiadisReader.DocStrToDate(S: string): TDate;
var ADay, AMonth, AYear : word;
    p : integer;
    ss : string;
begin
  // 1/2/2017
  p := pos('/', s);
  ADay   := StrToInt(LeftString(s, p-1));
  ss := RightString(s, Length(s) - p);
  p := pos('/', ss);
  AMonth := StrToInt(LeftString(ss, p-1));
  AYear  := StrToInt(RightString(s, 4));

  Result := EncodeDate(AYear, AMonth, ADay);
end;
(*----------------------------------------------------------------------------*)






initialization
  FileDescriptors.Add(TGeorgiadisDescriptor.Create);

end.
