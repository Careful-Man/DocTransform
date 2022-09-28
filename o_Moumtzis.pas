unit o_Moumtzis;

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
  TMoumtzisDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TMoumtzisReader = class(TPurchaseReader)
 protected
   function GetLineMarker(): string; override;
   function GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function GetLineValue: Double; override;
   function GetPayType: string; override;
   function DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;



implementation




{ TMoumtzisDescriptor }
(*----------------------------------------------------------------------------*)
constructor TMoumtzisDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ΜΟΥΜΤΖΗΣ';
  FFileName        := 'ΜΟΥΜΤΖΗΣ\*.txt';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '117887290';

  FNeedsMapPayMode := True;
  FPayModeMap.Add('1=ΜΕΤΡΗΤΑ');
  FPayModeMap.Add('Πίστωση 30 ημερών=ΕΠΙ ΠΙΣΤΩΣΗ');
  FPayModeMap.Add('3=ΕΠΙ ΠΙΣΤΩΣΗ'); // Με αντικαταβολή


  FDocTypeMap.Add('Τιμολόγιο=ΤΙΜ');
  FDocTypeMap.Add('Τιμολόγιο-ΔΑ=ΤΔΑ');
  FDocTypeMap.Add('Πιστωτικό Τιμολόγιο-Δα=ΠΕΠ');
  FDocTypeMap.Add('Πιστωτικό Τιμολόγιο - Έκπτωσης=ΠΕΚ');
  FDocTypeMap.Add('Πιστωτικό Τιμολόγιο=ΠΕΠ');
  FDocTypeMap.Add('Εγγραφο μη τιμολογηθέντων αποθεμάτων (ΔΑ)=ΔΑΠ');



  FMeasUnitMap.Add('Τεμάχια=ΤΕΜ');


  FNeedsMapGln     := True;

  FGLNMap.Add('03=1');
  FGLNMap.Add('12=2');
  FGLNMap.Add('11=3');
  FGLNMap.Add('02=5');
  FGLNMap.Add('19=6');
  FGLNMap.Add('01=7');
  FGLNMap.Add('05=8');
  FGLNMap.Add('13=9');
//  FGLNMap.Add('009=10');
  FGLNMap.Add('06=12');
  FGLNMap.Add('04=13');
  FGLNMap.Add('08=15');
  FGLNMap.Add('09=17');
  FGLNMap.Add('16=19');
  FGLNMap.Add('15=20');
  FGLNMap.Add('17=21');
  FGLNMap.Add('18=22');
  FGLNMap.Add('10=23');
  FGLNMap.Add('07=24'); //14
  FGLNMap.Add('14=24'); //14
  FGLNMap.Add('20=25'); //14
  FGLNMap.Add('21=26'); //14

end;
(*----------------------------------------------------------------------------*)
procedure TMoumtzisDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate        ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,4-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,5-1));
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,6-1));
{
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,4-1));
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,5-1));
}
  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  ,2-1));
  FItemList.Add(TFileItem.Create(itQty          ,2  ,5-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,6-1));
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,7-1));
  FItemList.Add(TFileItem.Create(itDisc         ,2  ,8-1)); // Percent
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,11-1));
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,12-1));

end;





{ TMoumtzisReader }
(*----------------------------------------------------------------------------*)
constructor TMoumtzisReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ΜΟΥΜΤΖΗΣ');
end;
(*----------------------------------------------------------------------------*)
function TMoumtzisReader.GetLineMarker: string;
begin
  Result := DataList[LineIndex][1];
end;

function TMoumtzisReader.GetLineValue: Double;
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
function TMoumtzisReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string;
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
//  SupMatCode := StripInt(SupMatCode);

  begin
  // Αντικατάσταση για ΑΡΤ/ΣΜΑ ΜΠΑΓΚΕΤΑ ΟΛΙΚΗΣ ΑΛΕΣΕΩΣ
    if (SupMatCode = '1-01-0001') then
      SupMatCode := '1-01-0022';

  // Αντικατάσταση για ΑΡΤ/ΣΜΑ ΜΑΡΓΑΡΙΤΑ
    if (SupMatCode = '1-01-0003') then
      SupMatCode := '1-01-0030';

  // Αντικατάσταση για ΑΡΤ/ΣΜΑ ΠΟΛΥΣΠΟΡΟ
    if (SupMatCode = '1-01-0004') then
      SupMatCode := '1-01-0031';

  // Αντικατάσταση για ΑΡΤ/ΣΜΑ ΧΩΡΙΑΤΙΚΟ
    if (SupMatCode = '1-01-0005') then
      SupMatCode := '1-01-0021';

  // Αντικατάσταση για ΑΡΤ/ΣΜΑ ΓΑΛΛΙΚΟ
    if (SupMatCode = '1-01-0006') then
      SupMatCode := '1-01-0023';

  // Αντικατάσταση για ΑΡΤ/ΣΜΑ ΤΣΙΑΠΑΤΑ
    if (SupMatCode = '1-01-0008') then
      SupMatCode := '1-01-0025';

  // Αντικατάσταση για ΑΡΤ/ΣΜΑ ΠΡΟΖΥΜΙ
    if (SupMatCode = '1-01-0009') then
      SupMatCode := '1-01-0026';

  // Αντικατάσταση για ΑΡΤ/ΣΜΑ ΟΛΙΚΗΣ ΑΛΕΣΕΩΣ
    if (SupMatCode = '1-01-0010') then
      SupMatCode := '1-01-0022';

  // Αντικατάσταση για ΑΡΤ/ΣΜΑ ΜΠΑΓΚΕΤΑ
    if (SupMatCode = '1-01-0011') then
      SupMatCode := '1-01-0024';

  // Αντικατάσταση για ΑΡΤ/ΣΜΑ ΓΙΑΝΝΙΩΤΙΚΟ
    if (SupMatCode = '1-01-0014') then
      SupMatCode := '1-01-0028';

  // Αντικατάσταση για ΑΡΤ/ΣΜΑ ΠΑΡΑΔΟΣΙΑΚΟ 500ΓΡ.
    if (SupMatCode = '1-01-0015') then
      SupMatCode := '1-01-0029';

  // Αντικατάσταση για ΑΡΤ/ΣΜΑ ΜΑΡΓΑΡΙΤΑ ΟΛΙΚΗΣ ΑΛ.
    if (SupMatCode = '1-01-0016') then
      SupMatCode := '1-01-0032';

  // Αντικατάσταση για ΕΛΑΙΟΨΩΜΟ
    if (SupMatCode = '1-03-0005') then
      SupMatCode := '1-03-0032';

  // Αντικατάσταση για ΨΩΜΑΚΙ ΣΑΝΤΟΥΙΤΣ 70-80 ΓΡΑΜ.
    if (SupMatCode = '1-03-0020') then
      SupMatCode := '1-03-0031';


    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

    if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
  end;
end;
(*----------------------------------------------------------------------------*)
function TMoumtzisReader.GetPayType: string;
begin
  Result := 'Πίστωση 30 ημερών';
end;
(*----------------------------------------------------------------------------*)
function TMoumtzisReader.DocStrToDate(S: string): TDate;
var ADay, AMonth, AYear : word;
    p : integer;
begin
  S := StripDate(S);

  // 04/01/2016   16/01/2017

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
  FileDescriptors.Add(TMoumtzisDescriptor.Create);

end.
