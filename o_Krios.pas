unit o_Krios;

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
  ,uStringHandlingRoutines
  ;


type
(*----------------------------------------------------------------------------*)
  TKriosDescriptor = class(TFileDescriptor)
  protected
    procedure AddFileItems(); override;
  public
    constructor Create(); override;
  end;
(*----------------------------------------------------------------------------*)
 TKriosReader = class(TPurchaseReader)
 protected
   function  DocStrToDate(S: string): TDate; override;
   procedure LoadFromFile(); override;
 public
   constructor Create(Manager: TInputManager; Title: string); override;
 end;

implementation

{ TKriosDescriptor }
(*----------------------------------------------------------------------------*)
constructor TKriosDescriptor.Create;
begin
  inherited;

  FName            := 'Input.Descriptor.KRIOS';
  FFileName        := 'ΚΡΙΟΣ\*.txt';
  FKind            := fkFixedLength;
  FSchema          := fsSameLine;
  FSeparationMode  := smNone;

  FIsMultiSupplier := False;
  FAFM             := '094188840';

//  FIsOEM           := True;
//  FIsUnicode       := True;
//  FIsANSI          := True;

  FNeedsMapGln     := False;

  FDocTypeMap.Add('1=ΤΙΜ');
  FDocTypeMap.Add('2=ΤΔΑ');
  FDocTypeMap.Add('3=ΔΑΠ');
  FDocTypeMap.Add('4=ΠΕΠ');
  FDocTypeMap.Add('5=ΠΕΚ');
  FDocTypeMap.Add('12=ΠΕΠ');

// Νέες μονάδες μέτρησης από SAP.
  FMeasUnitMap.Add('ΚΙΛ=ΚΙΛ');
  FMeasUnitMap.Add('ΤΕΜ=ΤΕΜ');
  FMeasUnitMap.Add('ΚΙΒ=ΚΙΒ');

end;
(*----------------------------------------------------------------------------*)
procedure TKriosDescriptor.AddFileItems;
begin
  inherited;

  { master }
  FItemList.Add(TFileItem.Create(itDate        ,1  ,1    ,10)); //*
  FItemList.Add(TFileItem.Create(itDocType     ,1  ,17   ,2));  //*
  FItemList.Add(TFileItem.Create(itDocId       ,1  ,27   ,6));  //*
  FItemList.Add(TFileItem.Create(itDocChanger  ,1  ,24   ,9));  //*
  FItemList.Add(TFileItem.Create(itGLN         ,1  ,48   ,2));  //*


  { detail }
  FItemList.Add(TFileItem.Create(itCode        ,2  ,79  ,9)); //*
  FItemList.Add(TFileItem.Create(itQty         ,2  ,103  ,9)); //*
  FItemList.Add(TFileItem.Create(itPrice       ,2  ,119  ,9)); //*
  FItemList.Add(TFileItem.Create(itVAT         ,2  ,157  ,5));  //*    // percent
  FItemList.Add(TFileItem.Create(itDisc        ,2  ,130  ,7)); //*    // disc value
  FItemList.Add(TFileItem.Create(itLineValue   ,2  ,143  ,10)); //*    // Qnt * Price
  FItemList.Add(TFileItem.Create(itMeasUnit    ,2  ,163  ,3));  //*

end;


{ TKriosReader }
(*----------------------------------------------------------------------------*)
constructor TKriosReader.Create(Manager: TInputManager; Title: string);
begin
  inherited Create(Manager, Title);
  FDescriptor := FileDescriptors.Find('Input.Descriptor.KRIOS');
end;
(*----------------------------------------------------------------------------*)
function TKriosReader.DocStrToDate(S: string): TDate;
var ADay, AMonth, AYear : word;
    p : integer;
    ss : string;
begin
  // 1/2/2017
  s := Trim(s);
  p := pos('/', s);
  ADay   := StrToInt(LeftString(s, p-1));
  ss := RightString(s, Length(s) - p);
  p := pos('/', ss);
  AMonth := StrToInt(LeftString(ss, p-1));
  AYear  := StrToInt(RightString(s, 4));

  Result := EncodeDate(AYear, AMonth, ADay);


// 04/01/2016
//  AYear := StrToInt(RightString(S, 4));
// Από τo string αφαιρούμε το τελευταίο κομμάτι του έτους μαζί με την κάθετο.
//  S := LeftString(S, Length(S)-5);
//  p := pos('/', S);
//  ADay := StrToInt(LeftString(S, p-1));
//  AMonth := StrToInt(RightString(S, Length(S)-p));
//  Result := EncodeDate(AYear, AMonth, ADay);
end;

(*----------------------------------------------------------------------------*)
procedure TKriosReader.LoadFromFile();
//var
//  SrcText: PWideChar;
//  DstText: PAnsiChar;
begin
  DataList.LoadFromFile(FFileName, TEncoding.Unicode);

  if (FDescriptor.IsOem) then
//    DataList.Text := Utls.OemToAnsi(DataList.Text)
    DataList.Text := OemToAnsi(DataList.Text)
  else if (FDescriptor.IsUnicode) then
    DataList.Text := UTF8ToANSI(DataList.Text);
//  else if (FDescriptor.IsANSI) then begin
//    SrcText := PWideChar(DataList.Text);
//    CharToOem(SrcText, DstText);
//    DataList.Text := AnsiToOEM(DstText);
//  end;

  FTotal := DataList.Count;
  //FManager.Log(Self, DataList.Text);  //y print statement to check

end;
(*---------------------------------------------------------------------------- *)



initialization
  FileDescriptors.Add(TKriosDescriptor.Create);

end.
