unit o_Nikas;

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
  ,o_Descriptors
  ,o_Managers
  ,o_Purchases
  ,uStringHandlingRoutines
  ;


type
(*----------------------------------------------------------------------------*)
  TNikasDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TNikasReader = class(TPurchaseReader)
 protected
   function  GetQty: Double; override;
   function  GetDiscount: Double; override; //y ���� ��� ����
   function  DocStrToDate(S: string): TDate; override;
   function  GetPayType: string; override;    //y ����� ��� ��� ����� ��� �������
   //function  GetPrice: Double; override;   //y �� ��� �� �����, ������ �� �� ���������
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;


implementation


{ TNikasDescriptor }
(*----------------------------------------------------------------------------*)
constructor TNikasDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.�����';
  FFileName        := '�����\*.txt';
  FKind            := fkDelimited;
  FDelimiter       := #9;    //y #9 TAB delimiter?
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  FAFM             := '094029969';
  //FNeedsMapGln     := True;


  // ����� ������������
  FDocTypeMap.Add('��=���');
  FDocTypeMap.Add('???=���');
  //FDocTypeMap.Add('��-��=���');


  // ������ ��������  *MONO* ��� �������
  FNeedsMapPayMode := True;
  FPayModeMap.Add('1=��� �������');

  // ������� ��������
  FMeasUnitMap.Add('tmx=���');
  FMeasUnitMap.Add('KG=���');

  // ������������� �����
  FGLNMap.Add('80050323=1');     //y ��� ����� ������� ����� ��� �����
  FGLNMap.Add('?=2');
  FGLNMap.Add('?=3');
  FGLNMap.Add('?=5');
  FGLNMap.Add('?=6');
  FGLNMap.Add('?=7');
  FGLNMap.Add('?=8');
  FGLNMap.Add('?=9');
  FGLNMap.Add('?=10');
  FGLNMap.Add('?=12');
  FGLNMap.Add('?=13');
  FGLNMap.Add('?=15');
  FGLNMap.Add('?=17');
  FGLNMap.Add('?=19');
  FGLNMap.Add('?=20');
  FGLNMap.Add('?=21');
  FGLNMap.Add('?=22');
  FGLNMap.Add('?=23');
  FGLNMap.Add('?=24'); //14
  FGLNMap.Add('?=24'); //14
  FGLNMap.Add('?=25'); //14
  FGLNMap.Add('?=26'); //14

end;
(*----------------------------------------------------------------------------*)
procedure TNikasDescriptor.AddFileItems;
begin
  inherited;


    { master }
  FItemList.Add(TFileItem.Create(itDate        ,1   ,7-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,5-1));   //y should be ok?
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,5-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,12-1));
  //FItemList.Add(TFileItem.Create(itPayType     ,1   ,34-1));  //y overriden, ��� ������� only


  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  ,25-1));
  FItemList.Add(TFileItem.Create(itQty          ,2  ,16-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,27-1));
  //FItemList.Add(TFileItem.Create(itVAT        ,2  ,22-1));
  FItemList.Add(TFileItem.Create(itDisc         ,2  ,29-1));  //y overriden, calculated
  //FItemList.Add(TFileItem.Create(itDisc2      ,2  ,29-1)); // use line value post-discount to calc discount
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,31-1)); //y
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,17-1));


end;



{ TNikasReader }
(*----------------------------------------------------------------------------*)
constructor TNikasReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.�����');
end;


(*----------------------------------------------------------------------------*)
//y BLOCK IF NECESSARY, OVERRIDES INPUT
function TNikasReader.GetQty: Double;
var
  S : string;
//  tmpResult : Double;
begin
  S := GetStrDef(fiQty, '0');
//  S := Utls.CommaToDot(S);
//  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  S := DotToComma(S);
  Result := abs(StrToFloat(S));
// ���� ���������� ��� ��� ��������� ��� ����� ��������.
// ���������� ������ �� ����� ��� �� ��� ��� ��� ����� ����.
//  tmpResult := abs(StrToFloat(S));
//  if tmpResult = 0.0 then
//  begin
//
//  end;
end;


(*----------------------------------------------------------------------------*)
//y BLOCK IF NECESSARY, OVERRIDES INPUT
function TNikasReader.DocStrToDate(S: string): TDate;
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
(*----------------------------------------------------------------------------*)
function TNikasReader.GetPayType: string;
begin
  Result :=  '��� �������';
end;
(*----------------------------------------------------------------------------*
function TNikasReader.GetPrice: Double;

var
  Price : Double;
  LineValue : Double;
  Quantity : Double;
  DiscountValue : Double;

begin
  LineValue := GetLineValue;
  Quantity := GetQty;
  DiscountValue := GetDiscount;
  //sVAT := GetVAT(MatCode);
  //aVAT := StrToFloat(sVAT);
  // ������ �� ����������� �� ��� ��� �� ����������� ��� ������� ��� Price
  // Price := LineValue / Quantity / (1+(aVAT/100));
  // Price := (LineValue / (1+(aVAT/100)) + DiscountValue) / Quantity;
  // Result := Price;
  Price := (LineValue + DiscountValue) / Quantity;
  Result := Price;

end;
(*----------------------------------------------------------------------------*)
function TNikasReader.GetDiscount: Double;
//yy ������ �� ������ ��� ������� ��� ������� �� �����, ��� ��������� �� �� ��������
//yy S ��������������� ��� �� ����� �� fiDisc ���� �� ������� ��� ������� �������
//yy ��� ����������� �� fiDisc ��� �� ���� ��� ������ ���� ������� ������� ��������
//yy ��� ��������� ��� ������ ������� ������� �� ��� �������� ����.

var
  S : string;
  Pre : Double;
  Post : Double;
  DiscountValue : Double;

begin

  S := GetStrDef(fiDisc, '0');
  S := DotToComma(S);
  S := StripPositiveToStr(S);

  Pre := GetLineValue;
  Post := StrToFloat(S);
  DiscountValue := Pre - Post;
  Result := DiscountValue;

end;
(*----------------------------------------------------------------------------*)

initialization
  FileDescriptors.Add(TNikasDescriptor.Create);

end.

