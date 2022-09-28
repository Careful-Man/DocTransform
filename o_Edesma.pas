unit o_Edesma;

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
  TEdesmaDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TEdesmaReader = class(TPurchaseReader)
 protected
   function  DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;




implementation


{ TSergalDescriptor }

(*----------------------------------------------------------------------------*)
constructor TEdesmaDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.EDESMA';
  FFileName        := 'едесла\afroditi*.txt';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smEmptyLine;
//  FMasterMarker    := 'H';
//  FDetailMarker    := 'D';
  FAFM             := '094069537';

//  FIsOem           := True;
//  FIsUniCode       := True;


  FDocTypeMap.Add('тда=тда');
  FDocTypeMap.Add('пис=пеп');

  // епи пистысг

  FMeasUnitMap.Add('тел=тел');
  FMeasUnitMap.Add('йик=йик');

end;
(*----------------------------------------------------------------------------*)
procedure TEdesmaDescriptor.AddFileItems;
begin
  inherited;

  { master }

  FItemList.Add(TFileItem.Create(itDate       ,1    ,7    ,8));
  FItemList.Add(TFileItem.Create(itDocType    ,1    ,16   ,3));
  FItemList.Add(TFileItem.Create(itDocId      ,1    ,21   ,8));
  FItemList.Add(TFileItem.Create(itGLN        ,1    ,1    ,5));    // GLN
  //FItemList.Add(TFileItem.Create(itPayType    ,1    ,0    ,0));



  { detail }
  FItemList.Add(TFileItem.Create(itCode, 2, 1, 7));        // ХщКЕИ lookup select
//  FItemList.Add(TFileItem.Create(itBarcode, 2, 12, 13));
  FItemList.Add(TFileItem.Create(itQty, 2, 27, 8));
  FItemList.Add(TFileItem.Create(itPrice, 2, 36, 9));
  FItemList.Add(TFileItem.Create(itVAT, 2, 92, 2));  // percent
  FItemList.Add(TFileItem.Create(itDisc, 2, 62, 9));   // disc value
  FItemList.Add(TFileItem.Create(itLineValue, 2, 72, 9));
  FItemList.Add(TFileItem.Create(itMeasUnit, 2, 95, 3));
end;





{ TEdesmaReader }
(*----------------------------------------------------------------------------*)
constructor TEdesmaReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.Edesma');
end;
(*----------------------------------------------------------------------------*)
function TEdesmaReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 02/07/12

  Y := Copy(S, 7, 2);
  M := Trim(Copy(S, 4, 2));
  D := Trim(Copy(S, 1, 2));
  Result := EncodeDate(
                       StrToInt(Y) + 2000,
                       StrToInt(M),
                       StrToInt(D)
                       );
end;



initialization
  FileDescriptors.Add(TEdesmaDescriptor.Create);

end.

