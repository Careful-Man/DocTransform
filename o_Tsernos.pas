unit o_Tsernos;

interface

uses
   Windows
  ,SysUtils
  ,JclSysUtils
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
(*----------------------------------------------------------------------------
O περιγραφέας θα πρέπει να έχει καταστάσεις
  NoLine
  HeaderLine
  DetailLine
  SkipLine
και ο αναγνώστης να του περνάει κάθε γραμμή και να τον συμβουλεύεται

*)
  TTsernosDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TTsernosReader = class(TPurchaseReader)
 protected
   function GetVAT(MatCode: string): string; override;
   function  DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;



implementation




{ TMebgalDescriptor }
(*----------------------------------------------------------------------------*)
constructor TTsernosDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ΤΣΕΡΝΟΣ';
  FFileName        := 'ΤΣΕΡΝΟΣ\Afroditi.txt';
  FKind            := fkDelimited;
  FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '800745534';
//  FIsMultiSupplier := True;

//  FIsOem           := True;
//  FIsUniCode       := True;

  FNeedsMapPayMode := True;

  FDocTypeMap.Add('ΔΑΠ=ΔΑΠ');
  FDocTypeMap.Add('ΤΙΠ=ΤΙΜ');
  FDocTypeMap.Add('ΤΔΑ=ΤΔΑ');
  FDocTypeMap.Add('ΠΤΔ=ΠΕΠ');
  FDocTypeMap.Add('ΠΤΕ=ΠΕΚ');
  FDocTypeMap.Add('ΠΤΙ=ΠΕΠ');

  FPayModeMap.Add('0001=ΜΕΤΡΗΤΑ');
  FPayModeMap.Add('0002=ΕΠΙ ΠΙΣΤΩΣΗ');

  FMeasUnitMap.Add('ΚΙΛ=ΚΙΛ');
  FMeasUnitMap.Add('ΤΕΜ=ΤΕΜ');

end;

procedure TTsernosDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate, 1, 1));
  FItemList.Add(TFileItem.Create(itDocType, 1, 2));
  FItemList.Add(TFileItem.Create(itDocId, 1, 4));
  FItemList.Add(TFileItem.Create(itGLN, 1, 3));    // GLN
  FItemList.Add(TFileItem.Create(itPayType, 1, 10));


  // itRelDoc = itDocType + itDocId

  { detail }
  FItemList.Add(TFileItem.Create(itCode, 2, 1));        // θέλει lookup select
(*  FItemList.Add(TFileItem.Create(itBarcode, 2, 4)); *)
  FItemList.Add(TFileItem.Create(itQty, 2, 5));
  FItemList.Add(TFileItem.Create(itPrice, 2, 6));
  FItemList.Add(TFileItem.Create(itVAT, 2, 4));  // percent
  FItemList.Add(TFileItem.Create(itDisc, 2, 7));   // disc value
  FItemList.Add(TFileItem.Create(itLineValue, 2, 8));
  FItemList.Add(TFileItem.Create(itMeasUnit, 2, 3));
end;





{ TTsernosReader }
(*----------------------------------------------------------------------------*)
constructor TTsernosReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ΤΣΕΡΝΟΣ');
end;
(*----------------------------------------------------------------------------*)
(* Για τον ΤΣΕΡΝΟ δεν κάνω τίποτα γιατί μου στέλνει το ΦΠΑ έτοιμο ------------*)
function TTsernosReader.GetVAT(MatCode: string): string;
begin
  Result := RightString(GetStrDef(fiVAT), 2);
end;
(*----------------------------------------------------------------------------*)
function TTsernosReader.DocStrToDate(S: string): TDate;
var
  List: TStringList;
begin
  // 1/10/2018 - d/mm/yyyy

  List := TStringList.Create;
  Split(S, '/', List);
//  Result := JclSysUtils.EncodeDate(List[2], List[1], List[0]);
//    Result := JclSysUtils

  Result := EncodeDate(StrToInt(List[2]), StrToInt(List[1]), StrToInt(List[0]));
end;





initialization
  FileDescriptors.Add(TTsernosDescriptor.Create);

end.
