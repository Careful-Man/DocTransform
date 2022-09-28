unit o_KrikriP;

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

  ,uStringHandlingRoutines
//  ,tpk_Utls
  ,o_Descriptors
  ,o_Managers
  ,o_Purchases
  ;


type
(*----------------------------------------------------------------------------*)
  TKriKriPDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TKriKriPReader = class(TPurchaseReader)
 protected
   function GetDocType: string; override;
   function GetDocNo:   string; override;
   function GetPrice: Double; override;
   function GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function DocStrToDate(S: string): TDate; override;

 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;

implementation

{ TKrikriDescriptor }
(*----------------------------------------------------------------------------*)
constructor TKriKriPDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.KRIKRIP';
  FFileName        := 'йяийяи-п\*.csv';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  FAFM             := '094289571-2';

  FNeedsMapGln     := True;

  FDocTypeMap.Add('TP=тил');
  FDocTypeMap.Add('TP=тил');
  FDocTypeMap.Add('да=дап');
  FDocTypeMap.Add('PT=пеп');
  FDocTypeMap.Add('PT=пеп');


  FMeasUnitMap.Add('те=тел');
  FMeasUnitMap.Add('PC=тел');


  FGLNMap.Add('9005025=1');     //    лаяаскг 18
  FGLNMap.Add('9005026=2');     //    ваияиамым 1
  FGLNMap.Add('9005027=3');     //    пеяийкеоус 46
  FGLNMap.Add('9005032=5');     //    25 лаятиоу 113-115
  FGLNMap.Add('9005029=6');     //    йяылмгс 38
  FGLNMap.Add('9005028=7');     //    йаяайасг 92
  FGLNMap.Add('9005030=8');     //    йгжисиас 12
  FGLNMap.Add('9005031=9');     //    калпяайг 154
  FGLNMap.Add('24014=10');      //    меа пкациа
  FGLNMap.Add('9005308=10');    //    меа пкациа
  FGLNMap.Add('9005033=12');    //    ецматиа 6
  FGLNMap.Add('9005034=13');    //    бемифекоу 14 хеялг
  FGLNMap.Add('9005035=15');    //    мийопокеыс 27 & виоу
  FGLNMap.Add('9005036=17');    //    ихайгс 43
  FGLNMap.Add('9005037=19');    //    паяасйеуопоукоу 5
  FGLNMap.Add('9005038=20');    //    ептакожоу 6
  FGLNMap.Add('9005039=21');    //    л. акенамдяоу 9 пукаиа
  FGLNMap.Add('9005040=22');    //    аицаиоу 80 йакалаяиа
  FGLNMap.Add('9005041=23');    //    бихумиас 37 йакалаяиа
  FGLNMap.Add('9005042=24');    //    помтоу 109 йакалаяиа
  FGLNMap.Add('9005489=25');    //    вакйидийгс 19 хессакомийг
  FGLNMap.Add('9005601=26');    //    теяфгс пукаиа


  FGLNMap.Add('0150059=99');    //    йемтяийо
  FGLNMap.Add('150059=99');    //     йемтяийо



end;
(*----------------------------------------------------------------------------*)
procedure TKriKriPDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate        ,1   ,5-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,9-1)); // override
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,9-1)); // override
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,9-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,2-1));

  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  ,17-1));
  FItemList.Add(TFileItem.Create(itQty          ,2  ,20-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,21-1)); // override
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,26-1));
  FItemList.Add(TFileItem.Create(itDisc         ,2  ,24-1)); // Value
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,25-1));
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,19-1));

end;


{ TKrikriReader }
(*----------------------------------------------------------------------------*)
constructor TKriKriPReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.KRIKRIP');
end;
(*----------------------------------------------------------------------------*)
(* оИ ДЩО ПЯЧТОИ ВАЯАЙТчЯЕР АПЭ ТО ПЕДъО 9-1.                                 *)
function TKriKriPReader.GetDocType: string;
var
  s: string;
begin
  s := GetStrDef(fiDocType);
  Result := LeftString(s, 2);
end;
(*----------------------------------------------------------------------------*)
function TKriKriPReader.GetDocNo: string;
var
  s: string;
begin
  s := GetStrDef(fiDocId);
  Result := TrimLeftZeroes(RightString(s, 7));
end;
(*----------------------------------------------------------------------------*)
function TKriKriPReader.GetPrice: Double;
var
  s: string;
begin
  // г ПАЯэЛЕТЯОР '0' ЕъМАИ Г default ТИЛч, ЕэМ ДЕМ УПэЯВЕИ эККГ.
  s := GetStrDef(fiPrice, '0');

//  s := StripRealToStr(Utls.CommaToDot(s));
  s := StripRealToStr(DotToComma(s));
  Result := StrToFloat(s);
end;
(*----------------------------------------------------------------------------*)
function TKriKriPReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

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
  if LeftString(SupMatCode, 1) = '2' then // аПЭ 2 АЯВъФОУМ ОИ ЙЫДИЙОъ цАКАЙТОЙОЛИЙЧМ ЙАИ ДЕМ ТА ХщКЫ.
  begin
    MatCode := 'Will not be inserted';
    Result := False;
//    FManager.Log(Self, Format('XXXXXXXXXXXXXXXXXXXX  Will not be inserted  XXXXXXXXXXXXXXXXXXXX',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]))
    FManager.Log(Self, Format('XXXXXXXXXXXXXXXXXXXX  Will not be inserted  XXXXXXXXXXXXXXXXXXXX',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]))
  end
  else
  begin
    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);
    if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
  end;
end;
(*----------------------------------------------------------------------------*)
function TKriKriPReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 21/07/2012

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
  FileDescriptors.Add(TKriKriPDescriptor.Create);

end.
