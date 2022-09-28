unit o_Lykas;

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
  TLykasDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TLykasReader = class(TPurchaseReader)
 protected
// о кЩЙАР щВЕИ ЕИСАЦЫЦИЙэ ЦЩЯЫ АПЭ ЙэХЕ data. пЯщПЕИ МА ТА СБчМЫ.
//   function  GetDocType: string; override;
   function GetStrDef(FileItem: TFileItem; Default: string = ''): string; override;

   function GetQty: Double; override;
   function GetLineValue: Double; override;

   function DocStrToDate(S: string): TDate; override;

 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;

implementation

{ TKrikriDescriptor }
(*----------------------------------------------------------------------------*)
constructor TLykasDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.куйас';
  FFileName        := 'куйас\AFROD.csv';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  FAFM             := '081840386';

//  FIsOem           := True;

  FNeedsMapGln     := True;

  FNeedsMapPayMode := True;
  FPayModeMap.Add('1=XXX');
  FPayModeMap.Add('7=епи пистысг');
  FPayModeMap.Add('3=XXX');

  FDocTypeMap.Add('41=дап');
  FDocTypeMap.Add('61=тил');
  FDocTypeMap.Add('62=тда');
  FDocTypeMap.Add('67=пеп');


  FMeasUnitMap.Add('2=тел');
  FMeasUnitMap.Add('3=йик');


  FGLNMap.Add('06.112=1');     //    лаяаскг 18
  FGLNMap.Add('06.113=2');     //    ваияиамым 1
  FGLNMap.Add('06.114=3');     //    пеяийкеоус 46
  FGLNMap.Add('06.120=5');     //    25 лаятиоу 113-115
  FGLNMap.Add('06.116=6');     //    йяылмгс 38
  FGLNMap.Add('06.115=7');     //    йаяайасг 92
  FGLNMap.Add('06.117=8');     //    йгжисиа 12
  FGLNMap.Add('06.118=9');     //    калпяайг 154
  FGLNMap.Add('06.119=10');     //    м. пкациа
  FGLNMap.Add('06.121=12');    //    ецматиас 6
  FGLNMap.Add('06.122=13');    //    бемифекоу 14 хеялг
  FGLNMap.Add('06.123=15');    //    мийопокеыс 27 & виоу
  FGLNMap.Add('06.124=17');    //    ихайгс 43
  FGLNMap.Add('06.125=19');    //    паяасйеуопоукоу 5
  FGLNMap.Add('06.126=20');    //    ептакожоу 6
  FGLNMap.Add('06.127=21');    //    л. акенамдяоу 9 пукаиа
  FGLNMap.Add('06.088=22');    //    аицаиоу 80 йакалаяиа
  FGLNMap.Add('06.316=23');    //    бихумиас 37 йакалаяиа
  FGLNMap.Add('06.949=24');    //    помтоу 109 йакалаяиа
  FGLNMap.Add('08.032=25');    //    вакйидийгс 19 хессакомийг
  FGLNMap.Add('08.186=26');    //    теяфгс пукаиа
  FGLNMap.Add('07.029=99');    //    йемтяийо



end;
(*----------------------------------------------------------------------------*)
procedure TLykasDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,5-1));
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,5-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,6-1));
  FItemList.Add(TFileItem.Create(itPayType     ,1   ,8-1));


  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  ,9-1));
  FItemList.Add(TFileItem.Create(itQty          ,2  ,12-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,13-1));
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,15-1));
  FItemList.Add(TFileItem.Create(itDisc         ,2  ,14-1)); // Percent
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,19-1));
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,20-1));

end;


{ TKrikriReader }
(*----------------------------------------------------------------------------*)
constructor TLykasReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.куйас');
end;
(*----------------------------------------------------------------------------*)
function TLykasReader.GetQty: Double;
var
  S : string;
//  tmpResult : Double;
begin
  S := GetStrDef(fiQty, '0');
//  S := Utls.CommaToDot(S);
//  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  S := DotToComma(S);
  Result := abs(StrToFloat(S));
// аУТЭ ВЯЕИэФЕТАИ ЦИА ТГМ ПЕЯъПТЫСГ тил ВЫЯъР ПОСЭТГТА.
// аМТъСТОИВА ПЯщПЕИ МА ЦъМЕИ ЦИА ТА дап ПОУ ДЕМ щВОУМ АНъА.
//  tmpResult := abs(StrToFloat(S));
//  if tmpResult = 0.0 then
//  begin
//
//  end;
end;
(*----------------------------------------------------------------------------*)
function TLykasReader.GetLineValue: Double;
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
function TLykasReader.GetStrDef(FileItem: TFileItem; Default: string): string;
begin
  Result := Default;

  if (FileItem <> nil) then
  begin
    if (FDescriptor.Kind = fkDelimited) then
      Result := AnsiDequotedStr(Trim(ValueList[FileItem.Position]), '"')
    else  // fkFixedLength
      Result := AnsiDequotedStr(Trim(Copy(DataList[LineIndex], FileItem.Position, FileItem.Length)), '"');

    if (Result = '') then
      Result := Default;
  end;
end;
(*----------------------------------------------------------------------------*)
(*function TLykasReader.GetDocType: string;
begin

end;*)
(*----------------------------------------------------------------------------*)
function TLykasReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 21/07/2012
  S := AnsiDequotedStr(S, '"');

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
  FileDescriptors.Add(TLykasDescriptor.Create);

end.
