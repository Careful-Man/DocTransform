unit o_CretaNew;

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
  TCretaNewDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TCretaNewReader = class(TPurchaseReader)
 protected
   function  GetCode: string; override;
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function  GetQty: Double; override;
   function  DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;




implementation


{ TCretaFarmDescriptor }

(*----------------------------------------------------------------------------*)
constructor TCretaNewDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.CRETANEW';
  FFileName        := 'CRETA (NEW)\afroditi*.txt';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '801280552';

//  FIsOem           := True;


  FDocTypeMap.Add('ƒ¡-‘–=‘ƒ¡');
  FDocTypeMap.Add('‘–=‘…Ã');
  FDocTypeMap.Add('‘–¡=‘…Ã');
  FDocTypeMap.Add('ƒ¡=ƒ¡–');
  FDocTypeMap.Add('–‘=–≈ƒ');
  FDocTypeMap.Add('–‘¡=–≈–');
  FDocTypeMap.Add('–‘≈–=–≈–');
  FDocTypeMap.Add('–‘‘∆=–≈ ');

  // ≈–… –…”‘Ÿ”«

  FMeasUnitMap.Add('ST=‘≈Ã');
  FMeasUnitMap.Add('KG= …À');

end;
(*----------------------------------------------------------------------------*)
procedure TCretaNewDescriptor.AddFileItems;
begin
  inherited;

  { master }

  FItemList.Add(TFileItem.Create(itDate         ,1  ,33   ,10));
  FItemList.Add(TFileItem.Create(itDocType      ,1  ,235  ,6));   // ‘˝ÔÚ ·Ò/ÍÔ˝  ¬” !!!
//  FItemList.Add(TFileItem.Create(itDocId        ,1  ,18   ,9));
  FItemList.Add(TFileItem.Create(itDocId        ,1  ,244  ,9));
  FItemList.Add(TFileItem.Create(itGLN          ,1  ,126  ,14));  // GLN



  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  ,66   ,18));
  FItemList.Add(TFileItem.Create(itQty          ,2  ,129  ,11));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,115  ,14));
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,146  ,5));   // percent
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,84   ,14));
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,140  ,3));
end;







{ TCretaFarmReader }
(*----------------------------------------------------------------------------*)
constructor TCretaNewReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.CretaNew');
end;
(*----------------------------------------------------------------------------*)
function TCretaNewReader.GetCode: string;
begin
  Result := TrimLeftZeroes(GetStrDef(fiCode));
end;
(*----------------------------------------------------------------------------*)
function TCretaNewReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string;
  out MatAA: Integer): Boolean;

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

  // ¡ÌÙÈÍ·Ù‹ÛÙ·ÛÁ „È· TOSTAKI –¡—…∆¡ CR.FARM.
//    if (SupMatCode = '21002407') then
//      SupMatCode := '21001688';

    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

    if not Result then
//      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                     [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
end;
(*----------------------------------------------------------------------------*)
function TCretaNewReader.GetQty: Double;
var
  S : string;
begin
  S := GetStrDef(fiQty, '1');

//  S := Utls.CommaToDot(S);
//  S := Utls.DotToComma(S);
  S := DotToComma(S);

  if StrToFloat(S) = 0 then
    s := '1';

//  S := Utls.CommaToDot(S);
//  Result := StrToFloat(S, Utls.GlobalFormatSettings);
  S := DotToComma(S);
  Result := StrToFloat(S);
end;
(*----------------------------------------------------------------------------*)
function TCretaNewReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 12.10.2012

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
  FileDescriptors.Add(TCretaNewDescriptor.Create);

end.

