unit o_Kontzoglou;

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
(*----------------------------------------------------------------------------
O περιγραφέας θα πρέπει να έχει καταστάσεις
  NoLine
  HeaderLine
  DetailLine
  SkipLine
και ο αναγνώστης να του περνάει κάθε γραμμή και να τον συμβουλεύεται

*)
  TKontzoglouDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
(* Overridden classes come from o_Purchases.pas                               *)
 TKontzoglouReader = class(TPurchaseReader)
 protected
   FCon : TADOConnection;
   ADocDate : TDate;
   function DocStrToDate(S: string): TDate; override;
   function GetDocDate(): TDate; override;
   function GetAFM: string; override;
   function GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function GetPrice: Double; override;
   function GetQty: Double; override;
   function GetMeasUnitAA: Integer; override;
   function GetLineValue: Double; override;
   function GetDiscount: Double; override;
//   function GetSupplierCode(AFM: string; var SupplierCode: string): Boolean; override;
 public
   function Select(SqlText: string): TDataset;
   constructor Create(Manager: TInputManager; Title: string); override;
 end;

var ASupMatCode : string;

implementation

{ TKontzoglouDescriptor }
(*----------------------------------------------------------------------------*)
constructor TKontzoglouDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ΚΟΝΤΖΟΓΛΟΥ';
  FFileName        := 'ΚΟΝΤΖΟΓΛΟΥ\*AFRODITI*.TXT';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '';
  FIsMultiSupplier := True;

//  FIsOEM       := True;
//  FIsUnicode   := True;


//  FNeedsMapPayMode := True;

  FDocTypeMap.Add('ΤΔΑ=ΤΔΑ');
  FDocTypeMap.Add('ΔΑΠ=ΔΑΠ');
  FDocTypeMap.Add('ΠΤΙ=ΠΕΠ');
  FDocTypeMap.Add('ΠΤΕ=ΠΕΠ');

//  FDocTypeMap.Add('ςδΰ=ΤΔΑ');
//  FDocTypeMap.Add('δΰο=ΔΑΠ');
//  FDocTypeMap.Add('οςθ=ΠΕΠ');

  FMeasUnitMap.Add('ΤΕΜ=ΤΕΜ');
  FMeasUnitMap.Add('ΚΙΛ=ΚΙΛ');

end;
(*----------------------------------------------------------------------------*)
procedure TKontzoglouDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate         ,1   ,4));
  FItemList.Add(TFileItem.Create(itDocType      ,1   ,5));
  FItemList.Add(TFileItem.Create(itDocId        ,1   ,6));
  FItemList.Add(TFileItem.Create(itAFM          ,1   ,7));
  FItemList.Add(TFileItem.Create(itGLN          ,1   ,3));    // GLN


  // itRelDoc = itDocType + itDocId

  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2   ,3));
//  FItemList.Add(TFileItem.Create(itBarcode      ,2   ,4));
  FItemList.Add(TFileItem.Create(itQty          ,2   ,5));
  FItemList.Add(TFileItem.Create(itPrice        ,2   ,6));
  FItemList.Add(TFileItem.Create(itVAT          ,2   ,12));  // percent
  FItemList.Add(TFileItem.Create(itDisc         ,2   ,9));   // disc value
  FItemList.Add(TFileItem.Create(itLineValue    ,2   ,10));
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2   ,13));
end;
(*----------------------------------------------------------------------------*)




{ TKontzoglouReader }
(*----------------------------------------------------------------------------*)
function TKontzoglouReader.GetDocDate(): TDate;
begin
  if (FDescriptor.Kind = fkDelimited) then
      Result := DocStrToDate(Trim(ValueList[fiDate.Position]))
  else  // fkFixedLength
      Result := DocStrToDate(Copy(DataList[LineIndex], fiDate.Position, fiDate.Length));
  ADocDate := Result;
end;
(*----------------------------------------------------------------------------*)
function TKontzoglouReader.GetAFM: string;
begin
  if (not FDescriptor.IsMultiSupplier) then
    Result := FDescriptor.AFM
  else
  begin
    Result := GetStrDef(fiAFM);
    if Result = '94485000' then
      Result := '094485000';
  end;
end;
(*----------------------------------------------------------------------------*)
constructor TKontzoglouReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ΚΟΝΤΖΟΓΛΟΥ');
end;
(*----------------------------------------------------------------------------*)
{function TKontzoglouReader.GetSupplierCode(AFM: string; var SupplierCode: string): Boolean;
begin
  SupplierCode := '';

  Result := FManager.tblSupplier.Locate('AFM', AFM, []);

  if not Result then
    //raise Exception.CreateFmt('Supplier code not found. AFM: %s', [AFM])
    FManager.Log(Self, Format('   ERROR: Supplier code not found. AFM: %s - Line: %d', [AFM, LineIndex + 1]))
  else
    SupplierCode := FManager.tblSupplier.FieldByName('PersonId').AsString;
end;}
(*----------------------------------------------------------------------------*)
function TKontzoglouReader.GetMaterialCode(SupMatCode, SupCode: string;
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

  { Θέλουμε να προβλέψουμε την περίπτωση είδους ΣΥΛΛΟΓΗ. }
  if (SupMatCode = '22429') or (SupMatCode = '20216') or
     (SupMatCode = '23152') or (SupMatCode = '23153') then begin
    MatCode := 'MULTI CODE';
//    FManager.Log(Self, Format('MULTI CODE ERROR:---------SupCode: %10s, Date1: %10s, RelDoc: %5s, %-10s, SupMatCode: %-10s',
//                 [SupCode, Utls.DateToStrSQL(DocDate, False), DocType, RelDoc, SupMatCode]));
    FManager.Log(Self, Format('MULTI CODE ERROR:---------SupCode: %10s, Date1: %10s, RelDoc: %5s, %-10s, SupMatCode: %-10s',
                 [SupCode, DateToStrSQL(DocDate, False), DocType, RelDoc, SupMatCode]));
    Result := True;
  end

  else

  begin

  // Αντικατάσταση κωδικών για TWIX
    if (SupMatCode = '21422') then
      SupMatCode := '21239';

  // Αντικατάσταση κωδικών για MARS - SNICKERS
    if (SupMatCode = '22430') then
      SupMatCode := '21216';

  // Αντικατάσταση κωδικών για STAND
    if (SupMatCode = '21587') or (SupMatCode = '22052') then
      SupMatCode := '0789';

  // Αντικαταστάσεις για DANONE
    if (SupMatCode = '40863') then
      SupMatCode := '22868';

    if (SupMatCode = '40726') then
      SupMatCode := '22870';

    if (SupMatCode = '40788') then
      SupMatCode := '22874';

    if (SupMatCode = '40825') then
      SupMatCode := '22876';

    if (SupMatCode = '40849') then
      SupMatCode := '22878';

    if (SupMatCode = '40286') then
      SupMatCode := '22884';

    if (SupMatCode = '40309') then
      SupMatCode := '22887';

    if (SupMatCode = '20060') then
      SupMatCode := '22888';

    if (SupMatCode = '20018') then
      SupMatCode := '22889';

    if (SupMatCode = '20025') then
      SupMatCode := '22890';

    if (SupMatCode = '70514') then
      SupMatCode := '22904';

    if (SupMatCode = '70521') then
      SupMatCode := '22906';

    if (SupMatCode = '22932') then
      SupMatCode := '40641';

    if (SupMatCode = '22933') then
      SupMatCode := '40665';

    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

    if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
  end;

  ASupMatCode := SupMatCode;
end;
(*----------------------------------------------------------------------------*)
(* Εάν ο ΚΟΝΤΖΟΓΛΟΥ μου στέλνει τιμή 0, εγώ ψάχνω την ΤΤΑ και την χρησιμοποιώ.*)
(* Την θέλει η Τζένη για να βλέπει τυχόν δώρα που μας έχουν κάνει.            *)
(* Ελπίζω να μπαίνει αυτόματα και η τελευταία έκπτωση, εάν υπάρχει.           *)
(* Πιθανώς να πρέπει να υπολογίζω και την αξία γραμμής.                       *)
function TKontzoglouReader.GetPrice: Double;

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
    ADay, AMonth, AYear : Word;
    S          : String;
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
    DecodeDate(ADocDate, AYear, AMonth, ADay);
    SqlText := 'select top 1 d.Date1, l.Price, l.DiscVal/(case when l.Quantity = 0 then 1 end) as DiscVal' + LB +
               'from clroot.DocHdPur d with (nolock) join clroot.LItmPurc l with (nolock) on d.AA = l.DocumentAA' + LB +
               'where l.LinkIDNum = ' + IntToStr(MatAA) + LB +
//               'and d.SeriesCode not like ''ΜΠ%''' + LB +
               'and d.SeriesCode in (''ΤΙΜ'', ''ΤΔΑ'')' + LB +
               'and l.Price <> 0.00' + LB +
               'and d.Date1 <= ' + '''' + IntToStr(AYear)+'/'+IntToStr(AMonth)+'/'+IntToStr(ADay) + '''' + LB +
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
  // Υπολογίζω την ΤΤΑ με τον standard τρόπο.
  // Αν η τιμή αγοράς είναι 0 πρέπει να βρω την ιστορική ΤΤΑ.
  // Βρίσκω την τιμή αγοράς και για την Danone.
  if (R = 0) or (SupCode = '0000006526') then
  begin
    C := GetMaterialCode(ASupMatCode, SupCode, MatCode, MatAA);
    R := GetHistoryPrice(MatAA);
    S := FloatToStr(R);
//    S := Utls.CommaToDot(S);
    S := DotToComma(S);
// Logging the change in price
//    if R <> 0 then
//      FManager.Log(Self, 'Τιμή = 0 - Νέα τιμή ΤΤΑ = ' + s + ' !!!');
  end;
  // Επιστρέφουμε την πιο πρόσφατη τιμή αγοράς.
//  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  Result := abs(StrToFloat(S));
end;
(*----------------------------------------------------------------------------*)
function TKontzoglouReader.GetQty: Double;
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
(* Εάν ο ΚΟΝΤΖΟΓΛΟΥ μου στέλνει έκπτωση 0, εγώ ψάχνω την πιο πρόσφατη και την *)
(* χρησιμοποιώ. Πιθανώς να πρέπει να υπολογίζω και την αξία γραμμής.          *)
function TKontzoglouReader.GetDiscount: Double;

  function GetHistoryDiscount(MatAA: integer): Double;
  const
    CCS = 'Provider=SQLOLEDB.1;Password=yoda2k;Persist Security Info=True;User ID=sa;Initial Catalog=Afroditi;Data Source=localhost';
  var
    SqlText    : string;
    IniFileName: string;
    Ini        : TIniFile;
    CS         : string;
    Discounts  : TDataset;
    ADiscount  : Double;
    ADay, AMonth, AYear : Word;
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
    DecodeDate(ADocDate, AYear, AMonth, ADay);
    SqlText := 'select top 1 d.Date1, l.Price, (case when l.Quantity = 0 then 0 else l.DiscVal/l.Quantity end) as DiscVal' + LB +
               'from clroot.DocHdPur d with (nolock) join clroot.LItmPurc l with (nolock) on d.AA = l.DocumentAA' + LB +
               'where l.LinkIDNum = ' + IntToStr(MatAA) + LB +
               'and d.SeriesCode in (''ΤΙΜ'', ''ΤΔΑ'')' + LB +
               'and d.Date1 <= ' + '''' + IntToStr(AYear)+'/'+IntToStr(AMonth)+'/'+IntToStr(ADay) + '''' + LB +
               'order by d.Date1 desc';
    Discounts := Select(SqlText);
    Discounts.Open;
    ADiscount := Discounts.FieldByName('DiscVal').AsFloat;
    Result    := ADiscount;
    FreeAndNil(FCon);
    FreeAndNil(Discounts);
  end;

var
  S : string;
  C : boolean;
  R : Double;
begin
  // Η παράμετρος '0' είναι η default τιμή, εάν δεν υπάρχει άλλη.
  S := GetStrDef(fiDisc, '0');
//  S := Utls.CommaToDot(S);
//  R := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  S := DotToComma(S);
  R := abs(StrToFloat(S));
  // Αν η τιμή αγοράς είναι 0 πρέπει να βρω την ΤΤΑ.
  // Ψάχνουμε στο ιστορικό τιμών για να βρούμε ποια θα έπρεπε να είναι η τιμή.
  // Η σωστή τιμή είναι η πιο πρόσφατη τιμή αγοράς.
  if (R = 0) or (SupCode = '0000006526') then
  begin
    C := GetMaterialCode(ASupMatCode, SupCode, MatCode, MatAA);
    R := GetHistoryDiscount(MatAA);
    S := FloatToStr(R);
//    S := Utls.CommaToDot(S);
    S := DotToComma(S);
// Logging the change in discount
//    if R <> 0 then
//      FManager.Log(Self, 'Έκπτωση = 0 - Νέα Έκπτωση = ' + S + ' !!!');
  end;
  // Επιστρέφουμε την πιο πρόσφατη έκπτωση.
//  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  Result := abs(StrToFloat(S));
end;
(*----------------------------------------------------------------------------*)
function TKontzoglouReader.GetLineValue: Double;
var
  S : string;
//  C : boolean;
  R : Double; // Price
  Q : Double; // Qty
  V : Double; // Value
  p : integer;// negative sign.
begin
// Πρώτα υπολογίζουμε την LineValue με τον standard τρόπο.
// Αν η τιμή είναι 0 τότε πρέπει να κάνουμε custom υπολογισμό.
  S := GetStrDef(fiLineValue, '0');
//  S := Utls.CommaToDot(S);
  S := DotToComma(S);
  p := pos('-', s);
  if p > 0 then
  begin
    s := '-' + TrimLeftZeroes(ReplaceString(s, p, 1, ''));
  end;
//  Result := StrToFloat(S, Utls.GlobalFormatSettings);
  Result := StrToFloat(S);

  if Result = 0 then
  begin
    R := GetPrice;
    Q := GetQty;
    V := (R - GetDiscount) * Q ;

    S := FloatToStr(V);
//    S := Utls.CommaToDot(S);
//    Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
    S := DotToComma(S);
    Result := abs(StrToFloat(S));
  end;
end;
(*----------------------------------------------------------------------------*)
function TKontzoglouReader.Select(SqlText: string): TDataset;
var
  Q : TAdoQuery;
begin

  Q := TADOQuery.Create(nil);
  Q.Connection := FCon;
  try
    Q.SQL.Text := SqlText;
//  q.SQL.SaveToFile('C:\KONTZ.TXT');
    Q.Active := True;
  except
    on EDivByZero do

  end;

  Result := Q;
end;
(*----------------------------------------------------------------------------*)
function TKontzoglouReader.GetMeasUnitAA: Integer;
var
  S  : string;
  FK : AnsiString; // Means AnsiString by default;
begin
  FK := '''103000'''+'''103013'''+'''103016'''+'''103033'''+'''103040'''+
        '''103059'''+'''103142'''+'''103151'''+'''103311'''+'''103258'''+
        '''103341'''+'''103353'''+'''103354'''+'''103375'''+'''103392'''+
        '''103398'''+'''103405'''+'''103422'''+'''103438'''+'''103454'''+
        '''103459'''+'''103460'''+'''103462'''+'''103467'''+'''106020'''+
        '''106048'''+'''106049'''+'''106600'''+'''106606'''+'''106607''';
  S := GetStrDef(fiMeasUnit, '000');

  if (S <> '000') then
  begin
    S      := FDescriptor.MeasUnitMap.Values[S];
    if (S = 'ΤΕΜ') and (Pos(MatCode, FK) > 0) then
      S := 'ΚΙΒ';
    Result := FManager.GetMaterialMeasureUnitAA(MatAA, S);
  end else
    Result := -1;
end;
(*----------------------------------------------------------------------------*)
function TKontzoglouReader.DocStrToDate(S: string): TDate;
begin
  // 2013-06-10
{  Result := EncodeDate(StrToInt(Copy(S, 1, 4)),
                       StrToInt(Copy(S, 6, 2)),
                       StrToInt(Copy(S, 9, 2)));

}
  // 16-06-2013

  Result := EncodeDate(StrToInt(Copy(S, 7, 4)),
                       StrToInt(Copy(S, 4, 2)),
                       StrToInt(Copy(S, 1, 2)));
end;
(*----------------------------------------------------------------------------*)








initialization
  FileDescriptors.Add(TKontzoglouDescriptor.Create);

end.

