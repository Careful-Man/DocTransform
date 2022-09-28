unit o_Mebgal;

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
(*----------------------------------------------------------------------------
O περιγραφέας θα πρέπει να έχει καταστάσεις
  NoLine
  HeaderLine
  DetailLine
  SkipLine
και ο αναγνώστης να του περνάει κάθε γραμμή και να τον συμβουλεύεται

*)
  TMebgalDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TMebgalReader = class(TPurchaseReader)
 protected
   function  DocStrToDate(S: string): TDate; override;
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;



implementation




{ TMebgalDescriptor }
(*----------------------------------------------------------------------------*)
constructor TMebgalDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ΜΕΒΓΑΛ';
  FFileName        := 'ΜΕΒΓΑΛ\inv_lines_*.txt';
  FKind            := fkDelimited;
  FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '';
  FIsMultiSupplier := True;

  FNeedsMapPayMode := True;

  FDocTypeMap.Add('01=ΔΑΠ');
  FDocTypeMap.Add('02=ΤΙΜ');
  FDocTypeMap.Add('03=ΤΔΑ');
  FDocTypeMap.Add('04=ΠΕΠ');
  FDocTypeMap.Add('06=ΠΕΚ');

  FDocTypeMap.Add('07=ΠΕΔ');
  FDocTypeMap.Add('08=ΤΙΔ');
  FDocTypeMap.Add('09=ΤΧΤ');
  FDocTypeMap.Add('11=ΠΕΚ');

  FDocTypeMap.Add('13=ΔΑΠ');


  FPayModeMap.Add('10=ΜΕΤΡΗΤΑ');
  FPayModeMap.Add('20=ΕΠΙ ΠΙΣΤΩΣΗ');
  FPayModeMap.Add('30=ΕΠΙ ΠΙΣΤΩΣΗ');

  FMeasUnitMap.Add('1=ΤΕΜ');
  FMeasUnitMap.Add('2= ');
  FMeasUnitMap.Add('3= ');
  FMeasUnitMap.Add('4= ');
  FMeasUnitMap.Add('5= ');
  FMeasUnitMap.Add('6= ');
  FMeasUnitMap.Add('7=ΚΙΛ');

{
select aa
from MeasUnit
where Code = :c

select AA
from MtrlMUnt WITH (READUNCOMMITTED)
where MaterialAA = :MatAA
and MUnitAA = :MM

select
  MtrlMUnt.AA    as AA
from
  MtrlMUnt
    join MeasUnit on MeasUnit.AA = MtrlMUnt.MUnitAA
where
       MtrlMUnt.MaterialAA = :MatAA
   and MeasUnit.Code       = :MeasUnit_Code

}
end;
(*----------------------------------------------------------------------------
To αρχείο της ΜΕΒΓΑΛ είναι μία γραμμή μάστερ και ακολουθούν οι detail.
Η μάστερ ξεκινάει με τους χαρακτήρες  H#
Κάθε detail γραμμή ξεκινάει με D#
Από μπροστά μπορεί να υπάρχουν spaces
----------------------------------------------------------------------------*)
procedure TMebgalDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate, 1, 22));
  FItemList.Add(TFileItem.Create(itDocType, 1, 3));
  FItemList.Add(TFileItem.Create(itDocId, 1, 21));
  FItemList.Add(TFileItem.Create(itGLN, 1, 10));    // GLN
  FItemList.Add(TFileItem.Create(itPayType, 1, 11));


  // itRelDoc = itDocType + itDocId

  { detail }
  FItemList.Add(TFileItem.Create(itCode, 2, 16));        // θέλει lookup select
(*  FItemList.Add(TFileItem.Create(itBarcode, 2, 4)); *)
  FItemList.Add(TFileItem.Create(itQty, 2, 6));
  FItemList.Add(TFileItem.Create(itPrice, 2, 9));
  FItemList.Add(TFileItem.Create(itVAT, 2, 13));  // percent
  FItemList.Add(TFileItem.Create(itDisc, 2, 11));   // disc value
  FItemList.Add(TFileItem.Create(itLineValue, 2, 12));
  FItemList.Add(TFileItem.Create(itMeasUnit, 2, 7));
end;





{ TMebgalReader }
(*----------------------------------------------------------------------------*)
constructor TMebgalReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ΜΕΒΓΑΛ');
end;
(*----------------------------------------------------------------------------*)
function TMebgalReader.DocStrToDate(S: string): TDate;
begin
  // 20120721

  Result := EncodeDate(StrToInt(Copy(S, 1, 4)),
                       StrToInt(Copy(S, 5, 2)),
                       StrToInt(Copy(S, 7, 2)));
end;
(*----------------------------------------------------------------------------*)
function TMebgalReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

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
  if (SupMatCode = '2511') or (SupMatCode = '2687') then
    SupMatCode := '2264';
  if SupMatCode = '1283' then
    SupMatCode := '1321';
  if SupMatCode = '1102' then
    SupMatCode := '1322';

  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);
  if not Result then
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                   [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
end;






initialization
  FileDescriptors.Add(TMebgalDescriptor.Create);

end.
