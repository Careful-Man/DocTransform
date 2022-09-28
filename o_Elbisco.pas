unit o_Elbisco;

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
  TElbiscoDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TElbiscoReader = class(TPurchaseReader)
 protected
   FCon : TADOConnection;
   function DocStrToDate(S: string): TDate; override;
   function GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function GetPrice: Double; override;
   function GetQty: Double; override;
   function GetLineValue: Double; override;
   function GetVAT(MatCode: string): string; override;

 public
   function Select(SqlText: string): TDataset;
   constructor Create(Manager: TInputManager; Title: string); override;
 end;

var ASupMatCode : string;

implementation

{ TElbiscoDescriptor }
(*----------------------------------------------------------------------------*)
constructor TElbiscoDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.ELBISCO';
  FFileName        := 'ELBISCO\EDI_0026008_��������*.txt';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  //FMasterMarker    := 'H';
  //FDetailMarker    := 'D';
  FAFM             := '094207902';
  FNeedsMapGln     := True;

  FDocTypeMap.Add('E00=���');
  FDocTypeMap.Add('I00=���');
  FDocTypeMap.Add('I01=���');
  FDocTypeMap.Add('I02=���');
  FDocTypeMap.Add('I03=���');
  FDocTypeMap.Add('I04=���');
  FDocTypeMap.Add('I05=���');

  FMeasUnitMap.Add('PCS=���');
  FMeasUnitMap.Add('BOX=���');


  FGLNMap.Add('0011158=1');     //    ������� 18
  FGLNMap.Add('0013920=2');     //    ��������� 1
  FGLNMap.Add('0013921=3');     //    ���������� 46
  FGLNMap.Add('0013928=5');     //    25 ������� 113-115
  FGLNMap.Add('0013923=6');     //    ������� 38 & ������
  FGLNMap.Add('0013922=7');     //    �������� 92
  FGLNMap.Add('0013924=8');     //    �������� 12
  FGLNMap.Add('0013925=9');     //    �������� 154
  FGLNMap.Add('0013926=10');    //    ��� ������
  FGLNMap.Add('0013929=12');    //    ������� 6
  FGLNMap.Add('0013930=13');    //    ��������� 14
  FGLNMap.Add('0018497=14');    //    27����.���/�����-����������
  FGLNMap.Add('0020660=15');    //    ���������� 27 & ����
  FGLNMap.Add('0024951=16');    //    ������� ���������
  FGLNMap.Add('0026812=17');    //    ������ 43
  FGLNMap.Add('0027015=18');    //    �������� & ����������� �����
  FGLNMap.Add('0029740=19');    //    ��������������� 5
  FGLNMap.Add('0030582=20');    //    ��������� 6
  FGLNMap.Add('0033144=21');    //    �. ���������� 9 ������
  FGLNMap.Add('0035297=22');    //    ������� 80 ���������
  FGLNMap.Add('0013930=23');    //    �������� 37 ���������
  FGLNMap.Add('0035788=23');    //    �������� 37 ���������
  FGLNMap.Add('0037069=24');    //    ������ 109 ���������
  FGLNMap.Add('0044098=25');    //    ���������� 19 �����������
  FGLNMap.Add('0044634=26');    //    ������
  FGLNMap.Add('0026008=99');    //    14��� ������������-���������




end;
(*----------------------------------------------------------------------------*)
procedure TElbiscoDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate       ,1  ,71   ,8));
  FItemList.Add(TFileItem.Create(itDocType    ,1  ,62   ,4));
  FItemList.Add(TFileItem.Create(itDocId      ,1  ,34   ,15));
  FItemList.Add(TFileItem.Create(itDocChanger ,1  ,4    ,15));
  FItemList.Add(TFileItem.Create(itGLN        ,1  ,151  ,10));    // GLN

  // itRelDoc = itDocType + itDocId

  { detail }
  FItemList.Add(TFileItem.Create(itCode              ,2  ,303  ,15));        // ����� lookup select
//  FItemList.Add(TFileItem.Create(itBarcode           ,2  ,289  ,14));
  FItemList.Add(TFileItem.Create(itQty               ,2  ,369  ,10));
  FItemList.Add(TFileItem.Create(itPrice             ,2  ,339  ,15));
  FItemList.Add(TFileItem.Create(itVAT               ,2  ,214  ,3));         // percent
  FItemList.Add(TFileItem.Create(itVAT2              ,2  ,232  ,3));         // percent
  FItemList.Add(TFileItem.Create(itDisc              ,2  ,199  ,15));        // disc value
  FItemList.Add(TFileItem.Create(itLineValue         ,2  ,318  ,15));
  FItemList.Add(TFileItem.Create(itMeasUnit          ,2  ,379  ,3));
  FItemList.Add(TFileItem.Create(itMeasUnitRelation  ,2  ,382  ,10));
end;


{ TElbiscoReader }
(*----------------------------------------------------------------------------*)
constructor TElbiscoReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.ELBISCO');
end;
(*----------------------------------------------------------------------------*)
function TElbiscoReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

  function GetMatCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
  begin
    Result  := False;

    MatCode := '';
    MatAA   := -1;

  //  if tblMaterial.Locate('SupMatCode', SupMatCode, []) then
    if tblMaterial.Locate('SupMatCode;SupCode', VarArrayOf([SupMatCode, SupCode]), []) then
    begin
      MatCode := tblMaterial.FieldByName('MatCode').AsString;
      MatAA   := tblMaterial.FieldByName('MatAA').AsInteger;

      Result := True;
    end;

  end;

//var OriginalSupMatCode : string;

begin
  Result := False;

//  OriginalSupMatCode := SupMatCode;
// ������������� ������� ��� �� stand
  if (SupMatCode = '105012') or (SupMatCode = '105026') or (SupMatCode = '105029')
  or (SupMatCode = '105038') or (SupMatCode = '105042') or (SupMatCode = '105043')
  or (SupMatCode = '105045') or (SupMatCode = '105048') or (SupMatCode = '105049')
  or (SupMatCode = '105057') or (SupMatCode = '105061') or (SupMatCode = '105064')
  or (SupMatCode = '105066') or (SupMatCode = '105068') or (SupMatCode = '105070')
  or (SupMatCode = '105071') or (SupMatCode = '105072') or (SupMatCode = '105073')
  or (SupMatCode = '105074') or (SupMatCode = '105079') or (SupMatCode = '105080')
  or (SupMatCode = '105082') or (SupMatCode = '106000') or (SupMatCode = '106040')
  or (SupMatCode = '106041') or (SupMatCode = '106043') or (SupMatCode = '106044')
  or (SupMatCode = '107010') or (SupMatCode = '107011') or (SupMatCode = '107012')
  or (SupMatCode = '107040') or (SupMatCode = '107060') or (SupMatCode = '107071')
  or (SupMatCode = '107072')
  then
    SupMatCode  := '105040';

// ������������� ������� ��� �������� SOFT COOKIES ������-���-��� 160��
//  if (SupMatCode = '110200') then      // ������ �� �������� !!
//    SupMatCode  := '110209';

// ������������� ������� ��� �������� SOFT COOKIES ������-���-��� 160��
  if (SupMatCode = '110209') then
    SupMatCode  := '110200';

// ������������� ������� ��� GOODY ������� 185�� ��������
  if (SupMatCode = '110228') then
    SupMatCode  := '110221';

// ������������� ������� ��� �������� �������� ���� 250�� (-0,20�)
  if (SupMatCode = '110299') then
    SupMatCode  := '110290';

// ������������� ������� ��� D�G�S��V� C�����S ������� ������ 220��
//  if (SupMatCode = '110339') then
//    SupMatCode  := '110330';

// ������������� ������� ��� D�G�S��V� C�����S ������� ������ 220��
  if (SupMatCode = '110339') then
    SupMatCode  := '111040';

// ������������� ������� ��� �������� SOFT COOKIES ������-���� 160��
  if (SupMatCode = '110409') then
    SupMatCode  := '110400';

//// ������������� ������� ��� D�G�S��V� C�����S 3���  �������� 220��
//  if (SupMatCode = '110429') then
//    SupMatCode  := '110420';
//

// ������������� ������� ��� D�G�S��V� C�����S 3���  �������� 220��
//  if (SupMatCode = '110429') then
//    SupMatCode  := '111080';

// ������������� ������� ��� ������� 100% �� �� ���� �������� 160��
  if (SupMatCode = '110519') then
    SupMatCode  := '110510';

// ������������� ������� ��� D�G�S��V� C�����S ���� ����� ��������� 220��
  if (SupMatCode = '110829') then
    SupMatCode  := '110820';

// ������������� ������� ��� GOODY �������� 175�� ��������
  if (SupMatCode = '110919') then
    SupMatCode  := '110910';

// ������������� ������� ��� D�G�S��V� C�����S �������� 220��
  if (SupMatCode = '111019') then
    SupMatCode  := '111010';

// ������������� ������� ��� D�G�S��V� C�����S �������� 250��
  if (SupMatCode = '111029') then
    SupMatCode  := '111020';

// ������������� ������� ��� D�G�S��V� C�����S ����� ������ �������� 250��
  if (SupMatCode = '111069') then
    SupMatCode  := '111060';

// ������������� ������� ��� �������� ������ �.�.�. 1�� (-0,30�)
  if (SupMatCode = '111708') then
    SupMatCode  := '111701';

// ������������� ������� ��� �������� ������ ������ 1�� (-0,30�)
  if (SupMatCode = '111739') then
    SupMatCode  := '111730';

// ������������� ������� ��� �������� ������ ������� 1�� (-0,25�)
  if (SupMatCode = '111797') then
    SupMatCode  := '111792';

// ������������� ������� ��� ������  �������� �.�.� ����� �������� 1��
  if (SupMatCode = '111809') then
    SupMatCode  := '111800';

// ������������� ������� ��� �������� ������ ����� ������ 1�� (-0,30�)
  if (SupMatCode = '111898') then
    SupMatCode  := '111891';

// ������������� ������� ��� ������� ����� ����� ��� 200�� ��������
  if (SupMatCode = '111929') then
    SupMatCode  := '111920';

// ������������� ������� ��� ����.���.�����-�������
  if (SupMatCode = '111939') then
    SupMatCode  := '111931';

// ������������� ������� ��� ������� ������ & ������� BAN �������� 230��
  if (SupMatCode = '111959') then
    SupMatCode  := '111950';

// ������������� ������� ��� ������� ������ & ������� ��� �������� 230��
  if (SupMatCode = '111989') then
    SupMatCode  := '111980';

// ������������� ������� ��� ������� ������ & ������� ���� �������� 230��
  if (SupMatCode = '111999') then
    SupMatCode  := '111990';

// ������������� ������� ��� �������� ������ �.�.� 1��
  if (SupMatCode = '113009') then
    SupMatCode  := '113000';

// ������������� ������� ��� ������ �.�.�  �������� 5��
  if (SupMatCode = '113029') then
    SupMatCode  := '113020';

// ������������� ������� ��� C�����S ���&����� 175�� ��������
  if (SupMatCode = '113519') then
    SupMatCode  := '113510';

// ������������� ������� ��� SOFT KINGS ���� 180��
  if (SupMatCode = '114327') then
    SupMatCode  := '114322';

// ������������� ������� ��� C�����S BITES �� ����.��� ��� 70��
  if (SupMatCode = '114459') then
    SupMatCode  := '114450';

// ������������� ������� ��� SOFT KINGS CHOCO+STRAWBERRY 180��
  if (SupMatCode = '114717') then
    SupMatCode  := '114710';

// ������������� ������� ��� SOFT KINGS COOKIE CHOCO 45��
  if (SupMatCode = '116109') then
    SupMatCode  := '116100';

// ������������� ������� ��� SOFT KINGS COOKIE DARK CHOCO 45��
  if (SupMatCode = '116119') then
    SupMatCode  := '116110';

// ������������� ������� ��� SOFT KINGS COOKIE TRIPLE CHOCO 45��
  if (SupMatCode = '116129') then
    SupMatCode  := '116120';

// ������������� ������� ��� SOFT KINGS COOKIE CARAM & PECAN 45��
  if (SupMatCode = '116139') then
    SupMatCode  := '116130';

// ������������� ������� ��� SOFT KINGS COOKIE DARK CHOCO 180��
  if (SupMatCode = '116219') then
    SupMatCode  := '116210';

// ������������� ������� ��� SOFT KINGS COOKIE CHOCO 180��
  if (SupMatCode = '116209') then
    SupMatCode  := '116200';

// ������������� ������� ��� SOFT KINGS COOKIE TRIPLE CHOCO 180��
  if (SupMatCode = '116239') then
    SupMatCode  := '116230';

// ������������� ������� ��� SOFT KINGS COCONUT-WHITE CHOCO 180��
  if (SupMatCode = '116259') then
    SupMatCode  := '116250';

// ������������� ������� ��� ������� �������� ���.20�� (2+1) ��������
  if (SupMatCode = '117118') then
    SupMatCode  := '117111';

// ������������� ������� ��� ���� ����� �������� 27��
  if (SupMatCode = '117259') then
    SupMatCode  := '117250';

// ������������� ������� ��� �����.����� �� ����-��� 270��
  if (SupMatCode = '118139') then
    SupMatCode  := '118130';

// ������������� ������� ��� �����.����� �� ���� 270��
  if (SupMatCode = '118129') then
    SupMatCode  := '118120';

// ������������� ������� ��� �������� ������ ���� ������ 500�� (-0,30�)
  if (SupMatCode = '119459') then
    SupMatCode  := '119450';

// ������������� ������� ��� ������ �������� ���� ������ 500�� (-0,25�)
  if (SupMatCode = '119469') then
    SupMatCode  := '119460';

// ������������� ������� ��� D�G�S��V� C�����S �������� ��� CRANBERRY 40��
  if (SupMatCode = '120129') then
    SupMatCode  := '120120';

// ������������� ������� ��� D�G�S��V� C�����S �������� ��� ���� ������ 40��
  if (SupMatCode = '120529') then
    SupMatCode  := '120520';

// ������������� ������� ��� ��.���-���� �������� ��.������ 225��
  if (SupMatCode = '122772') then
    SupMatCode  := '122771';

// ������������� ������� ��� GOODY ������-�������� 185�� ��������
  if (SupMatCode = '124419') then
    SupMatCode  := '124410';

// ������������� ������� ��� ������� ����� �������� 200�� (-0,25�)
  if (SupMatCode = '128849') then
    SupMatCode  := '128840';

// ������������� ������� ��� ������� ����� �������� 200�� (-0,15E)
  if (SupMatCode = '128859') then
    SupMatCode  := '128850';

// ������������� ������� ��� C��C�-�L��� �������� 35��
  if (SupMatCode = '129019') then
    SupMatCode  := '129050';

// ������������� ������� ��� GOODY �������� 185�� ��������
  if (SupMatCode = '130319') then
    SupMatCode  := '133310';

// **** Conflict with the previous ^^^
// ������������� ������� ��� ��.���-���� �������� 225��
//  if (SupMatCode = '133619') then
//    SupMatCode  := '133630';

// ������������� ������� ��� ��.���-���� �������� 225��
  if (SupMatCode = '133638') then
    SupMatCode  := '133630';

// ������������� ������� ��� ��.���-���� �������� 225��
  if (SupMatCode = '133639') then
    SupMatCode  := '133630';

// ������������� ������� ��� ���-���� �������� �������� 225��
  if (SupMatCode = '133679') then
    SupMatCode  := '133670';

// ������������� ������� ��� ���-���� �������� ����� ������ 225��
  if (SupMatCode = '133689') then
    SupMatCode  := '133680';

// ������������� ������� ��� ���-���� �������� �������� 195��
  if (SupMatCode = '133809') then
    SupMatCode  := '133800';

// ������������� ������� ��� C�����S BITES �� �������� 70��
  if (SupMatCode = '134859') then
    SupMatCode  := '134850';

// ������������� ������� ��� C�����S BITES �� ������ ����� 70��
  if (SupMatCode = '134869') then
    SupMatCode  := '134860';

// ������������� ������� ��� C�����S BITES ����� �������� 70�� ��������
  if (SupMatCode = '134889') then
    SupMatCode  := '134880';

// ������������� ������� ��� C�����S C��C�+C��C� C��� 175�� �������
  if (SupMatCode = '134919') then
    SupMatCode  := '134910';

// ������������� ������� ��� C�����S C��C�L��� C��� 175�� ��������
  if (SupMatCode = '135019') then
    SupMatCode  := '135010';

// ������������� ������� ��� C�����S ������ �������� 175�� ��������
  if (SupMatCode = '137019') then
    SupMatCode  := '137010';

// ������������� ������� ��� ��R�� CR�C��RS 200�� ��������
  if (SupMatCode = '140939') then
    SupMatCode  := '140910';

// ������������� ������� ��� �������� ��������� ���� 500��
  if (SupMatCode = '142019') then
    SupMatCode  := '142010';

// ������������� ������� ��� �������� ��������� ������ 500��
  if (SupMatCode = '143019') then
    SupMatCode  := '143010';

// ������������� ������� ��� ��� 40��. ��������
  if (SupMatCode = '143319') then
    SupMatCode  := '143320';

// ������������� ������� ��� �L��� ���� ����� 125�� ��������
  if (SupMatCode = '150019') then
    SupMatCode  := '150012';

// ������������� ������� ��� �L��� ���� ����� 250�� �� �����
  if (SupMatCode = '150029') then
    SupMatCode  := '150020';

// ������������� ������� ��� �L��� ���� ����� ������ 100��
  if (SupMatCode = '150519') then
    SupMatCode  := '150510';

// ������������� ������� ��� �L��� ���� ������� 180�� ��������
  if (SupMatCode = '150129') then
    SupMatCode  := '150120';

// ������������� ������� ��� �L��� ���� ����� 250�� (-0,10�)
  if (SupMatCode = '150419') then
    SupMatCode  := '150410';

// ������������� ������� ��� �������� ���� ����� 375�� (-0,30�)
  if (SupMatCode = '153019') then
    SupMatCode  := '153010';

// ������������� ������� ��� �������� ���� ����� 250��
  if (SupMatCode = '153088') then
    SupMatCode  := '153081';

// ������������� ������� ��� �������� ���� ��.������ 180��
  if (SupMatCode = '153327') then
    SupMatCode  := '153322';

// ������������� ������� ��� �������� ���� ������ 400��
  if (SupMatCode = '153489') then
    SupMatCode  := '153480';

// ������������� ������� ��� �L��� ���� ������ 180��
  if (SupMatCode = '155019') then
    SupMatCode  := '155010';

// ������������� ������� ��� ELITE ���� ������ 360��
  if (SupMatCode = '155039') then
    SupMatCode  := '155030';

// ������������� ������� ��� ELITE ��������� �� ������� 250��
  if (SupMatCode = '155109') then
    SupMatCode  := '155100';

// ������������� ������� ��� ELITE ��������� �� ������� 250��
  if (SupMatCode = '155209') then
    SupMatCode  := '155200';

// ������������� ������� ��� ELITE ��������� �� ������� 250��
  if (SupMatCode = '155309') then
    SupMatCode  := '155300';

// ������������� ������� ��� ELITE ���� ���������� 180��
  if (SupMatCode = '155509') then
    SupMatCode  := '155500';

// ������������� ������� ��� ��������� ELITE �����. ��.������ 250�� (-0,20�)
  if (SupMatCode = '155928') then
    SupMatCode  := '155927';

// ������������� ������� ��� ELITE CRACK.����-��� 105��
  if (SupMatCode = '159009') then
    SupMatCode  := '159000';

// ������������� ������� ��� ELITE CRACK.����-��� 105��
  if (SupMatCode = '159109') then
    SupMatCode  := '159100';

// ������������� ������� ��� ELITE CRACK.���.����� 105��
  if (SupMatCode = '159309') then
    SupMatCode  := '159300';

// ������������� ������� ��� ELITE ���� ����� ������ 125���2 (-0,50�)
  if (SupMatCode = '160548') then
    SupMatCode  := '160541';

// ������������� ������� ��� ELITE ���� ����� ������ 125��
  if (SupMatCode = '161519') then
    SupMatCode  := '161510';

// ������������� ������� ��� ELITE CRACK.MINI �����EIAKA ����-��� 50��
  if (SupMatCode = '163109') then
    SupMatCode  := '163100';

// ������������� ������� ��� ELITE CRACK.MINI �����EIAKA PESTO 50��
  if (SupMatCode = '163209') then
    SupMatCode  := '163200';

// ������������� ������� ��� ELITE CRACK.��� ����-����� 105��
  if (SupMatCode = '163959') then
    SupMatCode  := '163950';

// ������������� ������� ��� ELITE CRACK.��� ������ ���� & ������� 105��
  if (SupMatCode = '163939') then
    SupMatCode  := '163930';

// ������������� ������� ��� ELITE CRACK.������ �����& ��� ������� 50��
  if (SupMatCode = '164139') then
    SupMatCode  := '164130';

// ������������� ������� ��� ELITE CRACK.������ �����& ����� ����� 50��
  if (SupMatCode = '164149') then
    SupMatCode  := '164140';

// ������������� ������� ��� ELITE BITES ����� ���.����� 50��
  if (SupMatCode = '164309') then
    SupMatCode  := '164300';

// ������������� ������� ��� ELITE BITES ����� ��������� 50��
  if (SupMatCode = '164409') then
    SupMatCode  := '164400';

// ������������� ������� ��� 2001 ������ 40 ��. ��������
  if (SupMatCode = '173319') then
    SupMatCode  := '173320';

// ������������� ������� ��� 2001 ������ 40 ��. ��������
  if (SupMatCode = '173339') then
    SupMatCode  := '173320';

// ������������� ������� ��� C�����S D�R� ��� 175���2+1 ��� (-1�)
  if (SupMatCode = '806778') then
    SupMatCode  := '806770';

// ������������� ������� ��� �������� ������ �.�.�. 1�� (2+1)
  if (SupMatCode = '811729') then
    SupMatCode  := '811720';

// ������������� ������� ��� GOODY �������� 175���3 (-0,80�)
  if (SupMatCode = '824099') then
    SupMatCode  := '824090';

// ������������� ������� ��� GOODY ������� 185��X3 (-0.80E)
  if (SupMatCode = '824119') then
    SupMatCode  := '824110';

// ������������� ������� ��� GOODY ������� 185��X3 (-0.70E)
  if (SupMatCode = '824159') then
    SupMatCode  := '824150';

// ������������� ������� ��� GOODY �������� 175���3 (-0,70�)
  if (SupMatCode = '824319') then
    SupMatCode  := '824310';

// ������������� ������� ��� ������� ����� �������� 200���2 (-0,80�)
  if (SupMatCode = '828199') then
    SupMatCode  := '828190';

// ������������� ������� ��� ������� ����� �������� 200���2 (-0,50�)
  if (SupMatCode = '828289') then
    SupMatCode  := '828280';

// ������������� ������� ��� ������� ����� �������� 200���2 (-0,70�)
  if (SupMatCode = '828299') then
    SupMatCode  := '828290';

// ������������� ������� ��� ��.���-���� �������� 225���3 (-0,50�)
  if (SupMatCode = '833739') then
    SupMatCode  := '833730';

// ������������� ������� ��� ���-���� �������� �������� 225���3 (-0,50)
  if (SupMatCode = '833759') then
    SupMatCode  := '833750';

// ������������� ������� ��� ���-���� �������� 225���3 (-0,45�)
  if (SupMatCode = '833839') then
    SupMatCode  := '833830';

// ������������� ������� ��� �L��� ���� ����� 125���4 (3+1)
  if (SupMatCode = '850029') then
    SupMatCode  := '850020';

// ������������� ������� ��� �L��� ���� ������� 90���4 (3+1)
  if (SupMatCode = '850118') then
    SupMatCode  := '850111';

// ������������� ������� ��� �L��� ���� ����� ���.����� 250��
  if (SupMatCode = '850179') then
    SupMatCode  := '850170';

// ������������� ������� ��� �L��� ���� ������� ���.����� 180��
  if (SupMatCode = '850189') then
    SupMatCode  := '850180';

// ������������� ������� ��� ELITE ���� ��.��.90���4 (3+1)
  if (SupMatCode = '850289') then
    SupMatCode  := '850280';

// ������������� ������� ��� �L��� ���� ����� ���.����� 125���4 (3+1)
  if (SupMatCode = '850709') then
    SupMatCode  := '850700';

// ������������� ������� ��� �L��� ���� ������� ���.����� 90���4 (3+1)
  if (SupMatCode = '850809') then
    SupMatCode  := '850800';

// ������������� ������� ��� F�R�� ���� ����� 125���4 (3+1)
  if (SupMatCode = '853069') then
    SupMatCode  := '853060';

// ������������� ������� ��� F�R�� ���� �������� 90��X4 (-0,50�)
  if (SupMatCode = '853158') then
    SupMatCode  := '853151';

// ������������� ������� ��� ELITE CRACK.����-��� 105�� (2+1)
  if (SupMatCode = '859009') then
    SupMatCode  := '859000';

// ������������� ������� ��� ELITE CRACK.����-��� 105��X3 (-1E)
  if (SupMatCode = '859029') then
    SupMatCode  := '859020';

    // ������������� ������� ��� ELITE CRACK.����-��� 105�� (2+1)
  if (SupMatCode = '859109') then
    SupMatCode  := '859100';

// ������������� ������� ��� ELITE CRACK.���.����� 105�� (2+1)
  if (SupMatCode = '859309') then
    SupMatCode  := '859300';

// ������������� ������� ��� ELITE ��������� ��������� 240�� (-0.30E)
  if (SupMatCode = '870269') then
    SupMatCode  := '870260';

// ������������� ������� ��� ELITE ��������� �� ������� 250�� (-0.30E)
  if (SupMatCode = '870289') then
    SupMatCode  := '870280';

{ ��� ����������� ����� �� ��������������� �����
//**************************************************************
// �� ������� �������� ���� ��� ����������� 'I03' ���  'I04',
// ����� ���� ���� ��������� ��� ���������� ������ ������ �������������.
  if (GetDocType = 'I03') or (GetDocType = 'I04') then
  begin
    if RightString(SupMatCode, 1) = '9' then
      SupMatCode := ReplaceString(SupMatCode, 6, 1, '0')
    else
    if RightString(SupMatCode, 1) = '8' then
      SupMatCode := ReplaceString(SupMatCode, 6, 1, '1');

// ��� ������� � ������� �� ������� �� ���������� ��.
    if GetMatCode(SupMatCode, SupCode, MatCode, MatAA) = False then
    begin
      if RightString(SupMatCode, 1) = '0' then
        SupMatCode := ReplaceString(SupMatCode, 6, 1, '9')
      else
      if RightString(SupMatCode, 1) = '1' then
        SupMatCode := ReplaceString(SupMatCode, 6, 1, '8');

      Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

    end
    else
      Result := True;

  end
  else
    Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);
//**************************************************************
}

  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);

  if not Result then
{    if SupMatCode = OriginalSupMatCode then
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]))
    else
    if SupMatCode <> OriginalSupMatCode then
      FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s, or %s',
                     [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode, OriginalSupMatCode]));
  ASupMatCode := SupMatCode;}
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
end;
(*----------------------------------------------------------------------------*)
(* ���� ��������� ����� ��� ������ ���� = 0, ��� ��� �� ���� ���� ���� = 0.
   ��� ���� ��� ���������� ���� ��� �� ���� �� ������� ������.                *)
function TElbiscoReader.GetPrice: Double;

  function GetHistoryPrice(MatAA: integer): Double;
  const
    CCS = 'Provider=SQLOLEDB.1;Password=yoda2k;Persist Security Info=True;User ID=sa;Initial Catalog=Afroditi;Data Source=localhost';
  var
    SqlText    : string;
    IniFileName: string;
    Ini        : TIniFile;
    CS         : string;
    Prices     : TDataset;
    APrice     : Double;
    S          : string;
  begin
//    IniFileName := Utls.AppPath + 'Main.ini';
    SetLength(S, 4096);
    SetLength(S, GetModuleFileName(HInstance, PChar(S), Length(S)));
    GetModuleFileName(HInstance, PChar(S), Length(S));
    IniFileName := ExtractFilePath(S) + 'Main.ini';
    Ini         := TIniFile.Create(IniFileName);
    try
      CS        := Ini.ReadString('Main', 'ConnectionString', '');
      if (CS = '') then
      begin
        CS := CCS;
        Ini.WriteString('Main', 'ConnectionString', CS);
      end;
    FCon                  := TADOConnection.Create(nil);
    FCon.Connected        := False;
    FCon.LoginPrompt      := False;
    FCon.ConnectionString := CS;
    FCon.Connected        := True;
    finally
      Ini.Free;
    end;
    SqlText := 'select top 1 d.Date1, l.Price' + LB +
               'from clroot.DocHdPur d with (nolock) join clroot.LItmPurc l with (nolock) on d.AA = l.DocumentAA' + LB +
               'where l.LinkIDNum = ' + IntToStr(MatAA) + LB +
               'and d.SeriesCode in (''���'', ''���'')' + LB +
               'and l.Price <> 0.00' + LB +
               'order by d.Date1 desc';
    Prices := Select(SqlText);
    Prices.Open;
    APrice := Prices.FieldByName('Price').AsFloat;
    Result := APrice;
    FreeAndNil(FCon);
    FreeAndNil(Prices);
  end;

var
  S : string;
  C : boolean;
  R : Double;
begin
  // � ���������� '0' ����� � default ����, ��� ��� ������� ����.
  S := GetStrDef(fiPrice, '0');
//  S := Utls.CommaToDot(S);
//  R := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  S := DotToComma(S);
  R := abs(StrToFloat(S));
  // �� � ���� ������ ����� 0 ��������� ��� ����.
  // �������� ��� �������� ����� ��� �� ������ ���� �� ������ �� ����� � ����.
  // � ����� ���� ����� � ��� �������� ���� ������.
  if R = 0 then
  begin
    FManager.Log(Self, '���� !!!');
    C := GetMaterialCode(ASupMatCode, SupCode, MatCode, MatAA);
    R := GetHistoryPrice(MatAA);
    S := FloatToStr(R);
//    S := Utls.CommaToDot(S);
    S := DotToComma(S);
  end;
  // ������������ ��� ��� �������� ���� ������.
//  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  Result := abs(StrToFloat(S));
end;
(*----------------------------------------------------------------------------*)
function TElbiscoReader.GetQty: Double;
var
  S : string;
begin
  S := GetStrDef(fiQty, '0');
//  S := Utls.CommaToDot(S);
//  Result := abs(StrToFloat(S, Utls.GlobalFormatSettings));
  S := DotToComma(S);
  Result := abs(StrToFloat(S));
end;
(*----------------------------------------------------------------------------*)
function TElbiscoReader.GetLineValue: Double;
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
(* ������ ��� ��� Elbisco, �� ������������� ��� ������� ����� ���.
   ��� ������� ���� �� ����� ��� ��� ��� �� �������, ���� ������ �� �����.
   ��� ������� ��� �������, ������ �� �������.                                *)
(* ��� ��� ELBISCO ��� ���� ������ ����� ��� ������� �� ��� ������ -----------*)
function TElbiscoReader.GetVAT(MatCode: string): string;
 const
   CCS = 'Provider=SQLOLEDB.1;Password=yoda2k;Persist Security Info=True;User ID=sa;Initial Catalog=Afroditi;Data Source=localhost';
 var
  SqlText : string;
  IniFileName: string;
  Ini : TIniFile;
  CS  : string;
  VATCat : TDataset;
  VATVal : Double;
  VAT2   : string;
  TaxCat : string;
  S      : string;
begin
  Result := GetStrDef(fiVAT);
  VAT2 := GetStrDef(fiVAT2);
  if (VAT2 <> '') then
  begin
(* ������ ���� ��� ��� Elbisco, ������ � ��������� ��� ��� ��� ������� ����� �����������,
   ������� �� ��� ��� �� ERP !!! *)
    Result := '';
//    FManager.Log(Self, Format('������������� ��� !!! SupCode: %s, Date1: %s, RelDoc: %s, MatCode: %s',
//                   [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, MatCode]));

  end;
//  Result := '';
  if (Result = '') or (Result = '0.00') then begin
//    IniFileName := Utls.AppPath + 'Main.ini';
    SetLength(S, 4096);
    SetLength(S, GetModuleFileName(HInstance, PChar(S), Length(S)));
    GetModuleFileName(HInstance, PChar(S), Length(S));
    IniFileName := ExtractFilePath(S) + 'Main.ini';
    Ini := TIniFile.Create(IniFileName);
    try
      CS := Ini.ReadString('Main', 'ConnectionString', '');
      if (CS = '') then
      begin
        CS := CCS;
        Ini.WriteString('Main', 'ConnectionString', CS);
      end;
      FCon := TADOConnection.Create(nil);
      FCon.Connected := False;
      FCon.LoginPrompt := False;
      FCon.ConnectionString := CS;
      FCon.Connected := True;
    finally
      Ini.Free;
    end;
    if GetDocDate < StrToDateTime('01/06/2016 00:00:00') then
      TaxCat := '8'
    else
      TaxCat := '0';
    SqlText := 'Select v.VATVal, m.String11 '                                                        + LB +
               'from clroot.InvVAT v join clroot.Material m with (nolock) on v.VATCtgr = m.VATCtgr'  + LB +
               'where m.Code = ' + qs(MatCode) +  LB +
               'and v.TaxCat = ' + TaxCat;
    VATCat := Select(SqlText);
    VATCat.Open;
    VATVal := VATCat.FieldByName('VATVal').AsFloat;
// If Material is changing VAT and DocDate is from 20/05 onwards, VAT becomes 13% instead of 24%.
    if ((VATCat.FieldByName('String11').AsString = '24->13a') and (DocDate >= 2019-05-20)) then
      VATVal := 13.0;

    Result := FloatToStr(VATVal);
    FreeAndNil(FCon);
    FreeAndNil(VATCat);
  end;
end;
(*----------------------------------------------------------------------------*)
function TElbiscoReader.Select(SqlText: string): TDataset;
var
  Q : TAdoQuery;
begin

  Q := TADOQuery.Create(nil);
  Q.Connection := FCon;
  Q.SQL.Text := SqlText;
  Q.SQL.SaveToFile('C:\Users\user\Documents\Projects\Delphi 101\DocTransform\SQL.txt');
  Q.Active := True;
  Result := Q;
end;
(*----------------------------------------------------------------------------*)
function TElbiscoReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 02072012

  Y := Copy(S, 5, 4);
  M := Copy(S, 3, 2);
  D := Copy(S, 1, 2);
  Result := EncodeDate(
                       StrToInt(Y),
                       StrToInt(M),
                       StrToInt(D)
                       );
end;
(*----------------------------------------------------------------------------*)







initialization
  FileDescriptors.Add(TElbiscoDescriptor.Create);

end.
