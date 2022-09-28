unit o_Kore;

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
  TKoreDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TKoreReader = class(TPurchaseReader)
 protected
   FCon : TADOConnection;
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function  DocStrToDate(S: string): TDate; override;
 public
   function Select(SqlText: string): TDataset;
   constructor Create(Manager: TInputManager; Title: string); override;
 end;





implementation

{ TKoreDescriptor }

(*----------------------------------------------------------------------------*)
constructor TKoreDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.KORE';
  FFileName        := 'ΚΟΡΕ\998940924*.txt';
  FKind            := fkFixedLength;
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '998940924';

//  FIsOEM           := True;
  FIsOEM           := False;

  FDocTypeMap.Add('001=ΤΔΑ');
  FDocTypeMap.Add('002=ΠΕΠ');
  FDocTypeMap.Add('003=ΠΕΚ');

  // ΕΠΙ ΠΙΣΤΩΣΗ

  FMeasUnitMap.Add('ΤΜΧ=ΤΕΜ');
  FMeasUnitMap.Add('ΣΕΤ=ΤΕΜ');
  FMeasUnitMap.Add('ΣΕΤ=ΤΕΜ');
  FMeasUnitMap.Add('ΠΑΚ=ΤΕΜ');
  FMeasUnitMap.Add('ΚΙΒ=ΚΙΒ');
  FMeasUnitMap.Add('ΚΙΒ=ΚΙΒ');

end;
(*----------------------------------------------------------------------------*)
procedure TKoreDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate       ,1   ,79   ,8));
  FItemList.Add(TFileItem.Create(itDocType    ,1   ,15   ,3));
  FItemList.Add(TFileItem.Create(itDocId      ,1   ,71   ,8));
  FItemList.Add(TFileItem.Create(itGLN        ,1   ,40   ,9));    // GLN


  { detail }
  FItemList.Add(TFileItem.Create(itCode       ,2   ,15   ,15));   // θέλει lookup select
  FItemList.Add(TFileItem.Create(itQty        ,2   ,30   ,12));
  FItemList.Add(TFileItem.Create(itPrice      ,2   ,54   ,12));
  FItemList.Add(TFileItem.Create(itVAT        ,2   ,138  ,12));   // percent
  FItemList.Add(TFileItem.Create(itDisc       ,2   ,78   ,12));
  FItemList.Add(TFileItem.Create(itDisc2      ,2   ,90   ,12));   // value
  FItemList.Add(TFileItem.Create(itDisc3      ,2   ,102  ,12));
  FItemList.Add(TFileItem.Create(itLineValue  ,2   ,126  ,12));
  FItemList.Add(TFileItem.Create(itMeasUnit   ,2   ,162  ,3));
//  FItemList.Add(TFileItem.Create(itBarCode    ,2   ,217  ,14));
end;





{ TKoreReader }
(*----------------------------------------------------------------------------*)
constructor TKoreReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.KORE');
end;
(*----------------------------------------------------------------------------*)
function TKoreReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
const
  CCS = 'Provider=SQLOLEDB.1;Password=yoda2k;Persist Security Info=True;User ID=sa;Initial Catalog=Afroditi;Data Source=localhost';

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

var
  SqlText : string;
  IniFileName: string;
  Ini : TIniFile;
  CS  : string;
  MatCodes : TDataset;
  BarCode : string;
  S   : string;
begin
  Result := False;

  MatCode := '';
  MatAA   := -1;

  SupMatCode := StripInt(SupMatCode);

  { Θέλουμε να προβλέψουμε την περίπτωση έίδους ΣΥΛΛΟΓΗ. }
  if (SupMatCode = '12232405') or (SupMatCode = '12234520') or (SupMatCode = '21000051')
                               or (SupMatCode = '12263838') or (SupMatCode = '12264012') then begin
    MatCode := 'MULTI CODE';
//    FManager.Log(Self, Format('MULTI CODE ERROR:---------SupCode: %10s, Date1: %10s, RelDoc: %5s, %-10s, SupMatCode: %-10s',
//                 [SupCode, Utls.DateToStrSQL(DocDate, False), DocType, RelDoc, SupMatCode]));
    FManager.Log(Self, Format('MULTI CODE ERROR:---------SupCode: %10s, Date1: %10s, RelDoc: %5s, %-10s, SupMatCode: %-10s',
                 [SupCode, DateToStrSQL(DocDate, False), DocType, RelDoc, SupMatCode]));
    Result := True;
  end

  else

  begin
  // Αντικατάσταση κωδικών για ΚΙΤ-ΚΑΤ SENSES NESTLE 31ΓΡ
    if (SupMatCode = '1500198') then
      SupMatCode := '12090047';

  // Αντικατάσταση κωδικών για KIT KAT  24x45g ΠΡ-10% GR
    if (SupMatCode = '12263312') then
      SupMatCode := '12113945';

  // Αντικατάσταση κωδικών για ΚΙΤ-ΚΑΤ ΝΕSΤLΕ 45ΓΡ
    if (SupMatCode = '12113945') then
      SupMatCode := '12248530';

  // Αντικατάσταση κωδικών για ΞΥΔΙΑ ΜΕΤΕΩΡΑ 400 ΚΟΚΚ. (2+1)
    if (SupMatCode = '03103003') then
      SupMatCode := '03-10-3003';

  // Αντικατάσταση κωδικών για CRUNCH ΜΠΛΕ 10Χ100 γρ PR -10%
    if (SupMatCode = '12263738') then
      SupMatCode := '12154103';

  // Αντικατάσταση κωδικών για CRUNCH ΛΕΥΚH  10Χ100gr.PR -10%
    if (SupMatCode = '12263737') then
      SupMatCode := '12154102';

  // Αντικατάσταση κωδικών για MAGNUM Γκοφρετα 6x(18x55g) PR -10% GR
    if (SupMatCode = '12263311') then
      SupMatCode := '12204877';

  // Αντικατάσταση κωδικών για MAGNUM Γκοφρετα 6x(18x55g) PR -10% GR
    if (SupMatCode = '12167952') then
      SupMatCode := '12202713';

  // Αντικατάσταση κωδικών για NESTLE Tab.Lime 10x100g PR -10%
    if (SupMatCode = '12263750') then
      SupMatCode := '12232950';

  // Αντικατάσταση κωδικών για MAGGI Ζωμός Κότας 20x66g
    if (SupMatCode = '11390476') then
      SupMatCode := '12262246';

  // Αντικατάσταση κωδικών για MAGGI Ζωμός Κότας 20x132g
    if (SupMatCode = '11390477') then
      SupMatCode := '12262247';

  // Αντικατάσταση κωδικών για SMARTIES ΚΑΡΑΜ/ΚΙΑ HEXAGON TUBE 38ΓΡ
    if (SupMatCode = '12263313') then
      SupMatCode := '12243571';

  // Αντικατάσταση κωδικών για τα stand.
    if (SupMatCode = '140002')  or (SupMatCode = '140004')
    or (SupMatCode = '140009')  or (SupMatCode = '093091005009')
    or (SupMatCode = '70000')   or (SupMatCode = '093091008048') then
      SupMatCode := '214007060017';

    if tblMaterial.Locate('SupMatCode;SupCode', VarArrayOf([SupMatCode, SupCode]), []) then
    begin
      MatCode := tblMaterial.FieldByName('MatCode').AsString;
      MatAA   := tblMaterial.FieldByName('MatAA').AsInteger;

      Result := True;
    end;
  end;

// Αν δεν βρούμε τον κωδικό, δοκιμάζουμε τη χρήση του barcode.
  if not Result then
  begin
    BarCode := GetBarCode;
// Αν δεν βρούμε ούτε BarCode τότε έχουμε ανύπαρκτο.
    if BarCode <> '' then
    begin
//      IniFileName := Utls.AppPath + 'Main.ini';
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
      SqlText := 'select IsNull(m.Code, ''XXX'') '                                                        + LB +
                 'from clroot.Material m with (nolock) left join clroot.MatBarCodes b with (nolock) on b.MaterialAA = m.AA'  + LB +
                 'where b.Code = ' + BarCode;
      try
        MatCodes := Select(SqlText);
        MatCodes.Open;
        MatCode := MatCodes.FieldByName('Code').AsString;
        Result := (MatCode <> '');
      except
        FreeAndNil(FCon);
        FreeAndNil(MatCodes);
        Result := False;
      end;
    end;
  end;

  if Result = False then
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                 [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                 [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));

end;
(*----------------------------------------------------------------------------*)
function TKoreReader.Select(SqlText: string): TDataset;
var
  Q : TAdoQuery;
begin

  Q := TADOQuery.Create(nil);
  Q.Connection := FCon;
  Q.SQL.Text := SqlText;
  Q.Active := True;

  Result := Q;
end;
(*----------------------------------------------------------------------------*)
function TKoreReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 02112012

  Y := Copy(S, 5, 4);
  M := Trim(Copy(S, 3, 2));
  D := Trim(Copy(S, 1, 2));
  Result := EncodeDate(
                       StrToInt(Y),
                       StrToInt(M),
                       StrToInt(D)
                       );
end;






initialization
  FileDescriptors.Add(TKoreDescriptor.Create);

end.
