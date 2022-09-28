unit o_Sergal;

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
//  ,tpk_Utls
  ,o_Descriptors
  ,o_Managers
  ,o_Purchases

  ,uStringHandlingRoutines
  ;


type
(*----------------------------------------------------------------------------*)
  TSergalDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TSergalReader = class(TPurchaseReader)
 protected
   function  DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;




implementation


{ TSergalDescriptor }

(*----------------------------------------------------------------------------*)
constructor TSergalDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.SERGAL';
  FFileName        := 'сеяцак\AFRODITI*.TXT';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smEmptyLine;
//  FMasterMarker    := 'H';
//  FDetailMarker    := 'D';
  FAFM             := '094406872';

  FIsOem           := True;


  FDocTypeMap.Add('3003=тил');
  FDocTypeMap.Add('3004=тда');
  FDocTypeMap.Add('4000=пеп'); // (П + А)
  FDocTypeMap.Add('4001=пеп');
  FDocTypeMap.Add('4002=пей');
  FDocTypeMap.Add('4003=пей');
  FDocTypeMap.Add('8000=дап'); // Mobile
  FDocTypeMap.Add('8001=тда'); // Mobile
  FDocTypeMap.Add('8002=пеп'); // (П + А) Mobile
//  FDocTypeMap.Add('тда=тда');
//  FDocTypeMap.Add('пеп=пеп');


  // епи пистысг

  FMeasUnitMap.Add('тел=тел');
  FMeasUnitMap.Add('йик=йик');
  FMeasUnitMap.Add('йиб=йиб');

end;
(*----------------------------------------------------------------------------*)
procedure TSergalDescriptor.AddFileItems;
begin
  inherited;

  { master }

  FItemList.Add(TFileItem.Create(itDate       ,1    ,7    ,8));
  FItemList.Add(TFileItem.Create(itDocType    ,1    ,17   ,4));
  FItemList.Add(TFileItem.Create(itDocId      ,1    ,23   ,6));
  FItemList.Add(TFileItem.Create(itGLN        ,1    ,1    ,2));    // GLN
  //FItemList.Add(TFileItem.Create(itPayType    ,1    ,0    ,0));



  { detail }
  FItemList.Add(TFileItem.Create(itCode       ,2   ,1    ,10));        // ХщКЕИ lookup select
  //FItemList.Add(TFileItem.Create(itBarcode, 2, 13, 14));
  FItemList.Add(TFileItem.Create(itQty        ,2   ,40   ,9));
  FItemList.Add(TFileItem.Create(itPrice      ,2   ,64   ,9));
  FItemList.Add(TFileItem.Create(itVAT        ,2   ,146  ,2));  // percent
  FItemList.Add(TFileItem.Create(itDisc       ,2   ,88   ,9));  // disc value
  FItemList.Add(TFileItem.Create(itLineValue  ,2   ,136  ,9));
  FItemList.Add(TFileItem.Create(itMeasUnit   ,2   ,221  ,3));
end;







{ TSergalReader }
(*----------------------------------------------------------------------------*)
constructor TSergalReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.Sergal');
end;
(*----------------------------------------------------------------------------*)
function TSergalReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 20110809

  Y := Copy(S, 1, 4);
  M := Trim(Copy(S, 5, 2));
  D := Trim(Copy(S, 7, 2));
  Result := EncodeDate(
                       StrToInt(Y),
                       StrToInt(M),
                       StrToInt(D)
                       );
end;



initialization
  FileDescriptors.Add(TSergalDescriptor.Create);

end.

