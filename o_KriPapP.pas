unit o_KriPapP;

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
  ,Variants
//  ,tpk_Utls
  ,o_Descriptors
  ,o_Managers
  ,o_Purchases
  ,uStringHandlingRoutines
  ;


type
(*----------------------------------------------------------------------------*)
  TKriPapPDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TKriPapPReader = class(TPurchaseReader)
 protected
   function  GetMaterialCode(SupMatCode: string; SupCode: string; out MatCode: string; out MatAA: Integer): Boolean; override;
   function  GetLineValue: Double; override;
   function  DocStrToDate(S: string): TDate; override;

 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;

implementation

{ TKrikriPDescriptor }
(*----------------------------------------------------------------------------*)
constructor TKriPapPDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.KRIPAP-P';
  FFileName        := '??????-?\*.TXT';
  FKind            := fkFixedLength;
  //FDelimiter       := '#';
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;
  //FMasterMarker    := 'H';
  //FDetailMarker    := 'D';
  FAFM             := '800177888-2';

//  FIsOem           := True;

  FNeedsMapGln     := True;

  FDocTypeMap.Add('??=???');
  FDocTypeMap.Add('??=???');
  FDocTypeMap.Add('??=???');


  FMeasUnitMap.Add('101=???');
  FMeasUnitMap.Add('???=???');
  FMeasUnitMap.Add('103=???');
  FMeasUnitMap.Add('???=???');
  FMeasUnitMap.Add('???=???');


  FGLNMap.Add('10404=1');     //    ??????? 18
  FGLNMap.Add('24012=1');     //    ??????? 18
  FGLNMap.Add('10405=2');     //    ????????? 1
  FGLNMap.Add('25722=2');     //    ????????? 1
  FGLNMap.Add('10406=3');     //    ?????????? 46
  FGLNMap.Add('25160=3');     //    ?????????? 46
  FGLNMap.Add('11133=5');     //    25 ??????? 113-115
  FGLNMap.Add('25161=5');     //    25 ??????? 113-115
  FGLNMap.Add('10408=6');     //    ??????? 38
  FGLNMap.Add('25719=6');     //    ??????? 38
  FGLNMap.Add('10407=7');     //    ???????? 92
  FGLNMap.Add('24013=7');     //    ???????? 92
  FGLNMap.Add('10409=8');     //    ???????? 12
  FGLNMap.Add('25718=8');     //    ???????? 12
  FGLNMap.Add('10410=9');     //    ???????? 154
  FGLNMap.Add('25720=9');     //    ???????? 154
  FGLNMap.Add('24014=10');    //    ??? ??????
  FGLNMap.Add('11186=12');    //    ??????? 6
  FGLNMap.Add('24015=12');    //    ???????? 6
  FGLNMap.Add('11304=13');    //    ????????? 14 ?????
  FGLNMap.Add('25716=13');    //    ????????? 14 ?????
  FGLNMap.Add('11450=15');    //    ?????????? 27 & ????
  FGLNMap.Add('24016=15');    //    ?????????? 27 & ????
  FGLNMap.Add('11612=16');    //    ??????? ?????????
  FGLNMap.Add('24017=16');    //    ??????? ?????????
  FGLNMap.Add('11718=17');    //    ?????? 43
  FGLNMap.Add('25162=17');    //    ?????? 43
  FGLNMap.Add('11730=18');    //    ???????? & ??????????? ?????
  FGLNMap.Add('11865=19');    //    ??????????????? 5
  FGLNMap.Add('25721=19');    //    ??????????????? 5
  FGLNMap.Add('11899=20');    //    ????????? 6
  FGLNMap.Add('25717=20');    //    ????????? 6
  FGLNMap.Add('12039=21');    //    ?. ?????????? 9 ??????
  FGLNMap.Add('25163=21');    //    ?. ?????????? 9 ??????
  FGLNMap.Add('12159=22');    //    ??????? 80 ?????????
  FGLNMap.Add('25595=22');    //    ??????? 80 ?????????
  FGLNMap.Add('12210=23');    //    ???????? 37 ?????????
  FGLNMap.Add('25863=23');    //    ???????? 37 ?????????
  FGLNMap.Add('12299=24');    //    ?????? 109 ?????????
  FGLNMap.Add('26033=24');    //    ?????? 109 ?????????
  FGLNMap.Add('12667=25');    //    ?????????? 19 ???????????
  FGLNMap.Add('27274=25');    //    ?????????? 19 ???????????
  FGLNMap.Add('12743=26');    //    ?????? ???????? 112 ??????
  FGLNMap.Add('27331=26');    //    ?????? ???????? 112 ??????



end;
(*----------------------------------------------------------------------------*)
procedure TKriPapPDescriptor.AddFileItems;
begin
  inherited;

  { master }
  //FItemList.Add(TFileItem.Create(itAFM,  1, 20));
  FItemList.Add(TFileItem.Create(itDate, 1, 1, 10));
  FItemList.Add(TFileItem.Create(itDocType, 1, 12, 2));
  FItemList.Add(TFileItem.Create(itDocId, 1, 16, 6));
  FItemList.Add(TFileItem.Create(itDocChanger, 1, 12, 10));
  FItemList.Add(TFileItem.Create(itGLN, 1, 23, 5));    // GLN



  // itRelDoc = itDocType + itDocId

  { detail }
  FItemList.Add(TFileItem.Create(itCode, 2, 30, 7));        // ????? lookup select
  //FItemList.Add(TFileItem.Create(itBarcode, 2, 209, 14));
  FItemList.Add(TFileItem.Create(itQty, 2, 91, 10));
  FItemList.Add(TFileItem.Create(itPrice, 2, 102, 10));
  //FItemList.Add(TFileItem.Create(itVAT, 2, 318, 5));          // percent
  //FItemList.Add(TFileItem.Create(itDisc, 2, 11));             // disc value
  FItemList.Add(TFileItem.Create(itLineValue, 2, 102, 10));   // ??? ??? ????? ?????? ???????, ??? ?? ????????????.
  FItemList.Add(TFileItem.Create(itMeasUnit, 2, 77, 3));
end;


{ TKrikriPReader }
(*----------------------------------------------------------------------------*)
constructor TKriPapPReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.KRIPAP-P');
end;
(*----------------------------------------------------------------------------*)
function TKriPapPReader.GetMaterialCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;

  function GetMatCode(SupMatCode, SupCode: string; out MatCode: string; out MatAA: Integer): Boolean;
  begin
    Result := False;

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

begin
  Result := False;

  MatCode := '';
  MatAA   := -1;

//  if tblMaterial.Locate('SupMatCode', SupMatCode, []) then
  if Copy(SupMatCode, 1, 2) ='99' then
    SupMatCode := '01' + Copy(SupMatCode, 3, Length(SupMatCode)-2);
  if tblMaterial.Locate('SupMatCode;SupCode', VarArrayOf([SupMatCode, SupCode]), []) then
  begin
    MatCode := tblMaterial.FieldByName('MatCode').AsString;
    MatAA   := tblMaterial.FieldByName('MatAA').AsInteger;

    Result := True;
  end;


// ????????????? ??????? ???? ??????.
  if (SupMatCode = '0109001') or (SupMatCode = '0109002') or (SupMatCode = '0109003')
  or (SupMatCode = '0109004') or (SupMatCode = '0109005') or (SupMatCode = '0109006')
  or (SupMatCode = '0109007') or (SupMatCode = '0109010') or (SupMatCode = '0109011')
  or (SupMatCode = '0109012') or (SupMatCode = '0109040') or (SupMatCode = '0109041')
  or (SupMatCode = '0109042') or (SupMatCode = '0109043') or (SupMatCode = '0109044')
  or (SupMatCode = '0109045') or (SupMatCode = '0109080') or (SupMatCode = '0109081')
  then
    SupMatCode  := '0109000';

  Result := GetMatCode(SupMatCode, SupCode, MatCode, MatAA);


  if not Result then
//    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
//                   [SupCode, Utls.DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));
    FManager.Log(Self, Format('XXX ERROR: Material Code not found. SupCode: %s, Date1: %s, RelDoc: %s, SupMatCode: %s',
                   [SupCode, DateToStrSQL(DocDate, False), RelDoc, SupMatCode]));

end;
(*----------------------------------------------------------------------------*)
function TKriPapPReader.GetLineValue: Double;
var
  S : string;
begin
  S := FloatToStr(GetPrice * GetQty);
//  S := Utls.CommaToDot(S);
//  Result := StrToFloat(S, Utls.GlobalFormatSettings);
  S := DotToComma(S);
  Result := StrToFloat(S);
end;
(*----------------------------------------------------------------------------*)
function TKriPapPReader.DocStrToDate(S: string): TDate;
var
  Y, M, D: string;
begin
  // 12/ 5/11

  Y := Copy(S, 7, 4);
  M := Trim(Copy(S, 4, 2));
  D := Trim(Copy(S, 1, 2));
  Result := EncodeDate(
                       StrToInt(Y),
                       StrToInt(M),
                       StrToInt(D)
                       );
end;







initialization
  FileDescriptors.Add(TKriPapPDescriptor.Create);

end.
