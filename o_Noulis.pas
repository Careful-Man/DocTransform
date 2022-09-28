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
O ����������� �� ������ �� ���� �����������
  NoLine
  HeaderLine
  DetailLine
  SkipLine
��� � ���������� �� ��� ������� ���� ������ ��� �� ��� �������������

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

  FName            := 'Input.Descriptor.������';
  FFileName        := '������\AFRO_*.txt';
  FKind            := fkDelimited;
  FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '084099000';

  FIsMultiSupplier := False;

  FNeedsMapPayMode := True;

  FPayModeMap.Add('1=�������');
  FPayModeMap.Add('2=��� �������');

  FDocTypeMap.Add('1=���');
  FDocTypeMap.Add('2=���');
  FDocTypeMap.Add('3=���');
  FDocTypeMap.Add('4=���');
  FDocTypeMap.Add('5=���');
  FDocTypeMap.Add('7=���');
  FDocTypeMap.Add('8=���');
  FDocTypeMap.Add('9=���');
  FDocTypeMap.Add('15=���');
  FDocTypeMap.Add('21=���');
  FDocTypeMap.Add('22=���');
  FDocTypeMap.Add('23=���');
  FDocTypeMap.Add('24=���');
  FDocTypeMap.Add('25=���');
  FDocTypeMap.Add('29=���');
  FDocTypeMap.Add('33=���');
  FDocTypeMap.Add('51=���');
  FDocTypeMap.Add('52=���');
  FDocTypeMap.Add('53=���');
  FDocTypeMap.Add('55=���');
  FDocTypeMap.Add('61=���');
  FDocTypeMap.Add('62=���');
  FDocTypeMap.Add('63=���');
  FDocTypeMap.Add('65=���');

  FNeedsMapGln     := True;

  FGLNMap.Add('2=1');     //    ������� 18
  FGLNMap.Add('1=13');    //    ��������� 14
  FGLNMap.Add('7=8');     //    �������� 12
  FGLNMap.Add('10=5');     //    25 ������� 113-115
  FGLNMap.Add('11=12');    //    ������� 6
  FGLNMap.Add('12=15');    //    ���������� 27 & ����
  FGLNMap.Add('15=19');    //    ��������������� 5
  FGLNMap.Add('16=20');    //    ��������� 6
  FGLNMap.Add('17=21');    //    �. ���������� 9 ������
  FGLNMap.Add('18=22');    //    ������� 80
  FGLNMap.Add('19=23');    //    �������� 37
  FGLNMap.Add('20=24');    //    ������ 109
  FGLNMap.Add('21=25');    //    ���������� 19
  FGLNMap.Add('26=26');    //    ���������� 19


  FMeasUnitMap.Add('1=���');
  FMeasUnitMap.Add('2=���');
  FMeasUnitMap.Add('3=���');

end;
(*----------------------------------------------------------------------------
To ������ ��� ������ ����� ��� ������ ������ ��� ���������� �� detail.
� ������ �������� �� ���� ����������  H#
���� detail ������ �������� �� D#
��� ������� ������ �� �������� spaces
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
  FItemList.Add(TFileItem.Create(itCode, 2, 1));        // ����� lookup select
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
  FDescriptor := FileDescriptors.Find('Input.Descriptor.������');
end;
(*----------------------------------------------------------------------------*)
(* ����� ����������� �� ������ �� �������������� ��� ����������.              *)
(*----------------------------------------------------------------------------*)
(* � ������ ��� ����� �� ����� ���� ������� ��� ��� ���� ��� ������ ����.  *)
(* � ����������� ����� : (����� ���� ������� - ���) (�.�.  ���������������)   *)
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
  (* �� �.�. � ��� ����� 13%, �� ����� �������� ��� 1 + 0,13 => 1,13          *)
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

