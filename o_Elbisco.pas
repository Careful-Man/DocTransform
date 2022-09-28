unit o_Elbisco;

interface

uses
   Windows
  ,SysUtils
  ,Classes
  ,Controls
  ,Forms
  ,Contnrs
  ,Db
  ,ADODB
  ,MidasLib
  ,Variants
  ,IniFiles
  ,StrUtils
//  ,tpk_Utls
  ,o_Descriptors
  ,o_Managers
  ,o_Purchases


  ,uStringHandlingRoutines
     ;


type
(*----------------------------------------------------------------------------*)
  TElbiscoDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TElbiscoReader = class(TPurchaseReader)
 protected
   FCon : TADOConnection;
   function DocStrToDate(S: string): TDate; override;
   function GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function GetPrice: Double; override;
   function GetQty: Double; override;
   function GetLineValue: Double; override;
   function GetVAT(MatCode: string): string; override;

 public
   function Select(SqlText: string): TDataset;
   constructor Create(Manager: TInputManager; Title: string); override;
 end;

var ASupMatCode : string;

implementation

{ TElbiscoDescriptor }
(*----------------------------------------------------------------------------*)
constructor TElbiscoDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ELBISCO';
  FFileName        := 'ELBISCO\EDI_0026008_ΑΦΡΟΔΙΤΗ*.txt';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  //FMasterMarker    := 'H';
  //FDetailMarker    := 'D';
  FAFM             := '094207902';
  FNeedsMapGln     := True;

  FDocTypeMap.Add('E00=ΔΑΠ');
  FDocTypeMap.Add('I00=ΔΑΠ');
  FDocTypeMap.Add('I01=ΤΔΑ');
  FDocTypeMap.Add('I02=ΤΙΜ');
  FDocTypeMap.Add('I03=ΠΕΠ');
  FDocTypeMap.Add('I04=ΠΕΠ');
  FDocTypeMap.Add('I05=ΠΕΚ');

  FMeasUnitMap.Add('PCS=ΤΕΜ');
  FMeasUnitMap.Add('BOX=ΚΙΒ');


  FGLNMap.Add('0011158=1');     //    ΜΑΡΑΣΛΗ 18
  FGLNMap.Add('0013920=2');     //    ΧΑΙΡΙΑΝΩΝ 1
  FGLNMap.Add('0013921=3');     //    ΠΕΡΙΚΛΕΟΥΣ 46
  FGLNMap.Add('0013928=5');     //    25 ΜΑΡΤΙΟΥ 113-115
  FGLNMap.Add('0013923=6');     //    ΚΡΩΜΝΗΣ 38 & ΠΟΥΛΑΝ
  FGLNMap.Add('0013922=7');     //    ΚΑΡΑΚΑΣΗ 92
  FGLNMap.Add('0013924=8');     //    ΚΗΦΙΣΙΑΣ 12
  FGLNMap.Add('0013925=9');     //    ΛΑΜΠΡΑΚΗ 154
  FGLNMap.Add('0013926=10');    //    ΝΕΑ ΠΛΑΓΙΑ
  FGLNMap.Add('0013929=12');    //    ΕΓΝΑΤΙΑ 6
  FGLNMap.Add('0013930=13');    //    ΒΕΝΙΖΕΛΟΥ 14
  FGLNMap.Add('0018497=14');    //    27οχΑμ.ΘΕΣ/ΝΙΚΗΣ-ΜΗΧΑΝΙΩΝΑΣ
  FGLNMap.Add('0020660=15');    //    ΝΙΚΟΠΟΛΕΩΣ 27 & ΧΙΟΥ
  FGLNMap.Add('0024951=16');    //    ΠΛΑΤΕΙΑ ΤΕΡΨΙΘΕΑΣ
  FGLNMap.Add('0026812=17');    //    ΙΘΑΚΗΣ 43
  FGLNMap.Add('0027015=18');    //    ΠΛΑΤΩΝΟΣ & ΙΠΠΙΚΡΑΤΟΥΣ ΓΩΝΙΑ
  FGLNMap.Add('0029740=19');    //    ΠΑΡΑΣΚΕΥΟΠΟΥΛΟΥ 5
  FGLNMap.Add('0030582=20');    //    ΕΠΤΑΛΟΦΟΥ 6
  FGLNMap.Add('0033144=21');    //    Μ. ΑΛΕΞΑΝΔΡΟΥ 9 ΠΥΛΑΙΑ
  FGLNMap.Add('0035297=22');    //    ΑΙΓΑΙΟΥ 80 ΚΑΛΑΜΑΡΙΑ
  FGLNMap.Add('0013930=23');    //    ΒΙΘΥΝΙΑΣ 37 ΚΑΛΑΜΑΡΙΑ
  FGLNMap.Add('0035788=23');    //    ΒΙΘΥΝΙΑΣ 37 ΚΑΛΑΜΑΡΙΑ
  FGLNMap.Add('0037069=24');    //    ΠΟΝΤΟΥ 109 ΚΑΛΑΜΑΡΙΑ
  FGLNMap.Add('0044098=25');    //    ΧΑΛΚΙΔΙΚΗΣ 19 ΘΕΣΣΑΛΟΝΙΚΗ
  FGLNMap.Add('0044634=26');    //    ΤΕΡΖΗΣ
  FGLNMap.Add('0026008=99');    //    14ΧΛΜ ΘΕΣΣΑΛΟΝΙΚΗΣ-ΜΟΥΔΑΝΙΩΝ




end;
(*----------------------------------------------------------------------------*)
procedure TElbiscoDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate       ,1  ,71   ,8));
  FItemList.Add(TFileItem.Create(itDocType    ,1  ,62   ,4));
  FItemList.Add(TFileItem.Create(itDocId      ,1  ,34   ,15));
  FItemList.Add(TFileItem.Create(itDocChanger ,1  ,4    ,15));
  FItemList.Add(TFileItem.Create(itGLN        ,1  ,151  ,10));    // GLN

  // itRelDoc = itDocType + itDocId

  { detail }
  FItemList.Add(TFileItem.Create(itCode              ,2  ,303  ,15));        // θέλει lookup select
//  FItemList.Add(TFileItem.Create(itBarcode           ,2  ,289  ,14));
  FItemList.Add(TFileItem.Create(itQty               ,2  ,369  ,10));
  FItemList.Add(TFileItem.Create(itPrice             ,2  ,339  ,15));
  FItemList.Add(TFileItem.Create(itVAT               ,2  ,214  ,3));         // percent
  FItemList.Add(TFileItem.Create(itVAT2              ,2  ,232  ,3));         // percent
  FItemList.Add(TFileItem.Create(itDisc              ,2  ,199  ,15));        // disc value
  FItemList.Add(TFileItem.Create(itLineValue         ,2  ,318  ,15));
  FItemList.Add(TFileItem.Create(itMeasUnit          ,2  ,379  ,3));
  FItemList.Add(TFileItem.Create(itMeasUnitRelation  ,2  ,382  ,10));
end;


{ TElbiscoReader }
(*----------------------------------------------------------------------------*)
constructor TElbiscoReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ELBISCO');
end;
(*----------------------------------------------------------------------------*)
function TElbiscoReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

  function GetMatCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
  begin
    Result  := False;

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

//var OriginalSupMatCode : string;

begin
  Result := False;

//  OriginalSupMatCode := SupMatCode;
// Αντικατάσταση κωδικών για τα stand
  if (SupMatCode = '105012') or (SupMatCode = '105026') or (SupMatCode = '105029')
  or (SupMatCode = '105038') or (SupMatCode = '105042') or (SupMatCode = '105043')
  or (SupMatCode = '105045') or (SupMatCode = '105048') or (SupMatCode = '105049')
  or (SupMatCode = '105057') or (SupMatCode = '105061') or (SupMatCode = '105064')
  or (SupMatCode = '105066') or (SupMatCode = '105068') or (SupMatCode = '105070')
  or (SupMatCode = '105071') or (SupMatCode = '105072') or (SupMatCode = '105073')
  or (SupMatCode = '105074') or (SupMatCode = '105079') or (SupMatCode = '105080')
  or (SupMatCode = '105082') or (SupMatCode = '106000') or (SupMatCode = '106040')
  or (SupMatCode = '106041') or (SupMatCode = '106043') or (SupMatCode = '106044')
  or (SupMatCode = '107010') or (SupMatCode = '107011') or (SupMatCode = '107012')
  or (SupMatCode = '107040') or (SupMatCode = '107060') or (SupMatCode = '107071')
  or (SupMatCode = '107072')
  then
    SupMatCode  := '105040';

// Αντικατάσταση κωδικών για ΑΛΛΑΤΙΝΗ SOFT COOKIES ΓΙΑΟΥΡ-ΠΟΡ-ΣΟΚ 160ΓΡ
//  if (SupMatCode = '110200') then      // Υπήρχε το αντίθετο !!
//    SupMatCode  := '110209';

// Αντικατάσταση κωδικών για ΑΛΛΑΤΙΝΗ SOFT COOKIES ΓΙΑΟΥΡ-ΠΟΡ-ΣΟΚ 160ΓΡ
  if (SupMatCode = '110209') then
    SupMatCode  := '110200';

// Αντικατάσταση κωδικών για GOODY ΚΑΝΕΛΛΑ 185ΓΡ ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '110228') then
    SupMatCode  := '110221';

// Αντικατάσταση κωδικών για ΑΛΛΑΤΙΝΗ ΒΟΥΤΗΧΤΑ ΚΛΑΣ 250ΓΡ (-0,20Ε)
  if (SupMatCode = '110299') then
    SupMatCode  := '110290';

// Αντικατάσταση κωδικών για DΙGΕSΤΙVΕ CΟΟΚΙΕS ΣΤΑΦΙΔΑ ΚΑΝΕΛΑ 220ΓΡ
//  if (SupMatCode = '110339') then
//    SupMatCode  := '110330';

// Αντικατάσταση κωδικών για DΙGΕSΤΙVΕ CΟΟΚΙΕS ΣΤΑΦΙΔΑ ΚΑΝΕΛΑ 220ΓΡ
  if (SupMatCode = '110339') then
    SupMatCode  := '111040';

// Αντικατάσταση κωδικών για ΑΛΛΑΤΙΝΗ SOFT COOKIES ΓΙΑΟΥΡ-ΣΤΑΦ 160ΓΡ
  if (SupMatCode = '110409') then
    SupMatCode  := '110400';

//// Αντικατάσταση κωδικών για DΙGΕSΤΙVΕ CΟΟΚΙΕS 3ΔΗΜ  ΣΟΚΟΛΑΤΑ 220ΓΡ
//  if (SupMatCode = '110429') then
//    SupMatCode  := '110420';
//

// Αντικατάσταση κωδικών για DΙGΕSΤΙVΕ CΟΟΚΙΕS 3ΔΗΜ  ΣΟΚΟΛΑΤΑ 220ΓΡ
//  if (SupMatCode = '110429') then
//    SupMatCode  := '111080';

// Αντικατάσταση κωδικών για ΓΕΜΙΣΤΑ 100% ΟΛ ΑΛ ΠΡΑΛ ΑΛΛΑΤΙΝΗ 160ΓΡ
  if (SupMatCode = '110519') then
    SupMatCode  := '110510';

// Αντικατάσταση κωδικών για DΙGΕSΤΙVΕ CΟΟΚΙΕS ΤΣΙΑ ΚΕΧΡΙ ΜΑΥΡΟΣΟΥΣ 220ΓΡ
  if (SupMatCode = '110829') then
    SupMatCode  := '110820';

// Αντικατάσταση κωδικών για GOODY ΒΟΥΤΥΡΟΥ 175ΓΡ ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '110919') then
    SupMatCode  := '110910';

// Αντικατάσταση κωδικών για DΙGΕSΤΙVΕ CΟΟΚΙΕS ΑΛΛΑΤΙΝΗ 220ΓΡ
  if (SupMatCode = '111019') then
    SupMatCode  := '111010';

// Αντικατάσταση κωδικών για DΙGΕSΤΙVΕ CΟΟΚΙΕS ΑΛΛΑΤΙΝΗ 250ΓΡ
  if (SupMatCode = '111029') then
    SupMatCode  := '111020';

// Αντικατάσταση κωδικών για DΙGΕSΤΙVΕ CΟΟΚΙΕS ΧΩΡΙΣ ΖΑΧΑΡΗ ΑΛΛΑΤΙΝΗ 250ΓΡ
  if (SupMatCode = '111069') then
    SupMatCode  := '111060';

// Αντικατάσταση κωδικών για ΑΛΛΑΤΙΝΗ ΑΛΕΥΡΙ Γ.Ο.Χ. 1ΚΛ (-0,30Ε)
  if (SupMatCode = '111708') then
    SupMatCode  := '111701';

// Αντικατάσταση κωδικών για ΑΛΛΑΤΙΝΗ ΑΛΕΥΡΙ ΟΛΙΚΗΣ 1ΚΛ (-0,30Ε)
  if (SupMatCode = '111739') then
    SupMatCode  := '111730';

// Αντικατάσταση κωδικών για ΑΛΛΑΤΙΝΗ ΑΛΕΥΡΙ ΚΙΤΡΙΝΟ 1ΚΛ (-0,25Ε)
  if (SupMatCode = '111797') then
    SupMatCode  := '111792';

// Αντικατάσταση κωδικών για ΑΛΕΥΡΙ  ΑΛΛΑΤΙΝΗ Γ.Ο.Χ ΧΩΡΙΣ ΓΛΟΥΤΕΝΗ 1ΚΛ
  if (SupMatCode = '111809') then
    SupMatCode  := '111800';

// Αντικατάσταση κωδικών για ΑΛΛΑΤΙΝΗ ΑΛΕΥΡΙ ΕΧΤΡΑ ΔΥΝΑΤΟ 1ΚΛ (-0,30Ε)
  if (SupMatCode = '111898') then
    SupMatCode  := '111891';

// Αντικατάσταση κωδικών για ΒΑΝΙΛΙΑ ΚΡΕΜΑ ΜΠΙΣΚ ΓΕΜ 200ΓΡ ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '111929') then
    SupMatCode  := '111920';

// Αντικατάσταση κωδικών για ΜΠΙΣ.ΓΕΜ.ΚΑΚΑΟ-ΒΑΝΙΛΙΑ
  if (SupMatCode = '111939') then
    SupMatCode  := '111931';

// Αντικατάσταση κωδικών για ΓΕΜΙΣΤΑ ΓΕΜΑΤΑ & ΤΡΑΓΑΝΑ BAN ΑΛΛΑΤΙΝΗ 230ΓΡ
  if (SupMatCode = '111959') then
    SupMatCode  := '111950';

// Αντικατάσταση κωδικών για ΓΕΜΙΣΤΑ ΓΕΜΑΤΑ & ΤΡΑΓΑΝΑ ΦΡΑ ΑΛΛΑΤΙΝΗ 230ΓΡ
  if (SupMatCode = '111989') then
    SupMatCode  := '111980';

// Αντικατάσταση κωδικών για ΓΕΜΙΣΤΑ ΓΕΜΑΤΑ & ΤΡΑΓΑΝΑ ΠΟΡΤ ΑΛΛΑΤΙΝΗ 230ΓΡ
  if (SupMatCode = '111999') then
    SupMatCode  := '111990';

// Αντικατάσταση κωδικών για ΒΟΣΙΝΑΚΗ ΑΛΕΥΡΙ Γ.Ο.Χ 1ΚΛ
  if (SupMatCode = '113009') then
    SupMatCode  := '113000';

// Αντικατάσταση κωδικών για ΑΛΕΥΡΙ Γ.Ο.Χ  ΒΟΣΙΝΑΚΗ 5ΚΛ
  if (SupMatCode = '113029') then
    SupMatCode  := '113020';

// Αντικατάσταση κωδικών για CΟΟΚΙΕS ΣΟΚ&ΦΟΥΝΤ 175ΓΡ ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '113519') then
    SupMatCode  := '113510';

// Αντικατάσταση κωδικών για SOFT KINGS ΠΟΡΤ 180ΓΡ
  if (SupMatCode = '114327') then
    SupMatCode  := '114322';

// Αντικατάσταση κωδικών για CΟΟΚΙΕS BITES ΜΕ ΕΠΙΚ.ΣΟΚ ΓΑΛ 70ΓΡ
  if (SupMatCode = '114459') then
    SupMatCode  := '114450';

// Αντικατάσταση κωδικών για SOFT KINGS CHOCO+STRAWBERRY 180ΓΡ
  if (SupMatCode = '114717') then
    SupMatCode  := '114710';

// Αντικατάσταση κωδικών για SOFT KINGS COOKIE CHOCO 45ΓΡ
  if (SupMatCode = '116109') then
    SupMatCode  := '116100';

// Αντικατάσταση κωδικών για SOFT KINGS COOKIE DARK CHOCO 45ΓΡ
  if (SupMatCode = '116119') then
    SupMatCode  := '116110';

// Αντικατάσταση κωδικών για SOFT KINGS COOKIE TRIPLE CHOCO 45ΓΡ
  if (SupMatCode = '116129') then
    SupMatCode  := '116120';

// Αντικατάσταση κωδικών για SOFT KINGS COOKIE CARAM & PECAN 45ΓΡ
  if (SupMatCode = '116139') then
    SupMatCode  := '116130';

// Αντικατάσταση κωδικών για SOFT KINGS COOKIE DARK CHOCO 180ΓΡ
  if (SupMatCode = '116219') then
    SupMatCode  := '116210';

// Αντικατάσταση κωδικών για SOFT KINGS COOKIE CHOCO 180ΓΡ
  if (SupMatCode = '116209') then
    SupMatCode  := '116200';

// Αντικατάσταση κωδικών για SOFT KINGS COOKIE TRIPLE CHOCO 180ΓΡ
  if (SupMatCode = '116239') then
    SupMatCode  := '116230';

// Αντικατάσταση κωδικών για SOFT KINGS COCONUT-WHITE CHOCO 180ΓΡ
  if (SupMatCode = '116259') then
    SupMatCode  := '116250';

// Αντικατάσταση κωδικών για ΜΠΕΪΚΙΝ ΠΑΟΥΝΤΕΡ ΦΑΚ.20ΓΡ (2+1) ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '117118') then
    SupMatCode  := '117111';

// Αντικατάσταση κωδικών για ΞΗΡΗ ΜΑΓΙΑ ΑΛΛΑΤΙΝΗ 27ΓΡ
  if (SupMatCode = '117259') then
    SupMatCode  := '117250';

// Αντικατάσταση κωδικών για ΜΠΙΣΚ.ΠΑΡΚΟ ΜΕ ΓΑΛΑ-ΣΟΚ 270ΓΡ
  if (SupMatCode = '118139') then
    SupMatCode  := '118130';

// Αντικατάσταση κωδικών για ΜΠΙΣΚ.ΠΑΡΚΟ ΜΕ ΓΑΛΑ 270ΓΡ
  if (SupMatCode = '118129') then
    SupMatCode  := '118120';

// Αντικατάσταση κωδικών για ΑΛΛΑΤΙΝΗ ΑΛΕΥΡΙ ΚΕΙΚ ΦΛΑΟΥΡ 500ΓΡ (-0,30Ε)
  if (SupMatCode = '119459') then
    SupMatCode  := '119450';

// Αντικατάσταση κωδικών για ΦΑΡΙΝΑ ΑΛΛΑΤΙΝΗ ΚΕΙΚ ΦΛΑΟΥΡ 500ΓΡ (-0,25Ε)
  if (SupMatCode = '119469') then
    SupMatCode  := '119460';

// Αντικατάσταση κωδικών για DΙGΕSΤΙVΕ CΟΟΚΙΕS ΜΠΟΥΚΙΕΣ ΔΗΜ CRANBERRY 40ΓΡ
  if (SupMatCode = '120129') then
    SupMatCode  := '120120';

// Αντικατάσταση κωδικών για DΙGΕSΤΙVΕ CΟΟΚΙΕS ΜΠΟΥΚΙΕΣ ΔΗΜ ΜΗΛΟ ΚΑΝΕΛΑ 40ΓΡ
  if (SupMatCode = '120529') then
    SupMatCode  := '120520';

// Αντικατάσταση κωδικών για ΜΠ.ΠΤΙ-ΜΠΕΡ ΑΛΛΑΤΙΝΗ ΟΛ.ΑΛΕΣΗΣ 225ΓΡ
  if (SupMatCode = '122772') then
    SupMatCode  := '122771';

// Αντικατάσταση κωδικών για GOODY ΛΕΜΟΝΙ-ΤΖΙΝΤΖΕΡ 185ΓΡ ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '124419') then
    SupMatCode  := '124410';

// Αντικατάσταση κωδικών για ΓΕΜΙΣΤΑ ΚΑΚΑΟ ΑΛΛΑΤΙΝΗ 200ΓΡ (-0,25Ε)
  if (SupMatCode = '128849') then
    SupMatCode  := '128840';

// Αντικατάσταση κωδικών για ΓΕΜΙΣΤΑ ΚΑΚΑΟ ΑΛΛΑΤΙΝΗ 200ΓΡ (-0,15E)
  if (SupMatCode = '128859') then
    SupMatCode  := '128850';

// Αντικατάσταση κωδικών για CΗΟCΟ-ΒLΟΟΜ ΑΛΛΑΤΙΝΗ 35ΓΡ
  if (SupMatCode = '129019') then
    SupMatCode  := '129050';

// Αντικατάσταση κωδικών για GOODY ΑΜΥΓΔΑΛΟ 185ΓΡ ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '130319') then
    SupMatCode  := '133310';

// **** Conflict with the previous ^^^
// Αντικατάσταση κωδικών για ΜΠ.ΠΤΙ-ΜΠΕΡ ΑΛΛΑΤΙΝΗ 225ΓΡ
//  if (SupMatCode = '133619') then
//    SupMatCode  := '133630';

// Αντικατάσταση κωδικών για ΜΠ.ΠΤΙ-ΜΠΕΡ ΑΛΛΑΤΙΝΗ 225ΓΡ
  if (SupMatCode = '133638') then
    SupMatCode  := '133630';

// Αντικατάσταση κωδικών για ΜΠ.ΠΤΙ-ΜΠΕΡ ΑΛΛΑΤΙΝΗ 225ΓΡ
  if (SupMatCode = '133639') then
    SupMatCode  := '133630';

// Αντικατάσταση κωδικών για ΠΤΙ-ΜΠΕΡ ΑΛΛΑΤΙΝΗ ΣΟΚΟΛΑΤΑ 225ΓΡ
  if (SupMatCode = '133679') then
    SupMatCode  := '133670';

// Αντικατάσταση κωδικών για ΠΤΙ-ΜΠΕΡ ΑΛΛΑΤΙΝΗ ΧΩΡΙΣ ΖΑΧΑΡΗ 225ΓΡ
  if (SupMatCode = '133689') then
    SupMatCode  := '133680';

// Αντικατάσταση κωδικών για ΠΤΙ-ΜΠΕΡ ΑΛΛΑΤΙΝΗ ΒΟΥΤΥΡΟΥ 195ΓΡ
  if (SupMatCode = '133809') then
    SupMatCode  := '133800';

// Αντικατάσταση κωδικών για CΟΟΚΙΕS BITES ΜΕ ΣΟΚΟΛΑΤΑ 70ΓΡ
  if (SupMatCode = '134859') then
    SupMatCode  := '134850';

// Αντικατάσταση κωδικών για CΟΟΚΙΕS BITES ΜΕ ΓΕΜΙΣΗ ΚΑΚΑΟ 70ΓΡ
  if (SupMatCode = '134869') then
    SupMatCode  := '134860';

// Αντικατάσταση κωδικών για CΟΟΚΙΕS BITES ΜΑΥΡΗ ΣΟΚΟΛΑΤΑ 70ΓΡ ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '134889') then
    SupMatCode  := '134880';

// Αντικατάσταση κωδικών για CΟΟΚΙΕS CΗΟCΟ+CΗΟCΟ CΗΙΡ 175ΓΡ ΑΛΑΤΙΝΗ
  if (SupMatCode = '134919') then
    SupMatCode  := '134910';

// Αντικατάσταση κωδικών για CΟΟΚΙΕS CΗΟCΟLΑΤΕ CΗΙΡ 175ΓΡ ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '135019') then
    SupMatCode  := '135010';

// Αντικατάσταση κωδικών για CΟΟΚΙΕS ΒΡΩΜΗΣ ΣΟΚΟΛΑΤΑ 175ΓΡ ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '137019') then
    SupMatCode  := '137010';

// Αντικατάσταση κωδικών για ΡΑRΤΥ CRΑCΚΕRS 200ΓΡ ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '140939') then
    SupMatCode  := '140910';

// Αντικατάσταση κωδικών για ΑΛΛΑΤΙΝΗ ΣΙΜΙΓΔΑΛΙ ΨΙΛΟ 500ΓΡ
  if (SupMatCode = '142019') then
    SupMatCode  := '142010';

// Αντικατάσταση κωδικών για ΑΛΛΑΤΙΝΗ ΣΙΜΙΓΔΑΛΙ ΧΟΝΔΡΟ 500ΓΡ
  if (SupMatCode = '143019') then
    SupMatCode  := '143010';

// Αντικατάσταση κωδικών για ΝΑΚ 40ΓΡ. ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '143319') then
    SupMatCode  := '143320';

// Αντικατάσταση κωδικών για ΕLΙΤΕ ΦΡΥΓ ΣΙΤΟΥ 125ΓΡ ΔΙΑΦΑΝΗΣ
  if (SupMatCode = '150019') then
    SupMatCode  := '150012';

// Αντικατάσταση κωδικών για ΕLΙΤΕ ΦΡΥΓ ΣΙΤΟΥ 250ΓΡ ΣΕ ΚΟΥΤΙ
  if (SupMatCode = '150029') then
    SupMatCode  := '150020';

// Αντικατάσταση κωδικών για ΕLΙΤΕ ΦΡΥΓ ΣΙΤΟΥ ΣΤΡΟΓΓ 100ΓΡ
  if (SupMatCode = '150519') then
    SupMatCode  := '150510';

// Αντικατάσταση κωδικών για ΕLΙΤΕ ΦΡΥΓ ΣΙΚΑΛΗΣ 180ΓΡ ΔΙΑΦΑΝΗΣ
  if (SupMatCode = '150129') then
    SupMatCode  := '150120';

// Αντικατάσταση κωδικών για ΕLΙΤΕ ΦΡΥΓ ΣΙΤΟΥ 250ΓΡ (-0,10Ε)
  if (SupMatCode = '150419') then
    SupMatCode  := '150410';

// Αντικατάσταση κωδικών για ΒΟΣΙΝΑΚΗ ΦΡΥΓ ΣΙΤΟΥ 375ΓΡ (-0,30Ε)
  if (SupMatCode = '153019') then
    SupMatCode  := '153010';

// Αντικατάσταση κωδικών για ΒΟΣΙΝΑΚΗ ΦΡΥΓ ΣΙΤΟΥ 250ΓΡ
  if (SupMatCode = '153088') then
    SupMatCode  := '153081';

// Αντικατάσταση κωδικών για ΒΟΣΙΝΑΚΗ ΦΡΥΓ ΟΛ.ΑΛΕΣΗΣ 180ΓΡ
  if (SupMatCode = '153327') then
    SupMatCode  := '153322';

// Αντικατάσταση κωδικών για ΒΟΣΙΝΑΚΗ ΦΡΥΓ ΤΡΙΜΜΑ 400ΓΡ
  if (SupMatCode = '153489') then
    SupMatCode  := '153480';

// Αντικατάσταση κωδικών για ΕLΙΤΕ ΦΡΥΓ ΤΡΙΜΜΑ 180ΓΡ
  if (SupMatCode = '155019') then
    SupMatCode  := '155010';

// Αντικατάσταση κωδικών για ELITE ΦΡΥΓ ΤΡΙΜΜΑ 360ΓΡ
  if (SupMatCode = '155039') then
    SupMatCode  := '155030';

// Αντικατάσταση κωδικών για ELITE ΦΡΥΓΑΝΙΕΣ ΜΕ ΚΡΙΘΑΡΙ 250ΓΡ
  if (SupMatCode = '155109') then
    SupMatCode  := '155100';

// Αντικατάσταση κωδικών για ELITE ΦΡΥΓΑΝΙΕΣ ΜΕ ΠΡΟΖΥΜΙ 250ΓΡ
  if (SupMatCode = '155209') then
    SupMatCode  := '155200';

// Αντικατάσταση κωδικών για ELITE ΦΡΥΓΑΝΙΕΣ ΜΕ ΧΑΡΟΥΠΙ 250ΓΡ
  if (SupMatCode = '155309') then
    SupMatCode  := '155300';

// Αντικατάσταση κωδικών για ELITE ΦΡΥΓ ΠΟΛΥΣΠΟΡΕΣ 180ΓΡ
  if (SupMatCode = '155509') then
    SupMatCode  := '155500';

// Αντικατάσταση κωδικών για ΚΡΙΤΣΙΝΙΑ ELITE ΖΥΜΩΜ. ΟΛ.ΑΛΕΣΗΣ 250ΓΡ (-0,20Ε)
  if (SupMatCode = '155928') then
    SupMatCode  := '155927';

// Αντικατάσταση κωδικών για ELITE CRACK.ΝΤΟΜ-ΒΑΣ 105ΓΡ
  if (SupMatCode = '159009') then
    SupMatCode  := '159000';

// Αντικατάσταση κωδικών για ELITE CRACK.ΦΕΤΑ-ΡΙΓ 105ΓΡ
  if (SupMatCode = '159109') then
    SupMatCode  := '159100';

// Αντικατάσταση κωδικών για ELITE CRACK.ΦΥΣ.ΓΕΥΣΗ 105ΓΡ
  if (SupMatCode = '159309') then
    SupMatCode  := '159300';

// Αντικατάσταση κωδικών για ELITE ΦΡΥΓ ΣΙΤΟΥ ΣΤΡΟΓΓ 125ΓΡΧ2 (-0,50Ε)
  if (SupMatCode = '160548') then
    SupMatCode  := '160541';

// Αντικατάσταση κωδικών για ELITE ΦΡΥΓ ΣΙΤΟΥ ΣΤΡΟΓΓ 125ΓΡ
  if (SupMatCode = '161519') then
    SupMatCode  := '161510';

// Αντικατάσταση κωδικών για ELITE CRACK.MINI ΜΕΣΟΓEIAKA ΝΤΟΜ-ΡΙΓ 50ΓΡ
  if (SupMatCode = '163109') then
    SupMatCode  := '163100';

// Αντικατάσταση κωδικών για ELITE CRACK.MINI ΜΕΣΟΓEIAKA PESTO 50ΓΡ
  if (SupMatCode = '163209') then
    SupMatCode  := '163200';

// Αντικατάσταση κωδικών για ELITE CRACK.ΜΕΣ ΣΠΑΝ-ΑΝΗΘΟ 105ΓΡ
  if (SupMatCode = '163959') then
    SupMatCode  := '163950';

// Αντικατάσταση κωδικών για ELITE CRACK.ΜΕΣ ΖΑΧΑΡΗ ΑΧΝΗ & ΚΑΝΕΛΛΑ 105ΓΡ
  if (SupMatCode = '163939') then
    SupMatCode  := '163930';

// Αντικατάσταση κωδικών για ELITE CRACK.ΑΛΕΥΡΙ ΦΑΚΗΣ& ΑΡΧ ΣΠΟΡΟΥΣ 50ΓΡ
  if (SupMatCode = '164139') then
    SupMatCode  := '164130';

// Αντικατάσταση κωδικών για ELITE CRACK.ΑΛΕΥΡΙ ΦΑΚΗΣ& ΕΛΙΕΣ ΚΑΛΑΜ 50ΓΡ
  if (SupMatCode = '164149') then
    SupMatCode  := '164140';

// Αντικατάσταση κωδικών για ELITE BITES ΜΕΣΟΓ ΘΑΛ.ΑΛΑΤΙ 50ΓΡ
  if (SupMatCode = '164309') then
    SupMatCode  := '164300';

// Αντικατάσταση κωδικών για ELITE BITES ΜΕΣΟΓ ΠΑΡΜΕΖΑΝΑ 50ΓΡ
  if (SupMatCode = '164409') then
    SupMatCode  := '164400';

// Αντικατάσταση κωδικών για 2001 ΑΛΜΥΡΑ 40 ΓΡ. ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '173319') then
    SupMatCode  := '173320';

// Αντικατάσταση κωδικών για 2001 ΑΛΜΥΡΑ 40 ΓΡ. ΑΛΛΑΤΙΝΗ
  if (SupMatCode = '173339') then
    SupMatCode  := '173320';

// Αντικατάσταση κωδικών για CΟΟΚΙΕS DΑRΚ ΣΟΚ 175ΓΡΧ2+1 ΣΟΚ (-1Ε)
  if (SupMatCode = '806778') then
    SupMatCode  := '806770';

// Αντικατάσταση κωδικών για ΑΛΛΑΤΙΝΗ ΑΛΕΥΡΙ Γ.Ο.Χ. 1ΚΛ (2+1)
  if (SupMatCode = '811729') then
    SupMatCode  := '811720';

// Αντικατάσταση κωδικών για GOODY ΒΟΥΤΥΡΟΥ 175ΓΡΧ3 (-0,80Ε)
  if (SupMatCode = '824099') then
    SupMatCode  := '824090';

// Αντικατάσταση κωδικών για GOODY ΚΑΝΕΛΛΑ 185ΓΡX3 (-0.80E)
  if (SupMatCode = '824119') then
    SupMatCode  := '824110';

// Αντικατάσταση κωδικών για GOODY ΚΑΝΕΛΛΑ 185ΓΡX3 (-0.70E)
  if (SupMatCode = '824159') then
    SupMatCode  := '824150';

// Αντικατάσταση κωδικών για GOODY ΒΟΥΤΥΡΟΥ 175ΓΡΧ3 (-0,70Ε)
  if (SupMatCode = '824319') then
    SupMatCode  := '824310';

// Αντικατάσταση κωδικών για ΓΕΜΙΣΤΑ ΚΑΚΑΟ ΑΛΛΑΤΙΝΗ 200ΓΡΧ2 (-0,80Ε)
  if (SupMatCode = '828199') then
    SupMatCode  := '828190';

// Αντικατάσταση κωδικών για ΓΕΜΙΣΤΑ ΚΑΚΑΟ ΑΛΛΑΤΙΝΗ 200ΓΡΧ2 (-0,50Ε)
  if (SupMatCode = '828289') then
    SupMatCode  := '828280';

// Αντικατάσταση κωδικών για ΓΕΜΙΣΤΑ ΚΑΚΑΟ ΑΛΛΑΤΙΝΗ 200ΓΡΧ2 (-0,70Ε)
  if (SupMatCode = '828299') then
    SupMatCode  := '828290';

// Αντικατάσταση κωδικών για ΜΠ.ΠΤΙ-ΜΠΕΡ ΑΛΛΑΤΙΝΗ 225ΓΡΧ3 (-0,50Ε)
  if (SupMatCode = '833739') then
    SupMatCode  := '833730';

// Αντικατάσταση κωδικών για ΠΤΙ-ΜΠΕΡ ΑΛΛΑΤΙΝΗ ΣΟΚΟΛΑΤΑ 225ΓΡΧ3 (-0,50)
  if (SupMatCode = '833759') then
    SupMatCode  := '833750';

// Αντικατάσταση κωδικών για ΠΤΙ-ΜΠΕΡ ΑΛΛΑΤΙΝΗ 225ΓΡΧ3 (-0,45Ε)
  if (SupMatCode = '833839') then
    SupMatCode  := '833830';

// Αντικατάσταση κωδικών για ΕLΙΤΕ ΦΡΥΓ ΣΙΤΟΥ 125ΓΡΧ4 (3+1)
  if (SupMatCode = '850029') then
    SupMatCode  := '850020';

// Αντικατάσταση κωδικών για ΕLΙΤΕ ΦΡΥΓ ΣΙΚΑΛΗΣ 90ΓΡΧ4 (3+1)
  if (SupMatCode = '850118') then
    SupMatCode  := '850111';

// Αντικατάσταση κωδικών για ΕLΙΤΕ ΦΡΥΓ ΣΙΤΟΥ ΧΩΡ.ΑΛΑΤΙ 250ΓΡ
  if (SupMatCode = '850179') then
    SupMatCode  := '850170';

// Αντικατάσταση κωδικών για ΕLΙΤΕ ΦΡΥΓ ΣΙΚΑΛΗΣ ΧΩΡ.ΑΛΑΤΙ 180ΓΡ
  if (SupMatCode = '850189') then
    SupMatCode  := '850180';

// Αντικατάσταση κωδικών για ELITE ΦΡΥΓ ΟΛ.ΑΛ.90ΓΡΧ4 (3+1)
  if (SupMatCode = '850289') then
    SupMatCode  := '850280';

// Αντικατάσταση κωδικών για ΕLΙΤΕ ΦΡΥΓ ΣΙΤΟΥ ΧΩΡ.ΑΛΑΤΙ 125ΓΡΧ4 (3+1)
  if (SupMatCode = '850709') then
    SupMatCode  := '850700';

// Αντικατάσταση κωδικών για ΕLΙΤΕ ΦΡΥΓ ΣΙΚΑΛΗΣ ΧΩΡ.ΑΛΑΤΙ 90ΓΡΧ4 (3+1)
  if (SupMatCode = '850809') then
    SupMatCode  := '850800';

// Αντικατάσταση κωδικών για FΟRΜΑ ΦΡΥΓ ΣΙΤΟΥ 125ΓΡΧ4 (3+1)
  if (SupMatCode = '853069') then
    SupMatCode  := '853060';

// Αντικατάσταση κωδικών για FΟRΜΑ ΦΡΥΓ ΣΙΚΑΛΕΩΣ 90ΓΡX4 (-0,50Ε)
  if (SupMatCode = '853158') then
    SupMatCode  := '853151';

// Αντικατάσταση κωδικών για ELITE CRACK.ΝΤΟΜ-ΒΑΣ 105ΓΡ (2+1)
  if (SupMatCode = '859009') then
    SupMatCode  := '859000';

// Αντικατάσταση κωδικών για ELITE CRACK.ΝΤΟΜ-ΒΑΣ 105ΓΡX3 (-1E)
  if (SupMatCode = '859029') then
    SupMatCode  := '859020';

    // Αντικατάσταση κωδικών για ELITE CRACK.ΦΕΤΑ-ΡΙΓ 105ΓΡ (2+1)
  if (SupMatCode = '859109') then
    SupMatCode  := '859100';

// Αντικατάσταση κωδικών για ELITE CRACK.ΦΥΣ.ΓΕΥΣΗ 105ΓΡ (2+1)
  if (SupMatCode = '859309') then
    SupMatCode  := '859300';

// Αντικατάσταση κωδικών για ELITE ΦΡΥΓΑΝΙΕΣ ΣΤΑΡΕΝΙΕΣ 240ΓΡ (-0.30E)
  if (SupMatCode = '870269') then
    SupMatCode  := '870260';

// Αντικατάσταση κωδικών για ELITE ΦΡΥΓΑΝΙΕΣ ΜΕ ΣΟΥΣΑΜΙ 250ΓΡ (-0.30E)
  if (SupMatCode = '870289') then
    SupMatCode  := '870280';

{ Δεν χρειάζονται αυτές οι αντικαταστάσεις πλέον
//**************************************************************
// Οι έλεγχοι γίνονται μόνο για περιπτώσεις 'I03' και  'I04',
// γιατί μόνο στην περίπτωση των πιστωτικών έχουμε αλλαγή κωδικοποίησης.
  if (GetDocType = 'I03') or (GetDocType = 'I04') then
  begin
    if RightString(SupMatCode, 1) = '9' then
      SupMatCode := ReplaceString(SupMatCode, 6, 1, '0')
    else
    if RightString(SupMatCode, 1) = '8' then
      SupMatCode := ReplaceString(SupMatCode, 6, 1, '1');

// Εδώ γίνεται ο έλεγχος αν υπάρχει το αντίστοιχο ΦΚ.
    if GetMatCode(SupMatCode, SupCode, MatCode, MatAA) = False then
    begin
      if RightString(SupMatCode, 1) = '0' then
        SupMatCode := ReplaceString(SupMatCode, 6, 1, '9')
      else
      if RightString(SupMatCode, 1) = '1' then
        SupMatCode := ReplaceString(SupMatCode, 6, 1, '8');

      Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

    end
    else
      Result := True;

  end
  else
    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);
//**************************************************************
}

  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

  if not Result then
{    if SupMatCode = OriginalSupMatCode then
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]))
    else
    if SupMatCode <> OriginalSupMatCode then
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s, or %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode, OriginalSupMatCode]));
  ASupMatCode := SupMatCode;}
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
end;
(*----------------------------------------------------------------------------*)
(* Στην περίπτωση δώρων μου δίνουν τιμή = 0, άρα και το δώρο έχει αξία = 0.
   Εγώ θέλω την πραγματική αξία για να ξέρω τι παροχές παίρνω.                *)
function TElbiscoReader.GetPrice: Double;

  function GetHistoryPrice(MatAA: integer): Double;
  const
    CCS = 'Provider=SQLOLEDB.1;Password=yoda2k;Persist Security Info=True;User ID=sa;Initial Catalog=Afroditi;Data Source=localhost';
  var
    SqlText    : string;
    IniFileName: string;
    Ini        : TIniFile;
    CS         : string;
    Prices     : TDataset;
    APrice     : Double;
    S          : string;
  begin
//    IniFileName := Utls.AppPath + 'Main.ini';
    SetLength(S, 4096);
    SetLength(S, GetModuleFileName(HInstance, PChar(S), Length(S)));
    GetModuleFileName(HInstance, PChar(S), Length(S));
    IniFileName := ExtractFilePath(S) + 'Main.ini';
    Ini         := TIniFile.Create(IniFileName);
    try
      CS        := Ini.ReadString('Main', 'ConnectionString', '');
      if (CS = '') then
      begin
        CS := CCS;
        Ini.WriteString('Main', 'ConnectionString', CS);
      end;
    FCon                  := TADOConnection.Create(nil);
    FCon.Connected        := False;
    FCon.LoginPrompt      := False;
    FCon.ConnectionString := CS;
    FCon.Connected        := True;
    finally
      Ini.Free;
    end;
    SqlText := 'select top 1 d.Date1, l.Price' + LB +
               'from clroot.DocHdPur d with (nolock) join clroot.LItmPurc l with (nolock) on d.AA = l.DocumentAA' + LB +
               'where l.LinkIDNum = ' + IntToStr(MatAA) + LB +
               'and d.SeriesCode in (''ΤΙΜ'', ''ΤΔΑ'')' + LB +
               'and l.Price <> 0.00' + LB +
               'order by d.Date1 desc';
    Prices := Select(SqlText);
    Prices.Open;
    APrice := Prices.FieldByName('Price').AsFloat;
    Result := APrice;
    FreeAndNil(FCon);
    FreeAndNil(Prices);
  end;

var
  S : string;
  C : boolean;
  R : Double;
begin
  // Η παράμετρος '0' είναι η default τιμή, εάν δεν υπάρχει άλλη.
  S := GetStrDef(fiPrice, '0');
//  S := Utls.CommaToDot(S);
//  R := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  S := DotToComma(S);
  R := abs(StrToFloat(S));
  // Αν η τιμή αγοράς είναι 0 πρόκειται για δώρο.
  // Ψάχνουμε στο ιστορικό τιμών για να βρούμε ποια θα έπρεπε να είναι η τιμή.
  // Η σωστή τιμή είναι η πιο πρόσφατη τιμή αγοράς.
  if R = 0 then
  begin
    FManager.Log(Self, 'ΔΩΡΟ !!!');
    C := GetMaterialCode(ASupMatCode, SupCode, MatCode, MatAA);
    R := GetHistoryPrice(MatAA);
    S := FloatToStr(R);
//    S := Utls.CommaToDot(S);
    S := DotToComma(S);
  end;
  // Επιστρέφουμε την πιο πρόσφατη τιμή αγοράς.
//  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  Result := abs(StrToFloat(S));
end;
(*----------------------------------------------------------------------------*)
function TElbiscoReader.GetQty: Double;
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
function TElbiscoReader.GetLineValue: Double;
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
(* Ειδικά για την Elbisco, θα χρησιμοποιήσω και δεύτερο πεδίο ΦΠΑ.
   Εάν υπάρχει μόνο το πρώτο και όχι ΚΑΙ το δεύτερο, τότε ισχύει το πρώτο.
   Εάν υπάρχει ΚΑΙ δεύτερο, ισχύει το δεύτερο.                                *)
(* Για την ELBISCO δεν κάνω τίποτα γιατί μου στέλνει το ΦΠΑ έτοιμο -----------*)
function TElbiscoReader.GetVAT(MatCode: string): string;
 const
   CCS = 'Provider=SQLOLEDB.1;Password=yoda2k;Persist Security Info=True;User ID=sa;Initial Catalog=Afroditi;Data Source=localhost';
 var
  SqlText : string;
  IniFileName: string;
  Ini : TIniFile;
  CS  : string;
  VATCat : TDataset;
  VATVal : Double;
  VAT2   : string;
  TaxCat : string;
  S      : string;
begin
  Result := GetStrDef(fiVAT);
  VAT2 := GetStrDef(fiVAT2);
  if (VAT2 <> '') then
  begin
(* Ειδικά ΠΑΛΙ για την Elbisco, επειδή η κατηγορία ΦΠΑ που μας στέλνει είναι αναξιόπιστη,
   διαβάζω το ΦΠΑ από το ERP !!! *)
    Result := '';
//    FManager.Log(Self, Format('Αντικατάσταση ΦΠΑ !!! SupCode: %s, Date1: %s, RelDoc: %s, MatCode: %s',
//                   [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, MatCode]));

  end;
//  Result := '';
  if (Result = '') or (Result = '0.00') then begin
//    IniFileName := Utls.AppPath + 'Main.ini';
    SetLength(S, 4096);
    SetLength(S, GetModuleFileName(HInstance, PChar(S), Length(S)));
    GetModuleFileName(HInstance, PChar(S), Length(S));
    IniFileName := ExtractFilePath(S) + 'Main.ini';
    Ini := TIniFile.Create(IniFileName);
    try
      CS := Ini.ReadString('Main', 'ConnectionString', '');
      if (CS = '') then
      begin
        CS := CCS;
        Ini.WriteString('Main', 'ConnectionString', CS);
      end;
      FCon := TADOConnection.Create(nil);
      FCon.Connected := False;
      FCon.LoginPrompt := False;
      FCon.ConnectionString := CS;
      FCon.Connected := True;
    finally
      Ini.Free;
    end;
    if GetDocDate < StrToDateTime('01/06/2016 00:00:00') then
      TaxCat := '8'
    else
      TaxCat := '0';
    SqlText := 'Select v.VATVal, m.String11 '                                                        + LB +
               'from clroot.InvVAT v join clroot.Material m with (nolock) on v.VATCtgr = m.VATCtgr'  + LB +
               'where m.Code = ' + qs(MatCode) +  LB +
               'and v.TaxCat = ' + TaxCat;
    VATCat := Select(SqlText);
    VATCat.Open;
    VATVal := VATCat.FieldByName('VATVal').AsFloat;
// If Material is changing VAT and DocDate is from 20/05 onwards, VAT becomes 13% instead of 24%.
    if ((VATCat.FieldByName('String11').AsString = '24->13a') and (DocDate >= 2019-05-20)) then
      VATVal := 13.0;

    Result := FloatToStr(VATVal);
    FreeAndNil(FCon);
    FreeAndNil(VATCat);
  end;
end;
(*----------------------------------------------------------------------------*)
function TElbiscoReader.Select(SqlText: string): TDataset;
var
  Q : TAdoQuery;
begin

  Q := TADOQuery.Create(nil);
  Q.Connection := FCon;
  Q.SQL.Text := SqlText;
  Q.SQL.SaveToFile('C:\Users\user\Documents\Projects\Delphi 101\DocTransform\SQL.txt');
  Q.Active := True;
  Result := Q;
end;
(*----------------------------------------------------------------------------*)
function TElbiscoReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 02072012

  Y := Copy(S, 5, 4);
  M := Copy(S, 3, 2);
  D := Copy(S, 1, 2);
  Result := EncodeDate(
                       StrToInt(Y),
                       StrToInt(M),
                       StrToInt(D)
                       );
end;
(*----------------------------------------------------------------------------*)







initialization
  FileDescriptors.Add(TElbiscoDescriptor.Create);

end.
