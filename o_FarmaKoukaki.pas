(*
  Επειδή αλλάζει κάθε φορά το format του excel, πρέπει να προβλέψω
  την ύπαρξη ή όχι διαφορετικό format ημαρομηνίας και αριθμών.

  Πρέπει να αφαιρώ την ημέρα της εβδομάδας από την ημ/νία.
*)
unit o_FarmaKoukaki;

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
  TFarmaKoukakiDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TFarmaKoukakiReader = class(TPurchaseReader)
 protected
   //function  ResolveGLN: Boolean; override;
   //function  GetDocDate: TDate; override;
   function GetGLN(): string; override;
   function GetDocType: string; override;
   function GetDocNo: string; override;
   function GetRelDocNum: string; override;
   function GetQty: Double; override;
   function GetLineValue: Double; override;
   function GetVAT(MatCode: string): string; override;
   function GetMeasUnitAA: integer; override;
   function GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function DocStrToDate(S: string): TDate; override;
   //function  GetPayType: string; override;
//   function StripInt(ToStrip: string):string;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;



implementation




{ TFarmaKoukakiDescriptor }
(*----------------------------------------------------------------------------*)
constructor TFarmaKoukakiDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ΦΑΡΜΑ-ΚΟΥΚΑΚΗ';
  FFileName        := 'ΦΑΡΜΑ ΚΟΥΚΑΚΗ\*.csv';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  FAFM             := '999811294';
  FNeedsMapGln     := True;
//  FIsMultiSupplier := True;

//  FNeedsMapPayMode := True;

//  FDocTypeMap.Add('ΑΤΔ=ΤΔΑ');
  FDocTypeMap.Add('ΤΔΑ=ΤΔΑ');
//  FDocTypeMap.Add('ΑΠΦ=ΠΕΠ');
//  FDocTypeMap.Add('ΑΠΔ=ΠΕΠ');
  FDocTypeMap.Add('ΠΕΔ=ΠΕΠ');
  FDocTypeMap.Add('ΠΕΠ=ΠΕΠ');
  FDocTypeMap.Add('ΠΕΚ=ΠΕΚ');
  FDocTypeMap.Add('ΠΤΖ=ΠΕΚ');

//  FDocTypeMap.Add('13=ΔΑΠ');


  FMeasUnitMap.Add('Τεμάχιο=ΤΕΜ');

  FGLNMap.Add('01=1');    //    ΜΑΡΑΣΛΗ 18
  FGLNMap.Add('02=2');    //    ΧΑΙΡΙΑΝΩΝ 1
  FGLNMap.Add('03=3');    //    ΠΕΡΙΚΛΕΟΥΣ 46
  FGLNMap.Add('08=5');    //    25 ΜΑΡΤΙΟΥ 113-115
  FGLNMap.Add('05=6');    //    ΚΡΩΜΝΗΣ 38 & ΠΟΥΛΑΝ
  FGLNMap.Add('04=7');    //    ΚΑΡΑΚΑΣΗ 92
  FGLNMap.Add('06=8');    //    ΚΗΦΙΣΙΑΣ 12
  FGLNMap.Add('07=9');    //    ΛΑΜΠΡΑΚΗ 154
  FGLNMap.Add('10=10');   //    ΝΕΑ ΠΛΑΓΙΑ
  FGLNMap.Add('09=12');   //    ΕΓΝΑΤΙΑ 6
  FGLNMap.Add('11=13');   //    ΒΕΝΙΖΕΛΟΥ 14
  FGLNMap.Add('13=15');   //    ΝΙΚΟΠΟΛΕΩΣ 27 & ΧΙΟΥ
  FGLNMap.Add('15=16');   //    ΠΛΑΤΕΙΑ ΤΕΡΨΙΘΕΑΣ
  FGLNMap.Add('17=17');   //    ΙΘΑΚΗΣ 43
  FGLNMap.Add('19=19');   //    ΠΑΡΑΣΚΕΥΟΠΟΥΛΟΥ 5
  FGLNMap.Add('20=20');   //    ΕΠΤΑΛΟΦΟΥ 6
  FGLNMap.Add('21=21');   //    Μ. ΑΛΕΞΑΝΔΡΟΥ 9 ΠΥΛΑΙΑ
  FGLNMap.Add('22=22');   //    ΑΙΓΑΙΟΥ
  FGLNMap.Add('00=99');  //    14ΧΛΜ ΘΕΣΣΑΛΟΝΙΚΗΣ-ΜΟΥΔΑΝΙΩΝ
  FGLNMap.Add('0=99');   //    14ΧΛΜ ΘΕΣΣΑΛΟΝΙΚΗΣ-ΜΟΥΔΑΝΙΩΝ
  FGLNMap.Add('  =99');  //    14ΧΛΜ ΘΕΣΣΑΛΟΝΙΚΗΣ-ΜΟΥΔΑΝΙΩΝ
  FGLNMap.Add('1=1');    //    ΜΑΡΑΣΛΗ 18
  FGLNMap.Add('2=2');    //    ΧΑΙΡΙΑΝΩΝ 1
  FGLNMap.Add('3=3');    //    ΠΕΡΙΚΛΕΟΥΣ 46
  FGLNMap.Add('8=5');    //    25 ΜΑΡΤΙΟΥ 113-115
  FGLNMap.Add('5=6');    //    ΚΡΩΜΝΗΣ 38 & ΠΟΥΛΑΝ
  FGLNMap.Add('4=7');    //    ΚΑΡΑΚΑΣΗ 92
  FGLNMap.Add('6=8');    //    ΚΗΦΙΣΙΑΣ 12
  FGLNMap.Add('7=9');    //    ΛΑΜΠΡΑΚΗ 154
  FGLNMap.Add('9=12');   //    ΕΓΝΑΤΙΑ 6
  FGLNMap.Add('23=23');  //    ΒΙΘΥΝΙΑΣ 37
  FGLNMap.Add('24=24');  //    ΠΟΝΤΟΥ
  FGLNMap.Add('25=25');  //    ΧΑΛΚΙΔΙΚΗΣ
  FGLNMap.Add('26=26');  //    ΤΕΡΖΗΣ ΠΥΛΑΙΑ

{
select aa
from MeasUnit
where Code = :c

select AA
from MtrlMUnt WITH (READUNCOMMITTED)
where MaterialAA = :MatAA
and MUnitAA = :MM

select
  MtrlMUnt.AA    as AA
from
  MtrlMUnt
    join MeasUnit on MeasUnit.AA = MtrlMUnt.MUnitAA
where
       MtrlMUnt.MaterialAA = :MatAA
   and MeasUnit.Code       = :MeasUnit_Code

}
end;
(*----------------------------------------------------------------------------*)
procedure TFarmaKoukakiDescriptor.AddFileItems;
begin
  inherited;

  { master }
//  FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,4-1));
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,4-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,7-1));    // GLN

  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  , 9-1));      // Παλιός κωδικός, από 1/1/13 νέος κωδικός.
  FItemList.Add(TFileItem.Create(itQty          ,2  ,11-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,13-1));
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,15-1));
  FItemList.Add(TFileItem.Create(itDisc         ,2  ,14-1)); // Percent
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,12-1));
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,17-1));

end;


{ TFarmaKoukakiReader }
(*----------------------------------------------------------------------------*)
constructor TFarmaKoukakiReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ΦΑΡΜΑ-ΚΟΥΚΑΚΗ');
end;
(*----------------------------------------------------------------------------*)
function TFarmaKoukakiReader.GetGLN: string;
begin
  Result := GetStrDef(fiGLN);
  if Result = '' then
    Result := '  ';
end;
(*----------------------------------------------------------------------------*)
function TFarmaKoukakiReader.GetDocType: string;
var
  s: string;
begin
  s := GetStrDef(fiDocType);
  Result := Copy(s, Length(s)-3+1, 3);
end;
(*----------------------------------------------------------------------------*)
function TFarmaKoukakiReader.GetDocNo: string;
var
  s: string;
begin
  s := GetStrDef(fiDocChanger);
  Result := TrimLeftZeroes(RightString(s, 5));
//  Result := StripRightmostInt(s);
end;
(*----------------------------------------------------------------------------*)
function TFarmaKoukakiReader.GetRelDocNum: string;
begin
  Result := GetDocNo;
end;
(*----------------------------------------------------------------------------*)
function TFarmaKoukakiReader.GetQty: Double;
var
  S : string;
begin
  S := GetStrDef(fiQty, '0');
//  S := Utls.CommaToDot(S);
//  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
//  S := CommaToDot(S);
  S := DotToComma(S);
//  Result := abs(StrToFloat(S, GlobalFormatSettings));
  Result := abs(StrToFloat(S));
end;
(*----------------------------------------------------------------------------*)
function TFarmaKoukakiReader.GetLineValue: Double;
var
  S : string;
begin
  S := GetStrDef(fiLineValue, '0');
//  S := Utls.CommaToDot(S);
//  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
//  S := CommaToDot(S);
  S := DotToComma(S);
//  Result := abs(StrToFloat(S, GlobalFormatSettings));
  Result := abs(StrToFloat(S));
end;
(*----------------------------------------------------------------------------*)
(* Για τον ΚΟΥΚΑΚΗ δεν κάνω τίποτα γιατί μου στέλνει το ΦΠΑ έτοιμο -----------*)
function TFarmaKoukakiReader.GetVAT(MatCode: string): string;
begin
  // Εμφανίζει το string 'ΦΠΑ 13% Νέος Συντελεστής'
  Result := FloatToStr(StripReal(GetStrDef(fiVAT)));
end;
(*----------------------------------------------------------------------------*)
function TFarmaKoukakiReader.GetMeasUnitAA: integer;
var
  S : string;
begin
  S := GetStrDef(fiMeasUnit, 'Τεμάχιο');

  if (S <> '000') then
  begin
    S      := FDescriptor.MeasUnitMap.Values[S];
    Result := FManager.GetMaterialMeasureUnitAA(MatAA, S);
  end else
    Result := -1;

end;
(*----------------------------------------------------------------------------*)
function TFarmaKoukakiReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

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

// Αντικατάσταση για ΧΥΜΟΣ ΠΟΡΤΟΚΑΛΙ  500ml (Επιστροφή)
  if (SupMatCode = '0151') then
    SupMatCode := '0152';

  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

  if not Result then
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                   [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));

end;
(*----------------------------------------------------------------------------*)
function TFarmaKoukakiReader.DocStrToDate(S: string): TDate;
var ADay, AMonth, AYear : word;
    p : integer;
begin
  // 29/10/12

  S := StripDate(S);
{  Result := EncodeDate(StrToInt(Copy(S, 7, 2)) + 2000,
                       StrToInt(Copy(S, 4, 2)),
                       StrToInt(Copy(S, 1, 2)));
}

  // 1/9/2014

  // Σε όποια θέση και να είναι το έτος, το διαβάζω πάντα σωστά.
  AYear := StrToInt(RightString(S, 4));
//  ShowMessage(Copy(S, 6, 4));
// Από τo string αφαιρούμε το τελευταίο κομμάτι του έτους μαζί με την κάθετο.
// Τώρα έχω το 1/9
  S := LeftString(S, Length(S)-5);
  p := pos('/', S);
  ADay := StrToInt(LeftString(S, p-1));
//  ShowMessage(LeftString(S, Length(S)-p));
  AMonth := StrToInt(RightString(S, Length(S)-p));
//  ShowMessage(RightString(S, Length(S)-p));

  Result := EncodeDate(AYear, AMonth, ADay);
end;
(*----------------------------------------------------------------------------*)






initialization
  FileDescriptors.Add(TFarmaKoukakiDescriptor.Create);

end.
