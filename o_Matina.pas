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

  FName            := 'Input.Descriptor.������'; // Greek
  FFileName        := '������\��������*.txt';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  //FMasterMarker    := 'H';
  //FDetailMarker    := 'D';
  FAFM             := '997543804';
  FNeedsMapGln     := True;

  FNeedsMapPayMode := True;
  FPayModeMap.Add('01=�������');
  FPayModeMap.Add('06=��� �������');

  FDocTypeMap.Add('1=���');
  FDocTypeMap.Add('2=���');
  FDocTypeMap.Add('3=���');
  FDocTypeMap.Add('4=���');
  FDocTypeMap.Add('5=���');
  FDocTypeMap.Add('12=���');
  FDocTypeMap.Add('16=���');
  FDocTypeMap.Add('17=���');
  FDocTypeMap.Add('18=���');


//  FMeasUnitMap.Add('PCS=���');
//  FMeasUnitMap.Add('BOX=���');


  FGLNMap.Add('10009=1');     //    ������� 18
  FGLNMap.Add('10006=2');     //    ��������� 1
  FGLNMap.Add('10012=3');     //    ���������� 46
  FGLNMap.Add('10013=5');     //    25 ������� 113-115
  FGLNMap.Add('10011=6');     //    ������� 38 & ������
  FGLNMap.Add('10008=7');     //    �������� 92
  FGLNMap.Add('10007=8');     //    �������� 12
  FGLNMap.Add('10001=9');     //    �������� 154
  FGLNMap.Add('10010=10');    //    ��� ������
  FGLNMap.Add('10002=12');    //    ������� 6
  FGLNMap.Add('10004=13');    //    ��������� 14
  FGLNMap.Add('10005=15');    //    ���������� 27 & ����
  FGLNMap.Add('10015=17');    //    ������ 43
  FGLNMap.Add('10016=19');    //    ��������������� 5
  FGLNMap.Add('10018=20');    //    ��������� 6
  FGLNMap.Add('10019=21');    //    �. ���������� 9 ������
  FGLNMap.Add('10020=22');    //    ������� 80 ���������
  FGLNMap.Add('10021=23');    //    �������� 37 ���������
  FGLNMap.Add('10022=24');    //    ������ 109 ���������
  FGLNMap.Add('10023=25');    //    ���������� 19 �����������
  FGLNMap.Add('10024=26');    //    ������
  FGLNMap.Add('99999=99');    //    �������� // ��� ����� �� 99999 ����� ��� ������


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
  FItemList.Add(TFileItem.Create(itPayType    ,1  ,96   ,6));   // ��


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
  FDescriptor := FileDescriptors.Find('Input.Descriptor.������'); // Greek
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
(* ��� ��� ������ ��� ���� ������ ����� ��� ������� �� ��� ������ ------------*)
function TMatinaReader.GetVAT(MatCode: string): string;
var
  tmpVAT: integer;
begin
  Result := 'xx';
  // �� ���������� ��� ��� ������ ����� 7=13 ��� 18=24
  tmpVAT := StrToInt(GetStrDef(fiVAT));
  case tmpVAT of
    7 : Result := '13';
    18: Result := '24';
  end;
end;
(*----------------------------------------------------------------------------*)
function TMatinaReader.GetMeasUnitAA: Integer;
begin
  Result := FManager.GetMaterialMeasureUnitAA(MatAA, '���');
end;
(*----------------------------------------------------------------------------*)
function TMatinaReader.DocStrToDate(S: string): TDate;
var ADay, AMonth, AYear : word;
    p : integer;
begin
  // 11/1/2019

  S := StripDate(S);

  // �� ����� ���� ��� �� ����� �� ����, �� ������� ����� �����.
  AYear := StrToInt(RightString(S, 4));
//  ShowMessage(Copy(S, 6, 4));
// ��� �o string ��������� �� ��������� ������� ��� ����� ���� �� ��� ������.
// ���� ��� �� 1/9
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
