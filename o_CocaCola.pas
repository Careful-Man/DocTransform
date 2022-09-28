// Θέλω να συγχωνεύσω όλα τα αρχεία σε ένα.
// Θέλω τα παραστατικά να χωρίζονται με μία κενή γραμμή.
// Πληροφορίες που χρειάζομαι :
// TFileKind        - fkFixedLength
// TFileSchema      - fsHeaderDetail
// TSeparationMode  - smEmptyLine

// TInfoType (Data) -
// AFM              - OK
// Date             - OK
// DocType          - OK
// DocId            - OK
// DocChanger       -
// GLN              - OK
// PayType          -
// RelDoc           XXX
// SupCode          - OK
// AlterDoc         -

// Code             - OK
// BarCode          -
// Qty              - OK
// Price            - OK
// VAT              XXX
// Disc             - OK
// Disc2            -
// Disc3            -
// LineValue        - OK
// MeasUnit         - OK
// MeasUnitRelation -


unit o_CocaCola;

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
  ,IniFiles
  ,Variants
  ,StrUtils
//  ,tpk_Utls
  ,uStringHandlingRoutines
  ,o_Descriptors
  ,o_Managers
  ,o_Purchases
//  ,FmxUtils

  ;


type
(*----------------------------------------------------------------------------*)
  TCocaColaDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TCocaColaReader = class(TPurchaseReader)
 protected
//   procedure MergeFiles(FileList : TStringList); override;
   function  DocStrToDate(S: string): TDate; override;
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function  GetLineValue: Double; override;
   function  GetPrice: Double; override;
//   function  GetLineValue: Double; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;

var ASupMatCode : string;

implementation


{ TCocaColaDescriptor }

(*----------------------------------------------------------------------------*)
constructor TCocaColaDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.CocaCola';
  FFileName        := 'Coca_Cola\INVOIC_COCA_COLA.txt';
//  FFileMask        := 'Coca_Cola\INVOIC_GR_AFRODITI_*.txt';
  FFileMask        := 'INVOIC_GR_AFRODITI_*.dat';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smEmptyLine;
  FNeedsFileMerge  := True;
//  FMasterMarker    := 'H';
//  FDetailMarker    := 'D';
  FAFM             := '094277965';
  FIsMultiSupplier := False;

  FNeedsMapGln     := True;

//  FIsOem           := True;
  FIsUniCode       := True;


  FDocTypeMap.Add('F2=ΤΔΑ');
  FDocTypeMap.Add('ZTRR=ΠΕΠ');
  FDocTypeMap.Add('ZROC=ΑΚ');

  FDocTypeMap.Add('ΔΑ-ΤΠ=ΤΔΑ');
  FDocTypeMap.Add('ΠΤ=ΠΕΠ');

  // ΕΠΙ ΠΙΣΤΩΣΗ

  FMeasUnitMap.Add('CS=ΚΙΒ');
  FMeasUnitMap.Add('PC=ΤΕΜ');
  FMeasUnitMap.Add('PCE=ΤΕΜ');
  FMeasUnitMap.Add('EA=ΤΕΜ');
//  FMeasUnitMap.Add('PACK=PACK');
//  FMeasUnitMap.Add('PAL=PALLET');

  FGLNMap.Add('3003006564=1');     // ΜΑΡΑΣΛΗ
  FGLNMap.Add('3003009760=2');     // ΧΑΙΡΙΑΝΩΝ
  FGLNMap.Add('3003010413=3');     // ΠΕΡΙΚΛΕΟΥΣ
  FGLNMap.Add('3003011533=5');     // ΜΑΡΤΙΟΥ
  FGLNMap.Add('3003010699=6');     // ΚΡΩΜΝΗΣ
  FGLNMap.Add('3003010580=7');     // ΚΑΡΑΚΑΣΗ
  FGLNMap.Add('3003010983=8');     // ΚΗΦΙΣΙΑ
  FGLNMap.Add('3003011032=9');     // ΛΑΜΠΡΑΚΗ
  FGLNMap.Add('3000119773=10');    // ΠΛΑΓΙΑ
  FGLNMap.Add('3003011580=12');    // ΕΓΝΑΤΙΑ
  FGLNMap.Add('3003011840=13');    // ΘΕΡΜΗ
  FGLNMap.Add('3003011986=15');    // ΝΙΚΟΠΟΛΗ
  FGLNMap.Add('3000108002=16');    // ΤΕΡΨΙΘΕΑ
  FGLNMap.Add('3000111337=17');    // ΙΘΑΚΗΣ
  FGLNMap.Add('3000119889=19');    // ΠΑΡΑΣΚΕΥΟΠΟΥΛΟΥ
  FGLNMap.Add('3000120095=20');    // ΕΠΤΑΛΟΦΟΥ
  FGLNMap.Add('3000126966=21');    // ΠΥΛΑΙΑ
  FGLNMap.Add('3005009233=22');    // ΑΙΓΑΙΟΥ
  FGLNMap.Add('3005013258=23');    // ΒΙΘΥΝΙΑΣ
  FGLNMap.Add('3005200140=24');    // ΠΟΝΤΟΥ
  FGLNMap.Add('3005238955=25');    // ΧΑΛΚΙΔΙΚΗΣ
  FGLNMap.Add('3005246266=26');    // ΤΕΡΖΗΣ ΠΥΛΑΙΑ
  FGLNMap.Add('3003010168=99');    // ΚΕΝΤΡΙΚΟ
  FGLNMap.Add('3005008839=99');    // ΚΕΝΤΡΙΚΟ

end;
(*----------------------------------------------------------------------------*)
procedure TCocaColaDescriptor.AddFileItems;
begin
  inherited;

  { master }

  FItemList.Add(TFileItem.Create(itDate       ,1    ,17   ,8));
  FItemList.Add(TFileItem.Create(itDocType    ,1    ,1    ,6));
  FItemList.Add(TFileItem.Create(itDocId      ,1    ,10   ,7));
  FItemList.Add(TFileItem.Create(itGLN        ,1    ,29   ,10));    // GLN
  //FItemList.Add(TFileItem.Create(itPayType    ,1    ,0    ,0));



  { detail }
  FItemList.Add(TFileItem.Create(itCode       ,2    ,1    ,15));        // θέλει lookup select
  //FItemList.Add(TFileItem.Create(itBarcode, 2, 13, 14));
  FItemList.Add(TFileItem.Create(itQty        ,2    ,30   ,14));
  FItemList.Add(TFileItem.Create(itPrice      ,2    ,44   ,14));
//  FItemList.Add(TFileItem.Create(itVAT        ,2    ,92   ,2));  // percent
  FItemList.Add(TFileItem.Create(itDisc       ,2    ,58   ,14));   // disc value
  FItemList.Add(TFileItem.Create(itLineValue  ,2    ,72   ,14));   // incl. VAT
  FItemList.Add(TFileItem.Create(itMeasUnit   ,2    ,86   ,14));
end;







{ TCocaColaReader }
(*----------------------------------------------------------------------------*)
constructor TCocaColaReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.CocaCola');
end;
(*----------------------------------------------------------------------------*)
function TCocaColaReader.GetMaterialCode(SupMatCode, SupCode: string;
  out MatCode: string; out MatAA: Integer): Boolean;

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

  // Αντικατάσταση για ΝΕΡΟ ΑΥΡΑ 500ML.
    if (SupMatCode = '1003906') then
      SupMatCode := '1003907';

  // Αντικατάσταση για ΑΜΙΤΑ ΜΟΤΙΟΝ 330ML.
    if (SupMatCode = '1359602') then
      SupMatCode := '1359602';

  // Αντικατάσταση για 500 PET 6X4 COCA COLA GR.
    if (SupMatCode = '2137501') then
      SupMatCode := '1382805';

  // Αντικατάσταση για 500 PET 6X4 COCA COLA GR.
    if (SupMatCode = '425527') then
      SupMatCode := '425505';

  // Αντικατάσταση για 330 CAN 4X6 SPRITE.
    if (SupMatCode = '459106') then
      SupMatCode := '459131';

  // Αντικατάσταση για FUZE TEA LEMON 300MLX4.
    if (SupMatCode = '1747601') then
      SupMatCode := '1747603';

  // Αντικατάσταση για COCA COLA ZERO 4X500ML.
    if (SupMatCode = '1035602') then
      SupMatCode := '1035612';

  // Αντικατάσταση για ??????.
    if (SupMatCode = '425505') then
      SupMatCode := '1035611';

  // Αντικατάσταση για ??????.
    if (SupMatCode = '517482') then
      SupMatCode := '517483';


    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

    if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
end;
(*----------------------------------------------------------------------------*)
(* Είναι προτιμότερο να μπορεί να χρησιμοποιηθεί από οπουδήποτε.              *)
(*----------------------------------------------------------------------------*)
(* Η Coca Cola μου δίνει τη μικτή αξία γραμμής ενώ εγώ θέλω την καθαρή αξία.  *)
(* Ο υπολογισμός είναι : (Μικτή αξία γραμμής - ΦΠΑ) (Μ.Α.  Αποφορολογημένη)   *)
function TCocaColaReader.GetLineValue: Double;

  (* Αυτό το function το χρησιμοποιώ και παρακάτω για τον υπολογισμό της τιμής*)
  function InternalGetLineValue: double;
  var
    S : string;
  begin
    S := GetStrDef(fiLineValue, '0');
//    S := Utls.CommaToDot(S);
//    Result := StrToFloat(S, Utls.GlobalFormatSettings);
//    S := CommaToDot(S);
    S := DotToComma(S);
//    Result := StrToFloat(S, GlobalFormatSettings);
    Result := StrToFloat(S);
  end;

var
  F, T : double;
begin
  T := InternalGetLineValue();
  F := StrToFloat(GetVAT(MatCode));
  (* Αν π.χ. ο ΦΠΑ είναι 23%, θα γίνει διαίρεση δια 1 + 0,23 => 1,23          *)
  T := T / (1+(F/100));
  Result := T;
end;
(*----------------------------------------------------------------------------*)
(* Ο υπολογισμός είναι : (Καθαρή αξία γραμμής + Έκπτωση) / Ποσότητα           *)
function TCocaColaReader.GetPrice: Double;

  function GetHistoryPrice(MatAA: integer): Double;
  const
    // Password=yoda2k
    CCS = 'Provider=SQLOLEDB.1;Password=1;Persist Security Info=True;User ID=sa;Initial Catalog=Afroditi;Data Source=localhost';
  var
    SqlText     : string;
    IniFileName : string;
    Ini         : TIniFile;
    CS          : string;
    S           : string;
    Prices      : TDataset;
    APrice      : Double;
  begin
//    IniFileName := Utls.AppPath + 'Main.ini';
    SetLength(S, 4096);
    SetLength(S, GetModuleFileName(HInstance, PChar(S), Length(S)));
    GetModuleFileName(HInstance, PChar(S), Length(S));
    IniFileName := ExtractFilePath(S) + 'Main.ini';
    Ini  := TIniFile.Create(IniFileName);
    try
      CS := Ini.ReadString('Main', 'ConnectionString', '');
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

  function InternalGetLineValue: double;
  var
    S : string;
  begin
    S := GetStrDef(fiLineValue, '0');
//    S := Utls.CommaToDot(S);
//    Result := StrToFloat(S, Utls.GlobalFormatSettings);
//    S := CommaToDot(S);
    S := DotToComma(S);
//    Result := StrToFloat(S, GlobalFormatSettings);
    Result := StrToFloat(S);
  end;

  function InternalGetPrice: double;
  var
    S : string;
  begin
    S := GetStrDef(fiPrice, '0');
//    S := Utls.CommaToDot(S);
//    Result := StrToFloat(S, Utls.GlobalFormatSettings);
//    S := CommaToDot(S);
    S := DotToComma(S);
//    Result := StrToFloat(S, GlobalFormatSettings);
    Result := StrToFloat(S);
  end;

var
  LineValue, Discount, Quantity, Price : double;
  S : string;
  C : boolean;
  HistoryPrice : Double;
begin
  LineValue := InternalGetLineValue();
  Price     := InternalGetPrice();
  if (LineValue <> 0) or (Price <> 0) then
  begin
    LineValue := GetLineValue();
    Discount  := GetDiscount();
    Quantity  := GetQty();

    Result := (LineValue + Discount) / Quantity;

  end
  // Αν η τιμή αγοράς είναι 0 πρόκειται για δώρο.
  // Ψάχνουμε στο ιστορικό τιμών για να βρούμε ποια θα έπρεπε να είναι η τιμή.
  // Η σωστή τιμή είναι η πιο πρόσφατη τιμή αγοράς.
  else if (LineValue = 0) and (Price = 0) then
  begin
    FManager.Log(Self, 'ΔΩΡΟ !!!');


//    C := GetMaterialCode(ASupMatCode, SupCode, MatCode, MatAA);
(* 'Εχω το MatCode, δεν χρειάζεται να το ξαναψάξω. *)

    HistoryPrice := GetHistoryPrice(MatAA);
    S := FloatToStr(HistoryPrice);
//    S := Utls.CommaToDot(S);
//    S := CommaToDot(S);
    S := DotToComma(S);
    // Επιστρέφουμε την πιο πρόσφατη τιμή αγοράς.
//    Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
//    Result := abs(StrToFloat(S, GlobalFormatSettings));
    Result := abs(StrToFloat(S));
  end
  else if (LineValue <> 0) and (Price = 0) then



    Result := 0;
end;
(*----------------------------------------------------------------------------*)
function TCocaColaReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 20110809

  Y := Copy(S, 1, 4);
  M := Trim(Copy(S, 5, 2));
  D := Trim(Copy(S, 7, 2));
  Result := EncodeDate(
                       StrToInt(Y),
                       StrToInt(M),
                       StrToInt(D)
                       );
end;
(*----------------------------------------------------------------------------*)

initialization
  FileDescriptors.Add(TCocaColaDescriptor.Create);

end.
