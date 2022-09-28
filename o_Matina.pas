unit o_Matina;

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
  TMatinaDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TMatinaReader = class(TPurchaseReader)
 protected
   FCon : TADOConnection;
   function GetLineValue: Double; override;
   function GetVAT(MatCode: string): string; override;
   function GetMeasUnitAA: Integer; override;
   function DocStrToDate(S: string): TDate; override;

 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;

var ASupMatCode : string;

implementation

{ TMatinaDescriptor }
(*----------------------------------------------------------------------------*)
constructor TMatinaDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.латима'; // Greek
  FFileName        := 'латима\ажяодитг*.txt';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  //FMasterMarker    := 'H';
  //FDetailMarker    := 'D';
  FAFM             := '997543804';
  FNeedsMapGln     := True;

  FNeedsMapPayMode := True;
  FPayModeMap.Add('01=летягта');
  FPayModeMap.Add('06=епи пистысг');

  FDocTypeMap.Add('1=тда');
  FDocTypeMap.Add('2=тил');
  FDocTypeMap.Add('3=дап');
  FDocTypeMap.Add('4=пеп');
  FDocTypeMap.Add('5=пеп');
  FDocTypeMap.Add('12=дап');
  FDocTypeMap.Add('16=дап');
  FDocTypeMap.Add('17=тда');
  FDocTypeMap.Add('18=пей');


//  FMeasUnitMap.Add('PCS=тел');
//  FMeasUnitMap.Add('BOX=йиб');


  FGLNMap.Add('10009=1');     //    лаяаскг 18
  FGLNMap.Add('10006=2');     //    ваияиамым 1
  FGLNMap.Add('10012=3');     //    пеяийкеоус 46
  FGLNMap.Add('10013=5');     //    25 лаятиоу 113-115
  FGLNMap.Add('10011=6');     //    йяылмгс 38 & поукам
  FGLNMap.Add('10008=7');     //    йаяайасг 92
  FGLNMap.Add('10007=8');     //    йгжисиас 12
  FGLNMap.Add('10001=9');     //    калпяайг 154
  FGLNMap.Add('10010=10');    //    меа пкациа
  FGLNMap.Add('10002=12');    //    ецматиа 6
  FGLNMap.Add('10004=13');    //    бемифекоу 14
  FGLNMap.Add('10005=15');    //    мийопокеыс 27 & виоу
  FGLNMap.Add('10015=17');    //    ихайгс 43
  FGLNMap.Add('10016=19');    //    паяасйеуопоукоу 5
  FGLNMap.Add('10018=20');    //    ептакожоу 6
  FGLNMap.Add('10019=21');    //    л. акенамдяоу 9 пукаиа
  FGLNMap.Add('10020=22');    //    аицаиоу 80 йакалаяиа
  FGLNMap.Add('10021=23');    //    бихумиас 37 йакалаяиа
  FGLNMap.Add('10022=24');    //    помтоу 109 йакалаяиа
  FGLNMap.Add('10023=25');    //    вакйидийгс 19 хессакомийг
  FGLNMap.Add('10024=26');    //    теяфгс
  FGLNMap.Add('99999=99');    //    йемтяийо // ецы ебака то 99999 циати дем упгяве


end;
(*----------------------------------------------------------------------------*)
procedure TMatinaDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate       ,1  ,1    ,13));  // OK
  FItemList.Add(TFileItem.Create(itDocType    ,1  ,34   ,5));   // OK
  FItemList.Add(TFileItem.Create(itDocId      ,1  ,19   ,10));
  FItemList.Add(TFileItem.Create(itDocChanger ,1  ,16   ,13));
  FItemList.Add(TFileItem.Create(itGLN        ,1  ,41   ,20));    // GLN
  FItemList.Add(TFileItem.Create(itPayType    ,1  ,96   ,6));   // ой


  { detail }
  FItemList.Add(TFileItem.Create(itCode              ,2  ,146  ,20));
//  FItemList.Add(TFileItem.Create(itBarcode           ,2  ,289  ,14));
  FItemList.Add(TFileItem.Create(itQty               ,2  ,172  ,9));
//  FItemList.Add(TFileItem.Create(itQty               ,2  ,166  ,9));
  FItemList.Add(TFileItem.Create(itPrice             ,2  ,190  ,6));
  FItemList.Add(TFileItem.Create(itVAT               ,2  ,217  ,3));     // Category
//  FItemList.Add(TFileItem.Create(itVAT               ,2  ,203  ,2));     // Category
//  FItemList.Add(TFileItem.Create(itVAT2              ,2  ,232  ,3));
  FItemList.Add(TFileItem.Create(itDisc              ,2  ,225  ,7));     // percent
//  FItemList.Add(TFileItem.Create(itDisc              ,2  ,208  ,7));     // percent
  FItemList.Add(TFileItem.Create(itLineValue         ,2  ,244  ,7));
//  FItemList.Add(TFileItem.Create(itLineValue         ,2  ,215  ,7));
//  FItemList.Add(TFileItem.Create(itMeasUnit          ,2  ,379  ,3));
//  FItemList.Add(TFileItem.Create(itMeasUnitRelation  ,2  ,382  ,10));
end;


{ TMatinaReader }
(*----------------------------------------------------------------------------*)
constructor TMatinaReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.латима'); // Greek
end;
(*----------------------------------------------------------------------------*)
function TMatinaReader.GetLineValue: Double;
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
(* цИА ТГМ латима ДЕМ ЙэМЫ ТъПОТА ЦИАТъ ЛОУ СТщКМЕИ ТО жпа щТОИЛО ------------*)
function TMatinaReader.GetVAT(MatCode: string): string;
var
  tmpVAT: integer;
begin
  Result := 'xx';
  // оИ ЙАТГЦОЯъЕР жпа ТГР лАТъМА ЕъМАИ 7=13 ЙАИ 18=24
  tmpVAT := StrToInt(GetStrDef(fiVAT));
  case tmpVAT of
    7 : Result := '13';
    18: Result := '24';
  end;
end;
(*----------------------------------------------------------------------------*)
function TMatinaReader.GetMeasUnitAA: Integer;
begin
  Result := FManager.GetMaterialMeasureUnitAA(MatAA, 'тел');
end;
(*----------------------------------------------------------------------------*)
function TMatinaReader.DocStrToDate(S: string): TDate;
var ADay, AMonth, AYear : word;
    p : integer;
begin
  // 11/1/2019

  S := StripDate(S);

  // сЕ ЭПОИА ХщСГ ЙАИ МА ЕъМАИ ТО щТОР, ТО ДИАБэФЫ ПэМТА СЫСТэ.
  AYear := StrToInt(RightString(S, 4));
//  ShowMessage(Copy(S, 6, 4));
// аПЭ Тo string АЖАИЯОЩЛЕ ТО ТЕКЕУТАъО ЙОЛЛэТИ ТОУ щТОУР ЛАФъ ЛЕ ТГМ ЙэХЕТО.
// тЧЯА щВЫ ТО 1/9
  S := LeftString(S, Length(S)-5);
  p := pos('/', S);
  ADay := StrToInt(LeftString(S, p-1));
//  ShowMessage(LeftString(S, Length(S)-p));
  AMonth := StrToInt(RightString(S, Length(S)-p));
//  ShowMessage(RightString(S, Length(S)-p));

  Result := EncodeDate(AYear, AMonth, ADay);
end;
(*----------------------------------------------------------------------------*)







initialization
  FileDescriptors.Add(TMatinaDescriptor.Create);

end.
