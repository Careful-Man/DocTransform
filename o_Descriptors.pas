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
     -Γράφεις έναν απόγονο του TFileDescriptor για κάθε τύπο Input αρχείου
     -Πας στον πάτο του εγγράφου και στο initialization section τον
      κάνεις Create και τον δίνεις στην FileDescriptors.Add(....)
    -Στην Create του κάθε TFileDescriptor δίνεις τιμή στο FSchema
       πχ. FSchema := fsFreeText;
    -Σε κάθε TFileDescriptor κάνεις override την AddFileItems()
      όπου δημιουργείς τα TFileItem αντικείμενα που το σύνολο τους
      περιγράφει το αρχείο input, και τα δίνεις στην FItemList.Add()
      πχ.   FItemList.Add(TFileItem.Create(itAFM,  2, 17, 9));

end;

 *)

type
  TFileKind = (
       fkFixedLength
      ,fkDelimited

  );
  { Μας λέει την γενική μορφή του format του αρχείου import}
  TFileSchema = (
     fsNone
    ,fsFreeText              { αυτά που βγαίνουν από τον φορολογικό μηχανισμό, και έχουν μορφή παραστατικού }
    ,fsHeaderDetail          { αυτά που έχουν μια γραμμή το header και αμέσως μετά τις detail γραμμές - Valid Separation Modes = EmptyLine, Marker }
    ,fsSameLine              { αυτά όπου κάθε γραμμή τους έχει και header και detail πληροφορίες Valid Separation Modes = None, σημαίνει οτι παρακολουθούμε αλλαγή πεδίου κωδικού }
  );

  { Ενδειξη αλλαγής ένός σετ master-detail γραμμών (παραστατικού) }
  TSeparationMode = (
     smNone                  { valid : SameLine }
    ,smEmptyLine             { valid : HeaderDetail }
    ,smMarker                { valid : HeaderDetail }
  );

  { τύποι πληροφορίας στα input αρχεία για κάθε διαφορετικό στοιχείο-dato-πληροφορία }
  TInfoType = (
    itAFM
   ,itDate
   ,itDocType
   ,itDocId         //
   ,itDocChanger    // σε SameLine σχήμα, χωρίς κενή διαχωριστική γραμμή, παρακολουθούμε αυτή την τιμή και όταν αλλάζει βάζουμε καινούρια μαστερ γραμμή
   ,itGLN           // κωδικός υποκαταστήματος
   ,itPayType
   ,itRelDoc
   ,itSupCode
   ,itAlterDoc


   ,itCode
   ,itBarcode
   ,itQty
   ,itPrice
   ,itVAT
   ,itVAT2  (* Ειδικά για την Elbisco, θα χρησιμοποιήσω και δεύτερο πεδίο ΦΠΑ.
               Εάν υπάρχει μόνο το πρώτο και όχι ΚΑΙ το δεύτερο, τότε ισχύει το πρώτο.
               Εάν υπάρχει ΚΑΙ δεύτερο, ισχύει το δεύτερο.                            *)

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
  { αντιπροσωπεύει έναν τύπο πληροφορίας, πχ TInfoType.itAFM
    με επιπλέον πληροφορίες τοποθεσίας στο αρχείο, δηλαδή
    σε ποια γραμμή, ποια κολώνα, κλπ. και το μήκος του }
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
  { Περιγράφει ένα αρχείο input.
    Εχει μια λίστα, την ItemList, από στοιχεία TFileItem }
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

    FDocTypeMap              : TStringList;      { αντιστοίχιση τύπου παραστατικών δικά του με με δικά μας}
    FPayModeMap              : TStringList;      { αντιστοίχιση τρόπου πληρωμής }
    FMeasUnitMap             : TStringList;      { αντιστοίχιση μονάδας μέτρησης }
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

    property Schema                  : TFileSchema read FSchema;              { γενική μορφή του format του αρχείου import }
    property SeparationMode          : TSeparationMode read FSeparationMode;  { τρόπος αλλαγής σετ master-detail γραμμών }
    property Kind                    : TFileKind read FKind;
    property FileName                : string read FFileName;                 { ονομα αρχείου input }

    property FileNameDetail          : string read FFileNameDetail;           { ονομα αρχείου input με detail εγγραφές}

    property FileMask                : string read FFileMask;
    property NeedsFileMerge          : boolean read FNeedsFileMerge default False;

    property IsOem                   : Boolean read FIsOem;
    property IsANSI                  : Boolean read FIsANSI;
    property IsUnicode               : Boolean read FIsUnicode;
    property Name                    : string read FName;
    property AFM                     : string read FAFM;                      { ΑΦΜ προμηθευτή-πελάτη}
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
  { Το μητρώο των περιγραφέων αρχείων input }
  // ΠΡΟΣΟΧΗ: Οτι περνάμε στην Add() δεν χρειάζεται Free,
  //          διότι το απελευθερωνει αυτή εδώ η κλάση.
  // ΠΡΟΣΟΧΗ 2: H κλάση αυτή είναι singleton. Δεν χρειάζεται
  //            να δημιουργήσεις αντικείμενο. Εχουμε ήδη
  //            αντικείμενο στην global μεταβλητή FileDescriptors
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
  FileDescriptors: TFileDescriptors = nil;  // Μητρώο Περιγραφέων

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
