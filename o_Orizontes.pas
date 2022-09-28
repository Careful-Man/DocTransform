(*
  ������ ������� ���� ���� �� format ��� excel, ������ �� ��������
  ��� ������ � ��� ����������� format ����������� ��� �������.

  ������ �� ������ ��� ����� ��� ��������� ��� ��� ��/���.
*)
unit o_Orizontes;

interface

uses
   Windows
  ,SysUtils
  ,Classes
  ,Controls
  ,Forms
  ,Dialogs
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
O ����������� �� ������ �� ���� �����������
  NoLine
  HeaderLine
  DetailLine
  SkipLine
��� � ���������� �� ��� ������� ���� ������ ��� �� ��� �������������

*)
  TOrizontesDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TOrizontesReader = class(TPurchaseReader)
 protected
   function GetGLN(): string; override;
   function GetVAT(MatCode: string): string; override;
   function DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;



implementation




{ TFarmaKoukakiDescriptor }
(*----------------------------------------------------------------------------*)
constructor TOrizontesDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.���������';
  FFileName        := '���������\��������*.csv';
  FKind            := fkDelimited;
  FDelimiter       := ';';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  FAFM             := '094449779';

//  FIsOem           := True;

  FNeedsMapGln     := False;
 //  FIsMultiSupplier := True;

//  FNeedsMapPayMode := True;

  FDocTypeMap.Add('001=���');
  FDocTypeMap.Add('002=���');

  FMeasUnitMap.Add('101=���');
  FMeasUnitMap.Add('102=���');

end;
(*----------------------------------------------------------------------------*)
procedure TOrizontesDescriptor.AddFileItems;
begin
  inherited;

  { master }
//  FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate        ,1   ,1-1));
  FItemList.Add(TFileItem.Create(itDocType     ,1   ,2-1));
  FItemList.Add(TFileItem.Create(itDocId       ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itDocChanger  ,1   ,3-1));
  FItemList.Add(TFileItem.Create(itGLN         ,1   ,0-1)); // No GLN for Orizontes

  { detail }
  FItemList.Add(TFileItem.Create(itCode         ,2  , 9-1));      // ������ �������, ��� 1/1/13 ���� �������.
  FItemList.Add(TFileItem.Create(itQty          ,2  ,19-1));
  FItemList.Add(TFileItem.Create(itPrice        ,2  ,15-1));
  FItemList.Add(TFileItem.Create(itVAT          ,2  ,14-1)); // 1130, 1240
  FItemList.Add(TFileItem.Create(itDisc         ,2  ,16-1)); // Percent
  FItemList.Add(TFileItem.Create(itDisc2        ,2  ,17-1)); // Percent
  FItemList.Add(TFileItem.Create(itDisc3        ,2  ,18-1)); // Percent
  FItemList.Add(TFileItem.Create(itLineValue    ,2  ,21-1));
  FItemList.Add(TFileItem.Create(itMeasUnit     ,2  ,11-1));

end;

(***** ������������� 599-005-013 - ���� ���������� ���� ����.120gr PLAY&WIN
             ��      599-005-010 - L� V�C�� Q.R. BABYBEL 120��                *****)



{ TOrizontesReader }
(*----------------------------------------------------------------------------*)
constructor TOrizontesReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.���������');
end;
(*----------------------------------------------------------------------------*)
function TOrizontesReader.GetGLN: string;
begin
// �� ��������� ��������� ���� ���� ����.
  Result := '99';
end;
(*----------------------------------------------------------------------------*)
(* ��� ���� ��������� ��� ���� ������ ����� ��� ������� �� ��� ������ -----------*)
function TOrizontesReader.GetVAT(MatCode: string): string;
var
  VATAsNumber : real;
  VATtmp: string;
begin
  // ��������� �� string '1130' � '1240'
  VATtmp := GetStrDef(fiVAT);
  VATAsNumber := (StrToFloat(VATtmp)-1000)/10;
  Result := FloatToStr(VATAsNumber);
end;
(*----------------------------------------------------------------------------*)
function TOrizontesReader.DocStrToDate(S: string): TDate;
var ADay, AMonth, AYear : word;
    p : integer;
begin
  // 8/8/2016

  AYear := StrToInt(RightString(S, 4));
// ��� �o string ��������� �� ��������� ������� ��� ����� ���� �� ��� ������.
// ���� ��� �� 1/9
  S := LeftString(S, Length(S)-5);
  p := pos('/', S);
  ADay := StrToInt(StripInt(LeftString(S, p-1)));
  AMonth := StrToInt(RightString(S, Length(S)-p));
  Result := EncodeDate(AYear, AMonth, ADay);

end;
(*----------------------------------------------------------------------------*)






initialization
  FileDescriptors.Add(TOrizontesDescriptor.Create);

end.
