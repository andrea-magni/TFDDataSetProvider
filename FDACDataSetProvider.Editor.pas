unit FDACDataSetProvider.Editor;

interface

uses
  System.Classes, System.SysUtils
  ,  DesignEditors
  , FDACDataSetProvider;

type
  TFDACDataSetProviderEditor = class(TComponentEditor)
  private
    function CurrentObj: TFDDataSetProvider;
  protected
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

procedure Register;

implementation

uses
  VCL.Dialogs
  , DesignIntf;

procedure Register;
begin
  RegisterComponentEditor(TFDDataSetProvider, TFDACDataSetProviderEditor);
end;

{ TDataSetRESTRequestAdapterEditor }

function TFDACDataSetProviderEditor.CurrentObj: TFDDataSetProvider;
begin
  Result := Component as TFDDataSetProvider;
end;

procedure TFDACDataSetProviderEditor.ExecuteVerb(Index: Integer);
var
  LDataSetIndex: Integer;
begin
  inherited;

  if Index = 0 then
  begin
    CurrentObj.RetrieveData;
    ShowMessage( Format('Retrieved %d datasets: %s', [CurrentObj.DataSetsCount, CurrentObj.DataSetsNames.CommaText]) );
  end
  else
  begin
    LDataSetIndex := Index-1;
    if (LDataSetIndex >= 0) and (LDataSetIndex < CurrentObj.DataSetsCount) then
      CurrentObj.UpdateTargetDataSet(LDataSetIndex)
    else
      raise Exception.CreateFmt('Invalid DataSetIndex: %d', [LDataSetIndex]);
  end;

  Designer.Modified;
end;

function TFDACDataSetProviderEditor.GetVerb(Index: Integer): string;
var
  LDataSetIndex: Integer;
  LTargetDataSetName: string;
begin
  if Index = 0 then
    Result := 'Retrieve data from server'
  else
  begin
    LDataSetIndex := Index-1;
    LTargetDataSetName := '<TargetDataSet not assigned>';
    if Assigned(CurrentObj.TargetDataSet) then
      LTargetDataSetName := AnsiQuotedStr(CurrentObj.TargetDataSet.Name, '"');

    Result := Format('Update %s with dataset "%s"', [LTargetDataSetName, CurrentObj.DataSetsInfo[LDataSetIndex]]);
  end;
end;

function TFDACDataSetProviderEditor.GetVerbCount: Integer;
begin
  Result := CurrentObj.DataSetsCount + 1;
end;

end.

