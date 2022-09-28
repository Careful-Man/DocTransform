(*
  Επειδή αλλάζει κάθε φορά το format του excel, πρέπει να προβλέψω
  την ύπαρξη ή όχι διαφορετικό format ημαρομηνίας και αριθμών.

  Πρέπει να αφαιρώ την ημέρα της εβδομάδας από την ημ/νία.
*)
unit o_Orizontes;

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
  TOrizontesDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TOrizontesReader = class(TPurchaseReader)
 protected
   function GetGLN(): string; override;
   function GetVAT(MatCode: string): string; override;
   function DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;



implementation




{ TFarmaKoukakiDescriptor }
(*----------------------------------------------------------------------------*)
constructor TOrizontesDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ΟΡΙΖΟΝΤΕΣ';
  FFileName        := 'ΟΡΙΖΟΝΤΕΣ\ΑΦΡΟΔΙΤΗ*.csv';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  FAFM             := '094449779';

//  FIsOem           := True;

  FNeedsMapGln     := False;
 //  FIsMultiSupplier := True;

//  FNeedsMapPayMode := True;

  FDocTypeMap.Add('001=ΤΔΑ');
  FDocTypeMap.Add('002=ΠΕΠ');

  FMeasUnitMap.Add('101=ΤΕΜ');
  FMeasUnitMap.Add('102=ΚΙΛ');

end;
(*----------------------------------------------------------------------------*)
procedure TOrizontesDescriptor.AddFileItems;
begin
  inherited;

  { master }
//  FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,0-1)); // No GLN for Orizontes

  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  , 9-1));      // Παλιός κωδικός, από 1/1/13 νέος κωδικός.
  FItemList.Add(TFileItem.Create(itQty          ,2  ,19-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,15-1));
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,14-1)); // 1130, 1240
  FItemList.Add(TFileItem.Create(itDisc         ,2  ,16-1)); // Percent
  FItemList.Add(TFileItem.Create(itDisc2        ,2  ,17-1)); // Percent
  FItemList.Add(TFileItem.Create(itDisc3        ,2  ,18-1)); // Percent
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,21-1));
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,11-1));

end;

(***** Αντικατάσταση 599-005-013 - ΜΙΝΙ ΜΠΑΜΠΙΜΠΕΛ ΤΥΡΙ ΔΙΧΤ.120gr PLAY&WIN
             με      599-005-010 - LΑ VΑCΗΕ Q.R. BABYBEL 120ΓΡ                *****)



{ TOrizontesReader }
(*----------------------------------------------------------------------------*)
constructor TOrizontesReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ΟΡΙΖΟΝΤΕΣ');
end;
(*----------------------------------------------------------------------------*)
function TOrizontesReader.GetGLN: string;
begin
// Οι Ορίζοντες παραδίδει μόνο στην έδρα.
  Result := '99';
end;
(*----------------------------------------------------------------------------*)
(* Για τους ΟΡΙΖΟΝΤΕΣ δεν κάνω τίποτα γιατί μου στέλνει το ΦΠΑ έτοιμο -----------*)
function TOrizontesReader.GetVAT(MatCode: string): string;
var
  VATAsNumber : real;
  VATtmp: string;
begin
  // Εμφανίζει το string '1130' ή '1240'
  VATtmp := GetStrDef(fiVAT);
  VATAsNumber := (StrToFloat(VATtmp)-1000)/10;
  Result := FloatToStr(VATAsNumber);
end;
(*----------------------------------------------------------------------------*)
function TOrizontesReader.DocStrToDate(S: string): TDate;
var ADay, AMonth, AYear : word;
    p : integer;
begin
  // 8/8/2016

  AYear := StrToInt(RightString(S, 4));
// Από τo string αφαιρούμε το τελευταίο κομμάτι του έτους μαζί με την κάθετο.
// Τώρα έχω το 1/9
  S := LeftString(S, Length(S)-5);
  p := pos('/', S);
  ADay := StrToInt(StripInt(LeftString(S, p-1)));
  AMonth := StrToInt(RightString(S, Length(S)-p));
  Result := EncodeDate(AYear, AMonth, ADay);

end;
(*----------------------------------------------------------------------------*)






initialization
  FileDescriptors.Add(TOrizontesDescriptor.Create);

end.
