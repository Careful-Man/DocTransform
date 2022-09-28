unit o_Papadopoulou;

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
  TPapadopoulouDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TPapadopoulouReader = class(TPurchaseReader)
 protected
   function  GetLineMarker(): string; override;   // yy add override για να αντικαταστήσουμε το raw input
   procedure LoadFromFile(); override;            // yy χρησιμοποιώντας κάποιο function block
//   function  GetDocNo: string; override;
   function  GetDocChanger: string;
   function  GetPayType: string; override;
   function  GetPrice: double; override;
   function  DocStrToDate(S: string): TDate; override;
   function  GetCode: string; override;   // added by yy
   function  GetQty: double; override;      // added by yy
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
(*----------------------------------------------------------------------------*)
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;


implementation


{ TPapadopoulouDescriptor }
(*----------------------------------------------------------------------------*)
constructor TPapadopoulouDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ΠΑΠΑΔΟΠΟΥΛΟΥ';
  FFileName        := 'ΠΑΠΑΔΟΠΟΥΛΟΥ\inv_header*.txt';
//  FFileNameDetail  := 'ΠΑΠΑΔΟΠΟΥΛΟΥ\inv_lines*.txt';
  FKind            := fkFixedLength;
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '094031399';
//  FNeedsMapGln     := True;
//  FIsMultiSupplier := True;

  FNeedsMapPayMode := True;
  FPayModeMap.Add('10=ΜΕΤΡΗΤΑ');
  FPayModeMap.Add('20=ΕΠΙ ΠΙΣΤΩΣΗ');
  FPayModeMap.Add('30=ΕΠΙ ΠΙΣΤΩΣΗ');

  FDocTypeMap.Add('1=ΔΑΠ');
  FDocTypeMap.Add('2=ΤΙΜ');
  FDocTypeMap.Add('3=ΤΔΑ');
  FDocTypeMap.Add('4=ΠΕΠ');
//  FDocTypeMap.Add('6=ΠΕΚ');
  FDocTypeMap.Add('7=ΠΕΠ');   // ΠΕΔ ?
//  FDocTypeMap.Add('11=ΠΕΚ');


  FMeasUnitMap.Add('1=ΤΕΜ');
  //FMeasUnitMap.Add('3=ΚΙΒ');     /yy commented out
  //FMeasUnitMap.Add('7=ΚΙΛ');     /yy commented out
  FMeasUnitMap.Add('3=ΤΕΜ');
  FMeasUnitMap.Add('7=ΤΕΜ');


end;
(*----------------------------------------------------------------------------*)
procedure TPapadopoulouDescriptor.AddFileItems;
begin
  inherited;

  { master }
// Because I am adding a D and a H before the lines, I have to add 1 to every position.
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,2    ,14));  // ΟΚ  (συνδεση header με lines)    
  FItemList.Add(TFileItem.Create(itDate        ,1   ,80   ,8));   // ΟΚ  (ημερομηνια)    
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,55   ,2));   // ΟΚ  (τυπος παραστατικού για προμηθευτη)    
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,60   ,20));  // ΟΚ  (αριθμος εναλλακτικού παραστατικού)    
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,121  ,13));  // ΟΚ  (αποθηκευτικός χώρος, κατάστημα μας)    
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,134  ,10));  // ΟΚ  (τροπος πληρωμής)


  { detail }
// Because I am adding a D and a H before the lines, I have to add 1 to every position.
  FItemList.Add(TFileItem.Create(itCode             ,2  ,29    ,6));  // ΟΚ *προσοχή στη διαφορά ψηφίων στο Code!*
  FItemList.Add(TFileItem.Create(itQty              ,2  ,140   ,10)); // ΟΚ (ποσότητα είτε σε τεμ, είτε σε κιβ)
  FItemList.Add(TFileItem.Create(itPrice            ,2  ,169   ,6));  // ΟΚ (τιμή τεμαχίου, όχι κιβ)
  FItemList.Add(TFileItem.Create(itVAT              ,2  ,390   ,2));  // ΟΚ (ΦΠΑ)
  FItemList.Add(TFileItem.Create(itDisc             ,2  ,202   ,15)); // ΟΚ (αξιακή έκπτωση, συνολικά στη γραμμή)
  FItemList.Add(TFileItem.Create(itLineValue        ,2  ,359   ,15)); // ΟΚ (συνολική καθαρή αξία της γραμμής)
  FItemList.Add(TFileItem.Create(itMeasUnit         ,2  ,150   ,1));  // ΟΚ (μονάδα μέτρησης: κιβ ή τεμ)
  FItemList.Add(TFileItem.Create(itMeasUnitRelation ,2  ,151   ,8));  // ΟΚ (πολλαπλασιαστής ποσότητας, ανάλογα την μ.μ.)


end;



{ TElgekaReader }
(*----------------------------------------------------------------------------*)
constructor TPapadopoulouReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ΠΑΠΑΔΟΠΟΥΛΟΥ');
end;
(*----------------------------------------------------------------------------*)
//function TPapadopoulouReader.GetDocNo: string;
//begin
//  Result := GetStrDef(fiDocId);
//end;
(*----------------------------------------------------------------------------*)
function TPapadopoulouReader.GetDocChanger: string;
begin
  Result := GetStrDef(fiDocChanger);
  Result := GetStrDef(fiDocType);
  Result := GetStrDef(fiDocID);
end;
(*----------------------------------------------------------------------------*)
function TPapadopoulouReader.GetPayType: string;
begin
  if (FDescriptor.NeedsMapPayMode) then
  begin
    Result := GetStrDef(fiPayType);
    if Result = '' then
      Result := '20';
    if (FDescriptor.PayModeMap.IndexOfName(Result) = -1) then
      raise Exception.CreateFmt('Invalid PayType. Map not found: %s', [Result]);

    Result :=  FDescriptor.PayModeMap.Values[Result];
  end else begin
    Result :=  'ΕΠΙ ΠΙΣΤΩΣΗ';
  end;
end;
(*----------------------------------------------------------------------------*)
function TPapadopoulouReader.GetPrice: double;
var
  S : string;

begin
  S := GetStrDef(fiPrice, '0');
  S := DotToComma(S);
  Result := StrToFloat(S)

end;
(*----------------------------------------------------------------------------*)
function TPapadopoulouReader.GetLineMarker: string;
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
(* Διαβάζω από μία γραμμή του Master το DocChanger.
   Ψάχνω το DocChanger μέσα στο Detail και κάθε γραμμή που βρίσκω την προσθέτω
   στο ίδιο αρχείο. Ουσιαστικά κάνω επαναδημιουργία του αρχείου όπως θα έπρεπε
   να είναι εξ' αρχής.

   //y  *** SOS! Υπάρχει hard-coded o delimiter στο παρακάτω block.
   //y  *** Θα πρέπει να τον αντικαταστήσω εάν είναι διαφορετικός.

*)
procedure TPapadopoulouReader.LoadFromFile;
var
  DataListMaster : TStringList;
  DataListDetail : TStringList;
  DocChanger     : string;
  ALine          : string;
  i, j, p        : integer;
  JustName       : string;
  JustExtension  : string;

  function DocExists(ALine: string): Boolean;
  var
    i: integer;
    NewDocChanger: string;
    OldDocChanger: string;
  begin
    Result := False;
// Προσθέτω το 'H' γιατί θέλω να συγκρίνω μόνο τα Headers και όχι και τα Lines.
    NewDocChanger := 'H' + LeftString(ALine, 14);
    for i := 0 to DataList.Count - 1 do
    begin
      OldDocChanger := LeftString(DataList[i], 14);
      if NewDocChanger = OldDocChanger then begin
        Result := True;
        Exit;
      end;
    end;
  end;

begin
  JustName := ExtractFileName(FFileName);
  JustExtension := ExtractFileExt(JustName);
  p := pos('.', JustName);
  // Έχουμε πάρει μόνο το όνομα χωρίς την προέκταση.
  JustName := LeftString(JustName, p-1);
  JustName := RightString(JustName, Length(JustName) - Length('inv_header'));
  FFileNameDetail := FInputPath + 'inv_lines' + JustName + JustExtension;

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
      DocChanger := LeftString(ALine, 14);
      for j := 0 to DataListDetail.Count - 1 do
        begin
        ALine := DataListDetail.Strings[j];
        if LeftString(ALine, 14) = DocChanger then
          DataList.Add('D' + ALine);
      end;
    end;

  end;

  FTotal := DataList.Count;

  FreeAndNil(DataListMaster);
  FreeAndNil(DataListDetail);
end;
(*----------------------------------------------------------------------------*)
function TPapadopoulouReader.DocStrToDate(S: string): TDate;

begin

  Result := EncodeDate(StrToInt(Copy(S, 1, 4)),
                       StrToInt(Copy(S, 5, 2)),
                       StrToInt(Copy(S, 7, 2)));
end;

(*----------------------------------------------------------------------------*)
// FOLLOWING BLOCK ADDED BY ME //YY
(*----------------------------------------------------------------------------*)
function  TPapadopoulouReader.GetCode: string;
(*
Ο παπαδοπουλος δεν έχει σταθερή στοίχιση στο 5ψήφιο code του είδους,
τα κιβ εχουν +1 ψηφίο από τα τεμ (βλ lines column 34), χαλώντας τη στοίχιση.
Το ζητούμενο είναι να κρατήσω τα δεξιά 5 ψηφία σε κάθε περίπτωση.
*)
begin
  Result := GetStrDef(fiCode);
    
  if Length(Result) = 5 then //Result := Result     
  else Result := Copy(Result, 2, 5);               

end;

(*----------------------------------------------------------------------------*)
// FOLLOWING BLOCK ADDED BY ME //YY
(*----------------------------------------------------------------------------*)

function TPapadopoulouReader.GetQty: Double;

var
  S: String;
  D: String;

begin
    S := GetStrDef(fiQty, '0');
    D := GetStrDef(fiMeasUnitRelation, '0');
    S := DotToComma(S);
    D := DotToComma(D);
     
    Result := StrToFloat(S) * StrToFloat(D);
end;

(*----------------------------------------------------------------------------*)
// FOLLOWING BLOCK ADDED BY ME //YY
(*----------------------------------------------------------------------------*)

function TPapadopoulouReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string;
  out MatAA: Integer): Boolean;

  function GetMatCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
  begin
    Result := False;

    MatCode := '';
    MatAA   := -1;

    if tblMaterial.Locate('SupMatCode;SupCode', VarArrayOf([SupMatCode, SupCode]), []) then
    begin
      MatCode := tblMaterial.FieldByName('MatCode').AsString;
      MatAA   := tblMaterial.FieldByName('MatAA').AsInteger;

      Result := True;
    end;

  end;

begin
  Result := False;

    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

    if not Result then
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
end;

(*----------------------------------------------------------------------------*)

initialization
  FileDescriptors.Add(TPapadopoulouDescriptor.Create);

end.

