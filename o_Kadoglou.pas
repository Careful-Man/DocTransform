unit o_Kadoglou;

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
  TKadoglouDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TKadoglouReader = class(TPurchaseReader)
 protected
   function  DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;




implementation


{ TKadoglouDescriptor }

(*----------------------------------------------------------------------------*)
constructor TKadoglouDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.KADOGLOU';
  FFileName        := '��������\*.asc';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '800652274';
  FNeedsMapGln     := True;

//  FIsOem           := True;
//  FIsUniCode       := True;

(*
  FDocTypeMap.Add('���.�����.-���/���=���');
  FDocTypeMap.Add('����.���. ����/���=���');
  FDocTypeMap.Add('���/��� ���������� (��)=���');
*)

  FDocTypeMap.Add('���=���');
  FDocTypeMap.Add('���=���');
  FDocTypeMap.Add('���=���');
  FDocTypeMap.Add('���=���');
  FDocTypeMap.Add('���=���');
  FDocTypeMap.Add('���=���');
  FDocTypeMap.Add('���=���');
  FDocTypeMap.Add('���=���');
  FDocTypeMap.Add('���=���');
  FDocTypeMap.Add('���=���');


  FPayModeMap.Add('01=�������');
  FPayModeMap.Add('02=��� �������');

//  FMeasUnitMap.Add('���=���');
  FMeasUnitMap.Add('���=���');
//  FMeasUnitMap.Add('���=���');

  FGLNMap.Add('2=1');      // �������
  FGLNMap.Add('4=5');      // �������
  FGLNMap.Add('3=8');      // �������
  FGLNMap.Add('13=9');     // ��������
  FGLNMap.Add('5=12');     // �������
  FGLNMap.Add('6=13');     // �����
  FGLNMap.Add('7=15');     // ��������
  FGLNMap.Add('8=19');     // ���������������
  FGLNMap.Add('9=20');     // ���������
  FGLNMap.Add('1=21');     // ������
  FGLNMap.Add('10=22');    // �������
  FGLNMap.Add('11=23');    // ��������
  FGLNMap.Add('12=24');    // ������
  FGLNMap.Add('14=25');    // ����������
  FGLNMap.Add('15=26');    // ������ ������
  FGLNMap.Add('00=99');    // ��������

end;
(*----------------------------------------------------------------------------*)
procedure TKadoglouDescriptor.AddFileItems;
begin
  inherited;

  { master }

  FItemList.Add(TFileItem.Create(itDate       ,1    ,7    ,10));
  FItemList.Add(TFileItem.Create(itDocType    ,1    ,20   ,3));
  FItemList.Add(TFileItem.Create(itDocId      ,1    ,23   ,10));
  FItemList.Add(TFileItem.Create(itGLN        ,1    ,93   ,2));
  FItemList.Add(TFileItem.Create(itPayType    ,1    ,212  ,1));



  { detail }
  FItemList.Add(TFileItem.Create(itCode,      2, 12,  10));        // ����� lookup select
//  FItemList.Add(TFileItem.Create(itBarcode, 2, 12,  13));
  FItemList.Add(TFileItem.Create(itQty,       2, 89,  9));
  FItemList.Add(TFileItem.Create(itPrice,     2, 102, 7));
  FItemList.Add(TFileItem.Create(itVAT,       2, 145, 2));  // percent
  FItemList.Add(TFileItem.Create(itDisc,      2, 118, 5));   // disc %
  FItemList.Add(TFileItem.Create(itLineValue, 2, 128, 8));
  FItemList.Add(TFileItem.Create(itMeasUnit,  2, 79,  3));
end;





{ TKadoglouReader }
(*----------------------------------------------------------------------------*)
constructor TKadoglouReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.Kadoglou');
end;
(*----------------------------------------------------------------------------*)
function TKadoglouReader.DocStrToDate(S: string): TDate;
var
  ADay, AMonth, AYear : word;
  p : integer;
begin
  // 6/6/2018
  S := StripDate(S);


  // �� ����� ���� ��� �� ����� �� ����, �� ������� ����� �����.
  AYear := StrToInt(RightString(S, 4));

// ��� �o string ��������� �� ��������� ������� ��� ����� ���� �� ��� ������.
// ���� ��� �� 6/6

  S := LeftString(S, Length(S)-5);
  p := pos('/', S);
  ADay := StrToInt(LeftString(S, p-1));
  AMonth := StrToInt(RightString(S, Length(S)-p));

(*
  Y := Copy(S, 7, 4);
  M := Trim(Copy(S, 4, 2));
  D := Trim(Copy(S, 1, 2));
*)

  Result := EncodeDate(AYear, AMonth, ADay);
end;



initialization
  FileDescriptors.Add(TKadoglouDescriptor.Create);

end.

