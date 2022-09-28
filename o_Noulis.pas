unit o_Noulis;

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
  ,Math
  ,uStringHandlingRoutines

  ;

type
(*----------------------------------------------------------------------------
O ðåñéãñáöÝáò èá ðñÝðåé íá Ý÷åé êáôáóôÜóåéò
  NoLine
  HeaderLine
  DetailLine
  SkipLine
êáé ï áíáãíþóôçò íá ôïõ ðåñíÜåé êÜèå ãñáììÞ êáé íá ôïí óõìâïõëåýåôáé

*)
  TNoulisDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TNoulisReader = class(TPurchaseReader)
 protected
   function  GetLineValue: Double; override;
   function  GetDocNo: string; override;
   function  DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;



implementation




{ TMebgalDescriptor }
(*----------------------------------------------------------------------------*)
constructor TNoulisDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ÍÏÕËÇÓ';
  FFileName        := 'ÍÏÕËÇÓ\AFRO_*.txt';
  FKind            := fkDelimited;
  FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '084099000';

  FIsMultiSupplier := False;

  FNeedsMapPayMode := True;

  FPayModeMap.Add('1=ÌÅÔÑÇÔÁ');
  FPayModeMap.Add('2=ÅÐÉ ÐÉÓÔÙÓÇ');

  FDocTypeMap.Add('1=ÔÄÁ');
  FDocTypeMap.Add('2=ÄÁÐ');
  FDocTypeMap.Add('3=ÔÉÌ');
  FDocTypeMap.Add('4=ÐÅÐ');
  FDocTypeMap.Add('5=ÐÅÐ');
  FDocTypeMap.Add('7=ÄÁÐ');
  FDocTypeMap.Add('8=ÔÄÁ');
  FDocTypeMap.Add('9=ÄÁÐ');
  FDocTypeMap.Add('15=ÄÁÐ');
  FDocTypeMap.Add('21=ÔÄÁ');
  FDocTypeMap.Add('22=ÄÁÐ');
  FDocTypeMap.Add('23=ÔÉÌ');
  FDocTypeMap.Add('24=ÐÅÐ');
  FDocTypeMap.Add('25=ÐÅÊ');
  FDocTypeMap.Add('29=ÔÄÁ');
  FDocTypeMap.Add('33=ÔÉÌ');
  FDocTypeMap.Add('51=ÔÄÁ');
  FDocTypeMap.Add('52=ÄÁÐ');
  FDocTypeMap.Add('53=ÔÉÌ');
  FDocTypeMap.Add('55=ÐÅÊ');
  FDocTypeMap.Add('61=ÔÄÁ');
  FDocTypeMap.Add('62=ÄÁÐ');
  FDocTypeMap.Add('63=ÔÉÌ');
  FDocTypeMap.Add('65=ÐÅÊ');

  FNeedsMapGln     := True;

  FGLNMap.Add('2=1');     //    ÌÁÑÁÓËÇ 18
  FGLNMap.Add('1=13');    //    ÂÅÍÉÆÅËÏÕ 14
  FGLNMap.Add('7=8');     //    ÊÇÖÉÓÉÁÓ 12
  FGLNMap.Add('10=5');     //    25 ÌÁÑÔÉÏÕ 113-115
  FGLNMap.Add('11=12');    //    ÅÃÍÁÔÉÁ 6
  FGLNMap.Add('12=15');    //    ÍÉÊÏÐÏËÅÙÓ 27 & ×ÉÏÕ
  FGLNMap.Add('15=19');    //    ÐÁÑÁÓÊÅÕÏÐÏÕËÏÕ 5
  FGLNMap.Add('16=20');    //    ÅÐÔÁËÏÖÏÕ 6
  FGLNMap.Add('17=21');    //    Ì. ÁËÅÎÁÍÄÑÏÕ 9 ÐÕËÁÉÁ
  FGLNMap.Add('18=22');    //    ÁÉÃÁÉÏÕ 80
  FGLNMap.Add('19=23');    //    ÂÉÈÕÍÉÁÓ 37
  FGLNMap.Add('20=24');    //    ÐÏÍÔÏÕ 109
  FGLNMap.Add('21=25');    //    ×ÁËÊÉÄÉÊÇÓ 19
  FGLNMap.Add('26=26');    //    ×ÁËÊÉÄÉÊÇÓ 19


  FMeasUnitMap.Add('1=ÊÉË');
  FMeasUnitMap.Add('2=ÔÅÌ');
  FMeasUnitMap.Add('3=ÊÉÂ');

end;
(*----------------------------------------------------------------------------
To áñ÷åßï ôçò ÍÏÕËÇÓ åßíáé ìßá ãñáììÞ ìÜóôåñ êáé áêïëïõèïýí ïé detail.
Ç ìÜóôåñ îåêéíÜåé ìå ôïõò ÷áñáêôÞñåò  H#
ÊÜèå detail ãñáììÞ îåêéíÜåé ìå D#
Áðü ìðñïóôÜ ìðïñåß íá õðÜñ÷ïõí spaces
----------------------------------------------------------------------------*)
procedure TNoulisDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate, 1, 1));
  FItemList.Add(TFileItem.Create(itDocType, 1, 2));
  FItemList.Add(TFileItem.Create(itDocId, 1, 3));
  FItemList.Add(TFileItem.Create(itGLN, 1, 4));    // GLN
  FItemList.Add(TFileItem.Create(itPayType, 1, 5));


  // itRelDoc = itDocType + itDocId

  { detail }
  FItemList.Add(TFileItem.Create(itCode, 2, 1));        // èÝëåé lookup select
  FItemList.Add(TFileItem.Create(itQty, 2, 4));
  FItemList.Add(TFileItem.Create(itPrice, 2, 5));
  FItemList.Add(TFileItem.Create(itVAT, 2, 6));  // percent
  FItemList.Add(TFileItem.Create(itDisc, 2, 7));   // disc value
  FItemList.Add(TFileItem.Create(itLineValue, 2, 8));
  FItemList.Add(TFileItem.Create(itMeasUnit, 2, 9));
end;





{ TMebgalReader }
(*----------------------------------------------------------------------------*)
constructor TNoulisReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ÍÏÕËÇÓ');
end;
(*----------------------------------------------------------------------------*)
(* Åßíáé ðñïôéìüôåñï íá ìðïñåß íá ÷ñçóéìïðïéçèåß áðü ïðïõäÞðïôå.              *)
(*----------------------------------------------------------------------------*)
(* Ï Íïýëçò ìïõ äßíåé ôç ìéêôÞ áîßá ãñáììÞò åíþ åãþ èÝëù ôçí êáèáñÞ áîßá.  *)
(* Ï õðïëïãéóìüò åßíáé : (ÌéêôÞ áîßá ãñáììÞò - ÖÐÁ) (Ì.Á.  ÁðïöïñïëïãçìÝíç)   *)
function TNoulisReader.GetLineValue: Double;

  function InternalGetLineValue: double;
  var
    S : string;
  begin
    S := GetStrDef(fiLineValue, '0');
//    S := Utls.CommaToDot(S);
//    Result := StrToFloat(S, Utls.GlobalFormatSettings);
    S := DotToComma(S);
    Result := StrToFloat(S);
  end;

var
  F, T : double;
  S : string;
  rm : TFPURoundingMode;
  NetValue : double;
  TotalValue : double;
begin
  T := InternalGetLineValue();
  F := StrToFloat(GetVAT(MatCode));
  (* Áí ð.÷. ï ÖÐÁ åßíáé 13%, èá ãßíåé äéáßñåóç äéá 1 + 0,13 => 1,13          *)
  T := T / (1+(F/100));
  Result := T;
end;
(*----------------------------------------------------------------------------*)
function TNoulisReader.GetDocNo: string;
var
  s: string;
begin
  s := GetStrDef(fiDocChanger);
  Result := TrimLeftZeroes(RightString(s, 6));
end;
(*----------------------------------------------------------------------------*)
function TNoulisReader.DocStrToDate(S: string): TDate;
begin
  // 01/11/16

  Result := EncodeDate(StrToInt(Copy(S, 7, 2))+2000,
                       StrToInt(Copy(S, 4, 2)),
                       StrToInt(Copy(S, 1, 2)));
end;



initialization
  FileDescriptors.Add(TNoulisDescriptor.Create);

end.

