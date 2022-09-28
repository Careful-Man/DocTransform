unit o_Yfantis;

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
  TYfantisDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TYfantisReader = class(TPurchaseReader)
 protected
   function  DocStrToDate(S: string): TDate; override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;




implementation


{ TYantisDescriptor }

(*----------------------------------------------------------------------------*)
constructor TYfantisDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.YFANTIS';
  FFileName        := '�������\Afroditi*.txt';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsHeaderDetail;
  FSeparationMode  := smMarker;
  FMasterMarker    := 'H';
  FDetailMarker    := 'D';
  FAFM             := '094383332';
  FNeedsMapGln     := True;

//  FIsOem           := True;
//  FIsUniCode       := True;

(*
  FDocTypeMap.Add('���.�����.-���/���=���');
  FDocTypeMap.Add('����.���. ����/���=���');
  FDocTypeMap.Add('���/��� ���������� (��)=���');
*)

  FDocTypeMap.Add('702=���');
  FDocTypeMap.Add('711=���');
  FDocTypeMap.Add('715=���');


  FPayModeMap.Add('01=�������');
  FPayModeMap.Add('02=��� �������');

  FMeasUnitMap.Add('���=���');
  FMeasUnitMap.Add('���=���');
  FMeasUnitMap.Add('���=���');

  FGLNMap.Add('01=1');     // �������
  FGLNMap.Add('02=2');     // ���������
  FGLNMap.Add('03=3');     // ����������
  FGLNMap.Add('09=5');     // �������
  FGLNMap.Add('05=6');     // �������
  FGLNMap.Add('04=7');     // ��������
  FGLNMap.Add('06=8');     // �������
  FGLNMap.Add('07=9');     // ��������
  FGLNMap.Add('08=10');    // ������
  FGLNMap.Add('10=12');    // �������
  FGLNMap.Add('11=13');    // �����
  FGLNMap.Add('13=15');    // ��������
  FGLNMap.Add('14=16');    // ��������
  FGLNMap.Add('15=17');    // ������
  FGLNMap.Add('17=19');    // ���������������
  FGLNMap.Add('18=20');    // ���������
  FGLNMap.Add('19=21');    // ������
  FGLNMap.Add('20=22');    // �������
  FGLNMap.Add('21=23');    // ��������
  FGLNMap.Add('22=24');    // ������
  FGLNMap.Add('23=25');    // ����������
  FGLNMap.Add('24=26');    // ������ ������
  FGLNMap.Add('00=99');    // ��������

end;
(*----------------------------------------------------------------------------*)
procedure TYfantisDescriptor.AddFileItems;
begin
  inherited;

  { master }

  FItemList.Add(TFileItem.Create(itDate       ,1    ,98   ,8));
  FItemList.Add(TFileItem.Create(itDocType    ,1    ,34   ,3));
  FItemList.Add(TFileItem.Create(itDocId      ,1    ,90   ,8));
  FItemList.Add(TFileItem.Create(itGLN        ,1    ,31   ,3));
  //FItemList.Add(TFileItem.Create(itPayType    ,1    ,0    ,0));



  { detail }
  FItemList.Add(TFileItem.Create(itCode,      2, 15, 15));        // ����� lookup select
//  FItemList.Add(TFileItem.Create(itBarcode, 2, 12, 13));
  FItemList.Add(TFileItem.Create(itQty,       2, 30, 12));
  FItemList.Add(TFileItem.Create(itPrice,     2, 42, 12));
  FItemList.Add(TFileItem.Create(itVAT,       2, 90, 12));  // percent
  FItemList.Add(TFileItem.Create(itDisc,      2, 66, 12));   // disc value
  FItemList.Add(TFileItem.Create(itLineValue, 2, 78, 12));
  FItemList.Add(TFileItem.Create(itMeasUnit,  2, 114, 3));
end;





{ TYantisReader }
(*----------------------------------------------------------------------------*)
constructor TYfantisReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.Yfantis');
end;
(*----------------------------------------------------------------------------*)
function TYfantisReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 24112011

  Y := Copy(S, 5, 4);
  M := Trim(Copy(S, 3, 2));
  D := Trim(Copy(S, 1, 2));
  Result := EncodeDate(
                       StrToInt(Y),
                       StrToInt(M),
                       StrToInt(D)
                       );
end;



initialization
  FileDescriptors.Add(TYfantisDescriptor.Create);

end.

