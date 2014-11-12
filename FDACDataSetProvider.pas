unit FDACDataSetProvider;

interface

uses
  System.SysUtils, System.Classes

  // REST Client Library
  , REST.Client
  , IPPeerClient

  // FireDAC
  , FireDAC.Stan.Intf
  , FireDAC.Stan.Option
  , FireDAC.Stan.Param
  , FireDAC.Stan.Error
  , FireDAC.DatS
  , FireDAC.Phys.Intf
  , FireDAC.DApt.Intf
  , FireDAC.Stan.Async
  , FireDAC.DApt
  , FireDAC.Comp.DataSet
  , FireDAC.Stan.StorageBin
  , FireDAC.UI.Intf
  , FireDAC.Comp.UI
  , FireDAC.Comp.Client
  , Data.FireDACJSONReflect

//  , FireDAC.FMXUI.Wait
//  , FireDAC.VCLUI.Wait

;

type
  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX32 or pidiOSSimulator or pidiOSDevice or pidAndroid)]
  TFDDataSetProvider = class(TComponent)
  private
    FClient: TRESTClient;
    FRequest: TRESTRequest;
    FDataSets: TFDJSONDataSets;
    FTargetDataSet: TFDCustomMemTable;
    FDataSetsInfo: TStrings;
    FDataSetsNames: TStrings;
    procedure SetTargetDataSet(const Value: TFDCustomMemTable);
    function GetDataSetsCount: Integer;
  protected
    procedure DoRetrieveData; virtual;
    procedure DoUpdateTargetDataSet(const ADataSetNameOrIndex: string); virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure ClearDataSetsInfo; virtual;
    procedure PopulateDataSetsInfo; virtual;
    procedure TargetDataSetChanged; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure RetrieveData;
    procedure UpdateTargetDataSet(const ADataSetName: string); overload;
    procedure UpdateTargetDataSet(const ADataSetIndex: Integer); overload;

    property DataSets: TFDJSONDataSets read FDataSets;
    property DataSetsCount: Integer read GetDataSetsCount;
  published
    property RESTClient: TRESTClient read FClient write FClient;
    property RESTRequest: TRESTRequest read FRequest write FRequest;
    property DataSetsInfo: TStrings read FDataSetsInfo;
    property DataSetsNames: TStrings read FDataSetsNames;
    property TargetDataSet: TFDCustomMemTable read FTargetDataSet write SetTargetDataSet;
  end;

procedure Register;

implementation

uses
  Data.DBXJSONReflect,
  System.JSON;

procedure Register;
begin
  RegisterComponents('Andrea Magni', [TFDDataSetProvider]);
end;

{ TFDDataSetProvider }

procedure TFDDataSetProvider.ClearDataSetsInfo;
begin
  FDataSetsInfo.Clear;
  FDataSetsNames.Clear;
end;

constructor TFDDataSetProvider.Create(AOwner: TComponent);
begin
  inherited;

  FClient := TRESTClient.Create(Self);
  FClient.Name := 'RESTClient';
  FClient.SetSubComponent(True);

  FRequest := TRESTRequest.Create(Self);
  FRequest.Name := 'RESTRequest';
  FRequest.SetSubComponent(True);
  FRequest.Client := FClient;

  FDataSetsInfo := TStringList.Create;
  FDataSetsNames := TStringList.Create;
end;

destructor TFDDataSetProvider.Destroy;
begin
  FDataSetsNames.Free;
  FDataSetsInfo.Free;

  FRequest.Free;
  FClient.Free;

  inherited;
end;

procedure TFDDataSetProvider.DoRetrieveData;
var
  LUnmarshaller: TJSONUnMarshal;
  LJSONObj: TJSONObject;
begin
  FRequest.Execute;

  if Assigned(FDataSets) then
    FreeAndNil(FDataSets);
  ClearDataSetsInfo;

  LJSONObj := FRequest.Response.JSONValue.GetValue<TJSONArray>('result').Items[0] as TJSONObject;

  LUnmarshaller := TJSONUnMarshal.Create;
  try
    FDataSets := LUnmarshaller.Unmarshal(LJSONObj) as TFDJSONDataSets;
    PopulateDataSetsInfo;
  finally
    LUnmarshaller.Free;
  end;
end;

procedure TFDDataSetProvider.DoUpdateTargetDataSet(const ADataSetNameOrIndex: string);
var
  LDataSet: TFDAdaptedDataSet;
  LDataSetIndex: Integer;
begin
  Assert(Assigned(FTargetDataSet));
  Assert(Assigned(FDataSets));

  LDataSetIndex := StrToIntDef(ADataSetNameOrIndex, -1);
  if LDataSetIndex <> -1 then
    LDataSet := TFDJSONDataSetsReader.GetListValue(FDataSets, LDataSetIndex)
  else
    LDataSet := TFDJSONDataSetsReader.GetListValueByName(FDataSets, ADataSetNameOrIndex);

  if not Assigned(LDataSet) then
    raise Exception.CreateFmt('Unable to find dataset "%s"', [ADataSetNameOrIndex]);

  TargetDataSet.Data := LDataSet;
end;

function TFDDataSetProvider.GetDataSetsCount: Integer;
begin
  Result := 0;
  if Assigned(FDataSets) then
    Result := TFDJSONDataSetsReader.GetListCount(FDataSets);
end;

procedure TFDDataSetProvider.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;

  if (Operation = opRemove) then
  begin
    if (AComponent = FTargetDataSet) then
      FTargetDataSet := nil;
  end;
end;

procedure TFDDataSetProvider.PopulateDataSetsInfo;
var
  LIndex: Integer;
  LDataSet: TFDAdaptedDataSet;
  LDataSetName: string;
begin
  if not Assigned(FDataSets) then
  begin
    ClearDataSetsInfo;
    Exit;
  end;

  for LIndex := 0 to DataSetsCount-1 do
  begin
    LDataSet := TFDJSONDataSetsReader.GetListValue(FDataSets, LIndex);
    LDataSetName := TFDJSONDataSetsReader.GetListKey(FDataSets, LIndex);

    FDataSetsNames.Add(LDataSetName);

    FDataSetsInfo.Add(
      Format('%d:%s (%d records)', [LIndex, LDataSetName, LDataSet.RecordCount])
    );
  end;
end;

procedure TFDDataSetProvider.RetrieveData;
begin
  DoRetrieveData;
end;
procedure TFDDataSetProvider.SetTargetDataSet(const Value: TFDCustomMemTable);
begin
  if FTargetDataSet <> Value then
  begin
    FTargetDataSet := Value;
    TargetDataSetChanged;
  end;
end;

procedure TFDDataSetProvider.TargetDataSetChanged;
begin
//  if Assigned(FTargetDataSet) and Assigned(FDataSets) then
//    UpdateTargetDataSet;
end;

procedure TFDDataSetProvider.UpdateTargetDataSet(const ADataSetName: string);
begin
  DoUpdateTargetDataSet(ADataSetName);
end;

procedure TFDDataSetProvider.UpdateTargetDataSet(const ADataSetIndex: Integer);
begin
  DoUpdateTargetDataSet(ADataSetIndex.ToString);
end;


end.
