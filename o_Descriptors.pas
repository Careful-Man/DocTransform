unit o_Descriptors;


interface

uses
   Windows
  ,SysUtils
  ,Classes
  ,Controls
  ,Forms
  ,Contnrs
  ,Db

  ;



(*
     -������� ���� ������� ��� TFileDescriptor ��� ���� ���� Input �������
     -��� ���� ���� ��� �������� ��� ��� initialization section ���
      ������ Create ��� ��� ������ ���� FileDescriptors.Add(....)
    -���� Create ��� ���� TFileDescriptor ������ ���� ��� FSchema
       ��. FSchema := fsFreeText;
    -�� ���� TFileDescriptor ������ override ��� AddFileItems()
      ���� ����������� �� TFileItem ����������� ��� �� ������ ����
      ���������� �� ������ input, ��� �� ������ ���� FItemList.Add()
      ��.   FItemList.Add(TFileItem.Create(itAFM,  2, 17, 9));

end;

 *)

type
  TFileKind = (
       fkFixedLength
      ,fkDelimited

  );
  { ��� ���� ��� ������ ����� ��� format ��� ������� import}
  TFileSchema = (
     fsNone
    ,fsFreeText              { ���� ��� �������� ��� ��� ���������� ���������, ��� ����� ����� ������������ }
    ,fsHeaderDetail          { ���� ��� ����� ��� ������ �� header ��� ������ ���� ��� detail ������� - Valid Separation Modes = EmptyLine, Marker }
    ,fsSameLine              { ���� ���� ���� ������ ���� ���� ��� header ��� detail ����������� Valid Separation Modes = None, �������� ��� �������������� ������ ������ ������� }
  );

  { ������� ������� ���� ��� master-detail ������� (������������) }
  TSeparationMode = (
     smNone                  { valid : SameLine }
    ,smEmptyLine             { valid : HeaderDetail }
    ,smMarker                { valid : HeaderDetail }
  );

  { ����� ����������� ��� input ������ ��� ���� ����������� ��������-dato-���������� }
  TInfoType = (
    itAFM
   ,itDate
   ,itDocType
   ,itDocId         //
   ,itDocChanger    // �� SameLine �����, ����� ���� ������������ ������, �������������� ���� ��� ���� ��� ���� ������� ������� ��������� ������ ������
   ,itGLN           // ������� ���������������
   ,itPayType
   ,itRelDoc
   ,itSupCode
   ,itAlterDoc


   ,itCode
   ,itBarcode
   ,itQty
   ,itPrice
   ,itVAT
   ,itVAT2  (* ������ ��� ��� Elbisco, �� ������������� ��� ������� ����� ���.
               ��� ������� ���� �� ����� ��� ��� ��� �� �������, ���� ������ �� �����.
               ��� ������� ��� �������, ������ �� �������.                            *)

   ,itDisc
   ,itDisc2
   ,itDisc3
//   ,itSpecialTax
//   ,itSpecialTaxAlcohol
//   ,itSpecialTaxRecycle
   ,itLineValue
   ,itMeasUnit
   ,itMeasUnitRelation
  );





  TLineKind = (
    lkNone,
    lkOnEmptyLine,
    lkOnMasterLine,
    lkOnDetailLine
  );



(*----------------------------------------------------------------------------*)
  { �������������� ���� ���� �����������, �� TInfoType.itAFM
    �� �������� ����������� ���������� ��� ������, ������
    �� ���� ������, ���� ������, ���. ��� �� ����� ��� }
  TFileItem = class(TObject)
  private
    FInfoType   : TInfoType;
    FLine       : Integer;
    FPosition   : Integer;
    FLength     : Integer;
  public
    constructor Create(InfoType: TInfoType; Line, Position: Integer; Length: Integer = 0);

    property InfoType : TInfoType read FInfoType;
    property Line     : Integer read FLine;
    property Position : Integer read FPosition;
    property Length   : Integer read FLength;
  end;

(*----------------------------------------------------------------------------*)
  { ���������� ��� ������ input.
    ���� ��� �����, ��� ItemList, ��� �������� TFileItem }
  TFileDescriptor = class(TPersistent)
  protected
    FSchema                  : TFileSchema;
    FSeparationMode          : TSeparationMode;
    FKind                    : TFileKind;
    FMasterMarker            : string;
    FDetailMarker            : string;
    FFileName                : string;

    FFileNameDetail          : string;

    FName                    : string;
    FAFM                     : string;
    FDelimiter               : Char;

    FDocTypeMap              : TStringList;      { ������������ ����� ������������ ���� ��� �� �� ���� ���}
    FPayModeMap              : TStringList;      { ������������ ������ �������� }
    FMeasUnitMap             : TStringList;      { ������������ ������� �������� }
    FGLNMap                  : TStringList;

    FInitialEmpyLine         : Boolean;

    FItemList                : TObjectList;
    FIsOem                   : Boolean;
    FIsUniCode               : Boolean;
    FIsANSI                  : Boolean;
    FIsMultiSupplier         : Boolean;

    FNeedsMeasUnitConversion : Boolean;          { Convert from BOX to single article }
    FNeedsMapGln             : Boolean;
    FNeedsMapPayMode         : Boolean;

    FFileMask                : string;           { Mask for multiple files needing merging }
    FNeedsFileMerge          : boolean;          { In case I want to merge multiple files into one }

    procedure AddFileItems(); virtual; abstract;
  public
    constructor Create(); virtual;
    destructor Destroy; override;

    function FindFileItem(InfoType: TInfoType): TFileItem;

    property Schema                  : TFileSchema read FSchema;              { ������ ����� ��� format ��� ������� import }
    property SeparationMode          : TSeparationMode read FSeparationMode;  { ������ ������� ��� master-detail ������� }
    property Kind                    : TFileKind read FKind;
    property FileName                : string read FFileName;                 { ����� ������� input }

    property FileNameDetail          : string read FFileNameDetail;           { ����� ������� input �� detail ��������}

    property FileMask                : string read FFileMask;
    property NeedsFileMerge          : boolean read FNeedsFileMerge default False;

    property IsOem                   : Boolean read FIsOem;
    property IsANSI                  : Boolean read FIsANSI;
    property IsUnicode               : Boolean read FIsUnicode;
    property Name                    : string read FName;
    property AFM                     : string read FAFM;                      { ��� ����������-������}
    property Delimiter               : Char read FDelimiter;
    property MasterMarker            : string read FMasterMarker;
    property DetailMarker            : string read FDetailMarker;
    property InitialEmptyLine        : Boolean read FInitialEmpyLine;
    property IsMultiSupplier         : Boolean read FIsMultiSupplier;

    property NeedsMeasUnitConversion : Boolean read FNeedsMeasUnitConversion;
    property NeedsMapGln             : Boolean read FNeedsMapGln;
    property NeedsMapPayMode         : Boolean read FNeedsMapPayMode;

    property ItemList                : TObjectList read FItemList;
    property DocTypeMap              : TStringList read FDocTypeMap;
    property PayModeMap              : TStringList read FPayModeMap;
    property MeasUnitMap             : TStringList read FMeasUnitMap;
    property GLNMap                  : TStringList read FGLNMap;
  end;
(*----------------------------------------------------------------------------*)
  TVivartiaDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;


(*----------------------------------------------------------------------------*)
  { �� ������ ��� ����������� ������� input }
  // �������: ��� ������� ���� Add() ��� ���������� Free,
  //          ����� �� ������������� ���� ��� � �����.
  // ������� 2: H ����� ���� ����� singleton. ��� ����������
  //            �� ������������� �����������. ������ ���
  //            ����������� ���� global ��������� FileDescriptors
  TFileDescriptors = class(TObject)
  private
    FList: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(Descriptor: TFileDescriptor);
    function  Find(Name: string): TFileDescriptor;
  end;


var
  FileDescriptors: TFileDescriptors = nil;  // ������ �����������

implementation

{ TFileItem }

constructor TFileItem.Create(InfoType: TInfoType; Line, Position, Length: Integer);
begin
  inherited Create;

  FInfoType      := InfoType;
  FLine          := Line;
  FPosition      := Position;
  FLength        := Length;
end;

{ TFileDescriptor }

constructor TFileDescriptor.Create;
begin
  inherited Create;

  FItemList     := TObjectList.Create(True);
  FDocTypeMap   := TStringList.Create;
  FPayModeMap   := TStringList.Create;
  FMeasUnitMap  := TStringList.Create;
  FGLNMap       := TStringList.Create;

  AddFileItems();
end;

destructor TFileDescriptor.Destroy;
begin
  FGLNMap.Free;
  FMeasUnitMap.Free;
  FPayModeMap.Free;
  FDocTypeMap.Free;
  FItemList.Free;
  inherited;
end;



function TFileDescriptor.FindFileItem(InfoType: TInfoType): TFileItem;
var
  i : Integer;
begin
  Result := nil;

  for i := 0 to FItemList.Count - 1 do
    if TFileItem(FItemList[i]).InfoType = InfoType then
    begin
      Result := TFileItem(FItemList[i]);
      Exit;
    end;

end;

{ TVivartiaDescriptor }

constructor TVivartiaDescriptor.Create;
begin
  inherited;
  FSchema := fsFreeText;
end;

procedure TVivartiaDescriptor.AddFileItems;
begin
  FItemList.Add(TFileItem.Create(itAFM,  2, 17, 9));
  FItemList.Add(TFileItem.Create(itDate, 2, 45, 8));
  //
  //
end;



{ TFileDescriptors }


constructor TFileDescriptors.Create;
begin
  inherited;
  FList := TObjectList.Create(True);
end;

destructor TFileDescriptors.Destroy;
begin
  FList.Free;
  inherited;
end;

function TFileDescriptors.Find(Name: string): TFileDescriptor;
var
  i : Integer;
begin
  Result := nil;

  for i := 0 to FList.Count - 1 do
   if AnsiSameText(Name, TFileDescriptor(FList[i]).Name) then
   begin
     Result := TFileDescriptor(FList[i]);
     Break;
   end;
end;

procedure TFileDescriptors.Add(Descriptor: TFileDescriptor);
begin
  if (Find(Descriptor.Name) = nil) and (FList.IndexOf(Descriptor) = -1) then
    FList.Add(Descriptor);
end;



initialization
  FileDescriptors := TFileDescriptors.Create;
//  FileDescriptors.Add(TVivartiaDescriptor.Create);

finalization
  FreeAndNil(FileDescriptors);


end.
