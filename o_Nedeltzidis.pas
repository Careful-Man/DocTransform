(*
  пЯЭБКГЛА ЛЕ л.л.
  лъА ПЕЯъПТЫСГ ЕъМАИ МА ЛОУ БэКЕИ ЛъА СТчКГ ЛЭМО ЛЕ ТЕЛэВИА.
  ╒ККГ ПЕЯъПТЫСГ ЕъМАИ МА ПЯОСХщСЫ ЭКЕР ТИР л.л. ПОУ БЯъСЙЫ.

  пЯЭБКГЛА ЛЕ ПОСЭТГТА 1.000,50 ╦ВЕИ ЙАИ ДИАВЫЯИСТИОЙЭ ВИКИэДЫМ ЙАИ УПОДИАСТОКч.
*)

unit o_Nedeltzidis;

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
(*----------------------------------------------------------------------------*)
  TNedeltzidisDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TNedeltzidisReader = class(TPurchaseReader)
 protected
   //function  ResolveGLN: Boolean; override;
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function  GetMeasUnitAA: Integer; override;
   function  DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;





implementation

{ TNedeltzidisDescriptor }

(*----------------------------------------------------------------------------*)
constructor TNedeltzidisDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.Nedeltzidis';
  FFileName        := 'медектфидгс\*123ажяодитг.txt';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '099772640';
  FNeedsMapGln     := False;

//  FNeedsMapGln     := True;

{
  FDocTypeMap.Add('001=тда');
  FDocTypeMap.Add('002=пеп');
  FDocTypeMap.Add('003=пей');
}
  FDocTypeMap.Add('тиф=тда');
  FDocTypeMap.Add('ти0=тда');
  FDocTypeMap.Add('пвф=пеп');
  FDocTypeMap.Add('пв0=пеп');
  FDocTypeMap.Add('пие=пей');

  // епи пистысг

  FMeasUnitMap.Add('тел=тел');
  FMeasUnitMap.Add('TEM=тел');
  FMeasUnitMap.Add('йик=йик');
  FMeasUnitMap.Add('01=йиб');
  FMeasUnitMap.Add('йиб=йиб');
  FMeasUnitMap.Add('KIB=йиб');

{
  FGLNMap.Add('лаяаскг 18-20 & стяылмитсгс 10=1');                    // лаяаскг
  FGLNMap.Add('ваияиамым 1 & вакдиас йакалаяиа=2');                   // ваияиамым
  FGLNMap.Add('пеяийкеоус 46 & татаоукым-буфамтио=3');                // пеяийкеоус
  FGLNMap.Add('лаятиоу 113 - 115  лаятиоу=5');                        // лаятиоу
  FGLNMap.Add('йяылмгс 38 & поукамтфайг йаяалпоуямайи=6');            // йяылмгс
  FGLNMap.Add('йаяайасг 92 йаты тоулпа=7');                           // йаяайасг
  FGLNMap.Add('йгжисиас 12& мактса -  йгжгсиа=8');                    // йгжисиа
  FGLNMap.Add('ця.калпяайг 154 - амы тоулпа=9');                      // калпяайг
  FGLNMap.Add('м.пкациа - вакйидийгс=10');                            // пкациа
  FGLNMap.Add('ецматиас 6 - хессакомийг=12');                         // ецматиа
  FGLNMap.Add('ек.бемифекоу 14 & лайяуциаммг хеялг=13');              // хеялг
  FGLNMap.Add('мийопокеыс 27 & виоу цымиа мийопокг=15');              // мийопокг
  FGLNMap.Add('гяайкеитоу 4  пкатеиа теяьихеас стауяоупокг=16');      // теяьихеа
  FGLNMap.Add('ихайгс 43 еуослос=17');                                // ихайгс
  FGLNMap.Add('паяасйеуопоукоу 5 йакалаяиа=19');                      // паяасйеуопоукоу
  FGLNMap.Add('ептакожоу 6 й.тоулпа=20');                             // ептакожоу
  FGLNMap.Add('лец.акенамдяоу 9 пукаиа=21');                          // пукаиа
  FGLNMap.Add('лец.акенамдяоу 9 пукаиа мео=21');                      // пукаиа
  FGLNMap.Add('л.акенамдяоу 9 пукаиа=21');                            // пукаиа
  FGLNMap.Add('аицаиоу 80 - йакалаяиа=22');                           // аицаиоу
  FGLNMap.Add('аицаиоу 80 йакалаяиа=22');                             // аицаиоу
  FGLNMap.Add('бихумиас 37 йакалаяиа=23');                            // бихумиас
  FGLNMap.Add('помтоу 109 & хгвгс 101 йакалаяиа=24');                 // помтоу
  FGLNMap.Add('помтоу 109 & хгвгс 101=24');                           // помтоу
  FGLNMap.Add('помтоу 101 & хгвгс=24');                               // помтоу
  FGLNMap.Add('йемтяийг апохгйг хеялгс=99');                          // йемтяийо
  FGLNMap.Add('14О ВКЛ.ехм.одоу хес/мийгс-лоудамиым тх 60 267=99');   // йемтяийо
  FGLNMap.Add('14О ВКЛ.еO хес/мийгс-лоудамиым тх 60 267 TK57001=99'); // йемтяийо
}

end;
(*----------------------------------------------------------------------------*)
procedure TNedeltzidisDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate,              1, 81, 8));
//  FItemList.Add(TFileItem.Create(itDocType,           1, 15, 3));
  FItemList.Add(TFileItem.Create(itDocType,           1, 68, 3));
  FItemList.Add(TFileItem.Create(itDocId,             1, 71, 7));
  FItemList.Add(TFileItem.Create(itGLN,               1, 265, 10));    // GLN
//  FItemList.Add(TFileItem.Create(itGLN,               1, 265, 50));    // GLN
  FItemList.Add(TFileItem.Create(itPayType,           1, 0, 0));

  { detail }
  FItemList.Add(TFileItem.Create(itCode,              2, 15, 15));   // ХщКЕИ lookup select
//  FItemList.Add(TFileItem.Create(itBarcode,           2, 0, 0));
  FItemList.Add(TFileItem.Create(itQty,               2, 30, 12));
  FItemList.Add(TFileItem.Create(itPrice,             2, 54, 12));
  FItemList.Add(TFileItem.Create(itVAT,               2, 138, 12));  // percent
  FItemList.Add(TFileItem.Create(itDisc,              2, 78, 12));   // disc value
  FItemList.Add(TFileItem.Create(itDisc2,             2, 90, 12));   // disc2 value
  FItemList.Add(TFileItem.Create(itDisc3,             2, 102, 12));  // disc3 value
  FItemList.Add(TFileItem.Create(itLineValue,         2, 126, 12));  // ╦ВОУМ АЖАИЯЕХЕъ ОИ ЕЙПТЧСЕИР
  FItemList.Add(TFileItem.Create(itMeasUnit,          2, 162, 3));
end;







{ TNedeltzidisReader }
(*----------------------------------------------------------------------------*)
constructor TNedeltzidisReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.Nedeltzidis');
end;
(*----------------------------------------------------------------------------
function TNedeltzidisReader.ResolveGLN: Boolean;
var
  Value: string;
begin
  if (FDescriptor.GLNMap.IndexOfName(GLN) = -1) then
    Result := False
  else begin
    Value  := FDescriptor.GLNMap.Values[GLN];
    Result := TryStrToInt(Value, GlnId);
  end;
end;  *)
(*----------------------------------------------------------------------------*)
function TNedeltzidisReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

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

  { хщКОУЛЕ МА ПЯОБКщЬОУЛЕ ТГМ ПЕЯъПТЫСГ ЕъДОУР суккоцг. }
  if (SupMatCode = '41.023') or (SupMatCode = '53.052') then begin
    MatCode := 'MULTI CODE';
//    FManager.Log(Self, Format('MULTI CODE ERROR:---------SupCode: %10s, Date1: %10s, RelDoc: %5s, %-10s, SupMatCode: %-10s',
//                 [SupCode, Utls.DateToStrSQL(DocDate, False), DocType, RelDoc, SupMatCode]));
    FManager.Log(Self, Format('MULTI CODE ERROR:---------SupCode: %10s, Date1: %10s, RelDoc: %5s, %-10s, SupMatCode: %-10s',
                 [SupCode, DateToStrSQL(DocDate, False), DocType, RelDoc, SupMatCode]));
    Result := True;
  end

  else

  begin

  // аМТИЙАТэСТАСГ ЙЫДИЙЧМ ЦИА боутуяо дыдымг ацекадос 250 ця.
//    if (SupMatCode = '54.062') then
//      SupMatCode := '54.012';

  // аМТИЙАТэСТАСГ ЙЫДИЙЧМ ЦИА йежакоцяабиеяа дыдымг пяобеиа
//    if (SupMatCode = '54.017') then
//      SupMatCode := '54.013';

  // аМТИЙАТэСТАСГ ЙЫДИЙЧМ ЦИА бажг ауцым пяасимг аматокг
    if (SupMatCode = '41.025') then
      SupMatCode := '41.014';

  // аМТИЙАТэСТАСГ ЙЫДИЙЧМ ЦИА бажг ауцым йитяимг аматокг
    if (SupMatCode = '41.026') then
      SupMatCode := '41.015';

  // аМТИЙАТэСТАСГ ЙЫДИЙЧМ ЦИА бажг ауцым лпке аматокг
    if (SupMatCode = '41.027') then
      SupMatCode := '41.016';

  // аМТИЙАТэСТАСГ ЙЫДИЙЧМ ЦИА ТА stand.
    if (SupMatCode = '90.008') or (SupMatCode = '00.075') or (SupMatCode = '00.117')
                               or (SupMatCode = '00.142') or (SupMatCode = '00.191')
                               or (SupMatCode = '00.241') or (SupMatCode = '60.243')
                               or (SupMatCode = '60.535') or (SupMatCode = '60.777') then
      SupMatCode := '00.189';
    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);
    if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
  end;

end;
(*----------------------------------------------------------------------------*)
function TNedeltzidisReader.GetMeasUnitAA: Integer;
var
  S : string;
begin
  S := GetStrDef(fiMeasUnit, '000');

  if (S <> '000') then
  begin
    S      := FDescriptor.MeasUnitMap.Values[S];
    if S = '' then
      S := 'тел';
    Result := FManager.GetMaterialMeasureUnitAA(MatAA, S);
  end else
    Result := -1;

end;
(*----------------------------------------------------------------------------*)
function TNedeltzidisReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 24112011

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
  FileDescriptors.Add(TNedeltzidisDescriptor.Create);

end.
