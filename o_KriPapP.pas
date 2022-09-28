unit o_KriPapP;

interface

uses
   Windows
  ,SysUtils
  ,Classes
  ,Controls
  ,Forms
  ,Contnrs
  ,Db
  ,StrUtils
  ,Variants
//  ,tpk_Utls
  ,o_Descriptors
  ,o_Managers
  ,o_Purchases
  ,uStringHandlingRoutines
  ;


type
(*----------------------------------------------------------------------------*)
  TKriPapPDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TKriPapPReader = class(TPurchaseReader)
 protected
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function  GetLineValue: Double; override;
   function  DocStrToDate(S: string): TDate; override;

 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;

implementation

{ TKrikriPDescriptor }
(*----------------------------------------------------------------------------*)
constructor TKriPapPDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.KRIPAP-P';
  FFileName        := 'йяипап-п\*.TXT';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  //FMasterMarker    := 'H';
  //FDetailMarker    := 'D';
  FAFM             := '800177888-2';

//  FIsOem           := True;

  FNeedsMapGln     := True;

  FDocTypeMap.Add('тд=тда');
  FDocTypeMap.Add('да=дап');
  FDocTypeMap.Add('пи=пеп');


  FMeasUnitMap.Add('101=тел');
  FMeasUnitMap.Add('тЕЛ=тел');
  FMeasUnitMap.Add('103=йиб');
  FMeasUnitMap.Add('дОВ=тел');
  FMeasUnitMap.Add('йИБ=йиб');


  FGLNMap.Add('10404=1');     //    лаяаскг 18
  FGLNMap.Add('24012=1');     //    лаяаскг 18
  FGLNMap.Add('10405=2');     //    ваияиамым 1
  FGLNMap.Add('25722=2');     //    ваияиамым 1
  FGLNMap.Add('10406=3');     //    пеяийкеоус 46
  FGLNMap.Add('25160=3');     //    пеяийкеоус 46
  FGLNMap.Add('11133=5');     //    25 лаятиоу 113-115
  FGLNMap.Add('25161=5');     //    25 лаятиоу 113-115
  FGLNMap.Add('10408=6');     //    йяылмгс 38
  FGLNMap.Add('25719=6');     //    йяылмгс 38
  FGLNMap.Add('10407=7');     //    йаяайасг 92
  FGLNMap.Add('24013=7');     //    йаяайасг 92
  FGLNMap.Add('10409=8');     //    йгжисиас 12
  FGLNMap.Add('25718=8');     //    йгжисиас 12
  FGLNMap.Add('10410=9');     //    калпяайг 154
  FGLNMap.Add('25720=9');     //    калпяайг 154
  FGLNMap.Add('24014=10');    //    меа пкациа
  FGLNMap.Add('11186=12');    //    ецматиа 6
  FGLNMap.Add('24015=12');    //    ецматиас 6
  FGLNMap.Add('11304=13');    //    бемифекоу 14 хеялг
  FGLNMap.Add('25716=13');    //    бемифекоу 14 хеялг
  FGLNMap.Add('11450=15');    //    мийопокеыс 27 & виоу
  FGLNMap.Add('24016=15');    //    мийопокеыс 27 & виоу
  FGLNMap.Add('11612=16');    //    пкатеиа теяьихеас
  FGLNMap.Add('24017=16');    //    пкатеиа теяьихеас
  FGLNMap.Add('11718=17');    //    ихайгс 43
  FGLNMap.Add('25162=17');    //    ихайгс 43
  FGLNMap.Add('11730=18');    //    пкатымос & иппийяатоус цымиа
  FGLNMap.Add('11865=19');    //    паяасйеуопоукоу 5
  FGLNMap.Add('25721=19');    //    паяасйеуопоукоу 5
  FGLNMap.Add('11899=20');    //    ептакожоу 6
  FGLNMap.Add('25717=20');    //    ептакожоу 6
  FGLNMap.Add('12039=21');    //    л. акенамдяоу 9 пукаиа
  FGLNMap.Add('25163=21');    //    л. акенамдяоу 9 пукаиа
  FGLNMap.Add('12159=22');    //    аицаиоу 80 йакалаяиа
  FGLNMap.Add('25595=22');    //    аицаиоу 80 йакалаяиа
  FGLNMap.Add('12210=23');    //    бихумиас 37 йакалаяиа
  FGLNMap.Add('25863=23');    //    бихумиас 37 йакалаяиа
  FGLNMap.Add('12299=24');    //    помтоу 109 йакалаяиа
  FGLNMap.Add('26033=24');    //    помтоу 109 йакалаяиа
  FGLNMap.Add('12667=25');    //    вакйидийгс 19 хессакомийг
  FGLNMap.Add('27274=25');    //    вакйидийгс 19 хессакомийг
  FGLNMap.Add('12743=26');    //    теяфгс ецматиас 112 пукаиа
  FGLNMap.Add('27331=26');    //    теяфгс ецматиас 112 пукаиа



end;
(*----------------------------------------------------------------------------*)
procedure TKriPapPDescriptor.AddFileItems;
begin
  inherited;

  { master }
  //FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate, 1, 1, 10));
  FItemList.Add(TFileItem.Create(itDocType, 1, 12, 2));
  FItemList.Add(TFileItem.Create(itDocId, 1, 16, 6));
  FItemList.Add(TFileItem.Create(itDocChanger, 1, 12, 10));
  FItemList.Add(TFileItem.Create(itGLN, 1, 23, 5));    // GLN



  // itRelDoc = itDocType + itDocId

  { detail }
  FItemList.Add(TFileItem.Create(itCode, 2, 30, 7));        // ХщКЕИ lookup select
  //FItemList.Add(TFileItem.Create(itBarcode, 2, 209, 14));
  FItemList.Add(TFileItem.Create(itQty, 2, 91, 10));
  FItemList.Add(TFileItem.Create(itPrice, 2, 102, 10));
  //FItemList.Add(TFileItem.Create(itVAT, 2, 318, 5));          // percent
  //FItemList.Add(TFileItem.Create(itDisc, 2, 11));             // disc value
  FItemList.Add(TFileItem.Create(itLineValue, 2, 102, 10));   // дЕМ ЛАР ДъМЕИ СЩМОКО ЦЯАЛЛчР, ЙАИ ТО УПОКОЦъФОУЛЕ.
  FItemList.Add(TFileItem.Create(itMeasUnit, 2, 77, 3));
end;


{ TKrikriPReader }
(*----------------------------------------------------------------------------*)
constructor TKriPapPReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.KRIPAP-P');
end;
(*----------------------------------------------------------------------------*)
function TKriPapPReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

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

  MatCode := '';
  MatAA   := -1;

//  if tblMaterial.Locate('SupMatCode', SupMatCode, []) then
  if Copy(SupMatCode, 1, 2) ='99' then
    SupMatCode := '01' + Copy(SupMatCode, 3, Length(SupMatCode)-2);
  if tblMaterial.Locate('SupMatCode;SupCode', VarArrayOf([SupMatCode, SupCode]), []) then
  begin
    MatCode := tblMaterial.FieldByName('MatCode').AsString;
    MatAA   := tblMaterial.FieldByName('MatAA').AsInteger;

    Result := True;
  end;


// аМТИЙАТэСТАСГ ЙЫДИЙЧМ ВЩЛА ПАЦЫТэ.
  if (SupMatCode = '0109001') or (SupMatCode = '0109002') or (SupMatCode = '0109003')
  or (SupMatCode = '0109004') or (SupMatCode = '0109005') or (SupMatCode = '0109006')
  or (SupMatCode = '0109007') or (SupMatCode = '0109010') or (SupMatCode = '0109011')
  or (SupMatCode = '0109012') or (SupMatCode = '0109040') or (SupMatCode = '0109041')
  or (SupMatCode = '0109042') or (SupMatCode = '0109043') or (SupMatCode = '0109044')
  or (SupMatCode = '0109045') or (SupMatCode = '0109080') or (SupMatCode = '0109081')
  then
    SupMatCode  := '0109000';

  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);


  if not Result then
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                   [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));

end;
(*----------------------------------------------------------------------------*)
function TKriPapPReader.GetLineValue: Double;
var
  S : string;
begin
  S := FloatToStr(GetPrice * GetQty);
//  S := Utls.CommaToDot(S);
//  Result := StrToFloat(S, Utls.GlobalFormatSettings);
  S := DotToComma(S);
  Result := StrToFloat(S);
end;
(*----------------------------------------------------------------------------*)
function TKriPapPReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 12/ 5/11

  Y := Copy(S, 7, 4);
  M := Trim(Copy(S, 4, 2));
  D := Trim(Copy(S, 1, 2));
  Result := EncodeDate(
                       StrToInt(Y),
                       StrToInt(M),
                       StrToInt(D)
                       );
end;







initialization
  FileDescriptors.Add(TKriPapPDescriptor.Create);

end.
