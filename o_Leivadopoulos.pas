(*----------------------------------------------------------------------------*)
{ мА ТСЕЙэЯЫ ТА ТЯъА ДЕЙАДИЙэ СТГМ ТИЛч ЛОМэДАР.                               }
(*----------------------------------------------------------------------------*)

unit o_Leivadopoulos;

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
  TLeivadopoulosDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TLeivadopoulosReader = class(TPurchaseReader)
 protected
//   procedure LoadFromFile(); override;
//   function  GetDocType(): string; override;
   function  DocStrToDate(S: string): TDate; override;
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;

 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;

implementation

{ TLeivadopoulosDescriptor }
(*----------------------------------------------------------------------------*)
constructor TLeivadopoulosDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.LEIVADOPOULOS';
  FFileName        := 'кеибадопоукос\ажяодитг_*.txt';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  //FMasterMarker    := 'H';
  //FDetailMarker    := 'D';
  FAFM             := '099409328';

//  FIsOem           := True;
//  FIsUniCode       := True;


  FNeedsMapGln     := True;

  FDocTypeMap.Add('тда=тда');
  FDocTypeMap.Add('пти=пеп');

  FPayModeMap.Add('2=епи пистысг');

  FMeasUnitMap.Add('тел=тел');


  FGLNMap.Add('8=1');               //    лаяаскг 18
  FGLNMap.Add('4=2');               //    ваияиамым 1
  FGLNMap.Add('6=3');               //    пеяийкеоус 46
  FGLNMap.Add('210201471-03=3');    //    пеяийкеоус 46
  FGLNMap.Add('210201471-19=3');    //    пеяийкеоус 46
  FGLNMap.Add('210201471-08=5');    //    25 лаятиоу 113-115
  FGLNMap.Add('210201471-16=5');    //    лаятиоу 113-115
  FGLNMap.Add('10=6');              //    йяылмгс 38 & поукам
  FGLNMap.Add('9=7');               //    йаяайасг 92
  FGLNMap.Add('7=8');               //    йгжисиас 12
  FGLNMap.Add('11=9');              //    калпяайг 154
  FGLNMap.Add('210201471-28=10');   //    меа пкациа
  FGLNMap.Add('13=12');             //    ецматиа 6
  FGLNMap.Add('1=13');              //    бемифекоу 14
  FGLNMap.Add('2=13');              //    бемифекоу 14
  FGLNMap.Add('210201471-18=15');   //    мийопокеыс 27 & виоу
  FGLNMap.Add('210201471-20=16');   //    пкатеиа теяьихеас
  FGLNMap.Add('210201471-21=17');   //    ихайгс 43
  FGLNMap.Add('210201471-22=18');   //    пкатымос & иппийяатоус цымиа
  FGLNMap.Add('3=19');              //    паяасйеуопоукоу 5
  FGLNMap.Add('5=20');              //    ептакожоу 6
  FGLNMap.Add('12=21');             //    л. акенамдяоу 9 пукаиа
  FGLNMap.Add('16=22');             //    аицаиоу 80 йакалаяиа
  FGLNMap.Add('18=25');             //    вакйидийгс 19 хессакомийг
  FGLNMap.Add('0000988 - 1=99');    //    14вкл хессакомийгс-лоудамиым

end;
(*----------------------------------------------------------------------------*)
procedure TLeivadopoulosDescriptor.AddFileItems;
begin
  inherited;

  { master }
  //FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate, 1, 201, 10));
  FItemList.Add(TFileItem.Create(itDocType, 1, 1, 50));
  FItemList.Add(TFileItem.Create(itDocId, 1, 157, 44));
  FItemList.Add(TFileItem.Create(itDocChanger, 1, 151, 50));
  FItemList.Add(TFileItem.Create(itGLN, 1, 222, 50));    // GLN
  FItemList.Add(TFileItem.Create(itPayType, 1, 372, 50));



  // itRelDoc = itDocType + itDocId

  { detail }
  FItemList.Add(TFileItem.Create(itCode, 2, 522, 50));        // ХщКЕИ lookup select
  FItemList.Add(TFileItem.Create(itQty, 2, 672, 20));
  FItemList.Add(TFileItem.Create(itPrice, 2, 712, 20));
  FItemList.Add(TFileItem.Create(itVAT, 2, 752, 20));          // percent
  FItemList.Add(TFileItem.Create(itDisc, 2, 732, 20));             // disc value
  FItemList.Add(TFileItem.Create(itLineValue, 2, 792, 20));
  FItemList.Add(TFileItem.Create(itMeasUnit, 2, 692, 20));
//  FItemList.Add(TFileItem.Create(tiMeasUnitRelation, 2, 692, 20));
end;


{ TLeivadopoulosReader }
(*----------------------------------------------------------------------------*)
constructor TLeivadopoulosReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.LEIVADOPOULOS');
end;
(*----------------------------------------------------------------------------*)
(*procedure TLeivadopoulosReader.LoadFromFile;
begin
  inherited;
  DataList.Text := StripStr(DataList.Text);
end;*)
(*----------------------------------------------------------------------------*)
(*function TLeivadopoulosReader.GetDocType: string;
var
  s : string;
begin
  s := GetStrDef(fiDocType);
  Result := StripStr(s);
end;*)
(*----------------------------------------------------------------------------*)
function TLeivadopoulosReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 23/07/2012

  Y := Copy(S, 7, 4);
  M := Trim(Copy(S, 4, 2));
  D := Trim(Copy(S, 1, 2));
  Result := EncodeDate(
                       StrToInt(Y),
                       StrToInt(M),
                       StrToInt(D)
                       );
end;
(*----------------------------------------------------------------------------*)
function TLeivadopoulosReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

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
  if (SupMatCode = '1163') then
    SupMatCode := '1555';
  if (SupMatCode = '1164') then
    SupMatCode := '1556';
// аМТИЙАТэСТАСГ ЦИА ТГ тфиапата лими жоялайи аспяг
  if (SupMatCode = '058') then
    SupMatCode := '1167';
  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);
  if not Result then
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                   [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
end;






initialization
  FileDescriptors.Add(TLeivadopoulosDescriptor.Create);

end.
