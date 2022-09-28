(*
  Επειδή αλλάζει κάθε φορά το format του excel, πρέπει να προβλέψω
  την ύπαρξη ή όχι διαφορετικό format ημαρομηνίας και αριθμών.

  Πρέπει να αφαιρώ την ημέρα της εβδομάδας από την ημ/νία.
*)
unit o_XatziGiannakidi;

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
  TXatziGiannakidiDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TXatziGiannakidiReader = class(TPurchaseReader)
 protected
   function GetDocNo: string; override;
//   function GetRelDocNum: string; override;
   function GetQty: Double; override;
   function GetLineValue: Double; override;
   function DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;



implementation




{ TXatziGiannakidiDescriptor }
(*----------------------------------------------------------------------------*)
constructor TXatziGiannakidiDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ΧΑΤΖΗΓΙΑΝΝΑΚΙΔΗ';
  FFileName        := 'Χ_Γιαννακίδη\ΑΦΡΟΔΙΤΗ*.csv';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;

  FAFM             := '998973771';

  FNeedsMapGln     := True;

  FNeedsMapPayMode := True;
  FPayModeMap.Add('1=ΜΕΤΡΗΤΑ');
  FPayModeMap.Add('2=ΕΠΙ ΠΙΣΤΩΣΗ');
  FPayModeMap.Add('3=ΕΠΙ ΠΙΣΤΩΣΗ'); // Με αντικαταβολή


  FDocTypeMap.Add('ΤΙΜ=ΤΙΜ');
  FDocTypeMap.Add('ΤΙΧ=ΤΙΜ');
  FDocTypeMap.Add('ΤΠΥ=ΤΠΥ');  // Παροχής υπηρεσιών
  FDocTypeMap.Add('ΤΠΥΧ=ΤΠΥ'); // Παροχής υπηρεσιών
  FDocTypeMap.Add('ΤΧ=ΤΔΑ');
  FDocTypeMap.Add('ΤΧΑ=ΤΔΑ');
  FDocTypeMap.Add('ΤΧΒ=ΤΔΑ');
  FDocTypeMap.Add('ΤΧΓ=ΤΔΑ');
  FDocTypeMap.Add('ΤΧΔ=ΤΔΑ');
  FDocTypeMap.Add('ΤΔΑ=ΤΔΑ');
  FDocTypeMap.Add('ΦΤΑ=ΤΔΑ');
  FDocTypeMap.Add('ΦΤΒ=ΤΔΑ');
  FDocTypeMap.Add('ΦΤΓ=ΤΔΑ');
  FDocTypeMap.Add('ΦΤΔ=ΤΔΑ');
  FDocTypeMap.Add('ΦΤΕ=ΤΔΑ');
  FDocTypeMap.Add('ΦΤΖ=ΤΔΑ');

  FDocTypeMap.Add('ΔΑΠ=ΔΑΠ');
  FDocTypeMap.Add('ΔΑΕ=ΔΑΠ');
  FDocTypeMap.Add('ΔΑΧ=ΔΑΠ');
  FDocTypeMap.Add('ΦΔΑ=ΔΑΠ');
  FDocTypeMap.Add('ΦΔΒ=ΔΑΠ');
  FDocTypeMap.Add('ΦΔΓ=ΔΑΠ');
  FDocTypeMap.Add('ΦΔΔ=ΔΑΠ');
  FDocTypeMap.Add('ΦΔΕ=ΔΑΠ');
  FDocTypeMap.Add('ΦΔΖ=ΔΑΠ');

  FDocTypeMap.Add('ΠΠΧ=ΠΕΠ');
  FDocTypeMap.Add('ΦΛΑ=ΠΕΠ');
  FDocTypeMap.Add('ΦΛΒ=ΠΕΠ');
  FDocTypeMap.Add('ΦΛΓ=ΠΕΠ');
  FDocTypeMap.Add('ΦΛΔ=ΠΕΠ');
  FDocTypeMap.Add('ΦΛΕ=ΠΕΠ');
  FDocTypeMap.Add('ΦΛΖ=ΠΕΠ');
  FDocTypeMap.Add('ΠΤΑ=ΠΕΠ');
  FDocTypeMap.Add('ΠΤΑ=ΠΕΠ');
  FDocTypeMap.Add('ΠΕΔ=ΠΕΠ');


  FMeasUnitMap.Add('1=ΤΕΜ');
  FMeasUnitMap.Add('2=ΚΙΛ');
  FMeasUnitMap.Add('3=ΚΙΒ');
  FMeasUnitMap.Add('5=ΛΙΤ');


  FGLNMap.Add('001=5');
  FGLNMap.Add('002=2');
  FGLNMap.Add('003=3');
  FGLNMap.Add('004=7');
  FGLNMap.Add('005=6');
  FGLNMap.Add('006=8');
  FGLNMap.Add('007=9');
  FGLNMap.Add('008=10');
  FGLNMap.Add('009=12');
  FGLNMap.Add('010=13');
//  FGLNMap.Add('011=14');
  FGLNMap.Add('012=15');
//  FGLNMap.Add('013=16');
  FGLNMap.Add('014=1');
  FGLNMap.Add('015=17');
  //FGLNMap.Add('016=18');
  FGLNMap.Add('017=19');
  FGLNMap.Add('018=20');
  FGLNMap.Add('019=21');
  FGLNMap.Add('020=22');
  FGLNMap.Add('021=23');
  FGLNMap.Add('022=24');
  FGLNMap.Add('023=25');
  FGLNMap.Add('024=26');
  FGLNMap.Add('099=99');

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
procedure TXatziGiannakidiDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,4-1));
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,4-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,7-1));
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,9-1));


  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  ,11-1));
  FItemList.Add(TFileItem.Create(itQty          ,2  ,14-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,16-1));
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,19-1));
  FItemList.Add(TFileItem.Create(itDisc         ,2  ,17-1)); // Percent
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,15-1));
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,20-1));

end;





{ TXatziGiannakidiReader }
(*----------------------------------------------------------------------------*)
constructor TXatziGiannakidiReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ΧΑΤΖΗΓΙΑΝΝΑΚΙΔΗ');
end;
(*----------------------------------------------------------------------------*)
function TXatziGiannakidiReader.GetDocNo: string;
var
  s: string;
begin
  s := RightString(GetStrDef(fiDocID), 6);
  Result := TrimLeftZeroes(s);
end;
(*----------------------------------------------------------------------------*)
(*function TXatziGiannakidiReader.GetRelDocNum: string;
begin
  Result := GetDocType + GetDocNo;
end;*)
(*----------------------------------------------------------------------------*)
function TXatziGiannakidiReader.GetQty: Double;
var
  S : string;
begin
  S := GetStrDef(fiQty, '0');
//  S := Utls.CommaToDot(S);
//  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  S := DotToComma(S);
  Result := abs(StrToFloat(S));
end;
(*----------------------------------------------------------------------------*)
function TXatziGiannakidiReader.GetLineValue: Double;
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
function TXatziGiannakidiReader.DocStrToDate(S: string): TDate;
var ADay, AMonth, AYear : word;
    p : integer;
begin
  S := StripDate(S);

  // 04/01/2016

  // Σε όποια θέση και να είναι το έτος, το διαβάζω πάντα σωστά.
  AYear := StrToInt(RightString(S, 4));
// Από τo string αφαιρούμε το τελευταίο κομμάτι του έτους μαζί με την κάθετο.
  S := LeftString(S, Length(S)-5);
  p := pos('/', S);
  ADay := StrToInt(LeftString(S, p-1));
  AMonth := StrToInt(RightString(S, Length(S)-p));
  Result := EncodeDate(AYear, AMonth, ADay);
end;
(*----------------------------------------------------------------------------*)



initialization
  FileDescriptors.Add(TXatziGiannakidiDescriptor.Create);

end.
