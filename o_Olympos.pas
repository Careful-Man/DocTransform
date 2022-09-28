unit o_Olympos;

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
  TOlymposDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TOlymposReader = class(TPurchaseReader)
 protected
   function  DocStrToDate(S: string): TDate; override;
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;

implementation

{ TOlymposDescriptor }
(*----------------------------------------------------------------------------*)
constructor TOlymposDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.OLYMPOS';
  FFileName        := 'окулпос\imp*.txt';
  FKind            := fkFixedLength;
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;

  FIsMultiSupplier := False;
  FAFM             := '094020244';

  FNeedsMapGln     := True;

// мщОИ ТЩПОИ ПАЯАСТАТИЙЧМ АПЭ SAP.
  FDocTypeMap.Add('да=дап');
  FDocTypeMap.Add('тил=тил');
  FDocTypeMap.Add('тда=тда');
  FDocTypeMap.Add('пт=пеп');

// мщЕР ЛОМэДЕР ЛщТЯГСГР АПЭ SAP.
  FMeasUnitMap.Add('KG=тел');
  FMeasUnitMap.Add('ST=тел');


  FGLNMap.Add('210201471-10=1');     //    лаяаскг 18
  FGLNMap.Add('210201471-12=2');     //    ваияиамиым 1
  FGLNMap.Add('210201471-03=3');     //    пеяийкеоус 46
  FGLNMap.Add('210201471-19=3');     //    пеяийкеоус 46
  FGLNMap.Add('210201471-16=5');     //    лаятиоу 113-115
  FGLNMap.Add('210201471-13=6');     //    йяылмгс 38
  FGLNMap.Add('210201471-11=7');     //    йаяайасг 92
  FGLNMap.Add('210201471-14=8');     //    йгжисиа 12
  FGLNMap.Add('210201471-15=9');     //    ця.калпяайг
  FGLNMap.Add('210201471-28=10');    //    меа пкациа
  FGLNMap.Add('210201471-17=12');    //    ецматиас 6
  FGLNMap.Add('210201471-26=13');    //    бемифекоу 14
  FGLNMap.Add('210201471-18=15');    //    мийопокеыс 27 & виоу
  FGLNMap.Add('210201471-21=17');    //    ихайгс 43
  FGLNMap.Add('210201471-23=19');    //    паяасйеуопоукоу 5
  FGLNMap.Add('210201471-24=20');    //    ептакожоу 6
  FGLNMap.Add('210201471-29=21');    //    л. акенамдяоу 9 пукаиа
  FGLNMap.Add('210201471-30=22');    //    аицаиоу 80
  FGLNMap.Add('210201471-31=23');    //    бихумиас 37
  FGLNMap.Add('210201471-32=24');    //    помтоу 109
  FGLNMap.Add('210201471-25=25');    //    вакйид --14вкл хессакомийгс-лоудамиым
  FGLNMap.Add('210201471-34=26');    //    теяфгс - пукаиа
  FGLNMap.Add('210201471-02=99');    //    14О вик. е.о. хес/йгс - лоудамиым


end;
(*----------------------------------------------------------------------------*)
procedure TOlymposDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate        ,1  ,31   ,9));  //*
  FItemList.Add(TFileItem.Create(itDocType     ,1  ,27   ,4));  //*
  FItemList.Add(TFileItem.Create(itDocId       ,1  ,8    ,10)); //*
  FItemList.Add(TFileItem.Create(itDocChanger  ,1  ,1    ,26)); //*
  FItemList.Add(TFileItem.Create(itGLN         ,1  ,460  ,14)); //*


  { detail }
  FItemList.Add(TFileItem.Create(itCode        ,2  ,380  ,16)); //*
  FItemList.Add(TFileItem.Create(itBarcode     ,2  ,229  ,15)); //*
  FItemList.Add(TFileItem.Create(itQty         ,2  ,289  ,12)); //*
  FItemList.Add(TFileItem.Create(itPrice       ,2  ,259  ,15)); //*
  FItemList.Add(TFileItem.Create(itVAT         ,2  ,338  ,6));  //*    // percent
  FItemList.Add(TFileItem.Create(itDisc        ,2  ,365  ,15)); //*    // disc value
  FItemList.Add(TFileItem.Create(itLineValue   ,2  ,244  ,15)); //*    // Qnt * Price
  FItemList.Add(TFileItem.Create(itMeasUnit    ,2  ,301  ,4));  //*

end;


{ TOlymposReader }
(*----------------------------------------------------------------------------*)
constructor TOlymposReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.OLYMPOS');
end;
(*----------------------------------------------------------------------------*)
function TOlymposReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

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

// аМТИЙАТэСТАСГ ЦИА 12-100-050 йатсийисио цака 3,5% 1 lt TGA
  if (SupMatCode = '12-100-050') then
    SupMatCode := '10-810-500';

// аМТИЙАТэСТАСГ ЦИА 12-100-062 цака йатсийисио 3,5% 1 lit TGA
  if (SupMatCode = '12-100-062') then
    SupMatCode := '12-100-062';

// аМТИЙАТэСТАСГ ЦИА 10-810-502 цака йатсийисио 3,5% 1 lit TGA
  if (SupMatCode = '10-810-502') then
    SupMatCode := '10-810-502';

// аМТИЙАТэСТАСГ ЦИА 10-101-008 аяиами нумоцака 1,5% 1 lt PET
  if (SupMatCode = '10-101-008') then
    SupMatCode := '10-101-008';



//*********
// аМТИЙАТэСТАСГ ЦИА 11-104-840 еп.циаоуят.йежия айт-бяы 1.7% окулпос 3x150g 2+1 дыяо
  if (SupMatCode = '11-104-840') then
    SupMatCode := '11-104-898';


// аМТИЙАТэСТАСГ ЦИА 11-104-841 еп.циаоуят.йежия дал-бяы 1.7% окулпос 3x150g 2+1 дыяо
  if (SupMatCode = '11-104-841') then
    SupMatCode := '11-104-897';


// аМТИЙАТэСТАСГ ЦИА 11-104-842 еп.циаоуят.йежия суйо-бяы 1.7% окулпос 3x150g 2+1 дыяо
  if (SupMatCode = '11-104-842') then
    SupMatCode := '11-104-896';

// аМТИЙАТэСТАСГ ЦИА 11-104-842 еп.циаоуят.йежия суйо-бяы 1.7% окулпос 3x150g 2+1 дыяо
  if (SupMatCode = '11-104-843') then
    SupMatCode := '11-104-895';



  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

  if not Result then
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                   [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));

end;
(*----------------------------------------------------------------------------*)
function TOlymposReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 01/11/16

   Result := EncodeDate(StrToInt(Copy(S, 7, 2))+2000,
                       StrToInt(Copy(S, 4, 2)),
                       StrToInt(Copy(S, 1, 2)));

end;





initialization
  FileDescriptors.Add(TOlymposDescriptor.Create);

end.
