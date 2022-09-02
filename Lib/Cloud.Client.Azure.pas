{ ***************************************************************************
  Unit        : Cloud.Client.Azure
  Description : Azure blobs operations client
  Author      : Ali Dehbansiahkarbon
  Version     : 1.0
  Created     : 29/05/2019
  LastUpdate  : 31/08/2022

 ***************************************************************************
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

 *************************************************************************** }
 {$I AzureClient.inc}

unit Cloud.Client.Azure;

interface

uses
  Classes, System.SysUtils, System.Generics.Collections,
  IPPeerClient, IdURI, Data.Cloud.CloudAPI, Data.Cloud.AzureAPI;

type

  TAzureProtocol = (apHTTP, apHTTPS);

  TAzureResponseInfo = record
    StatusCode: Integer;
    StatusMsg: string;
  end;

  TAzureBlobObject = class
    Name: string;
    Size: Int64;
    IsDir: Boolean;
    LastModified: TDateTime;
  end;

  TBlobList = TObjectList<TAzureBlobObject>;

  TAzureClient = class
    private
      FAzureConnection: TAzureConnectionInfo;
      FAzureAccountName: string;
      FAzureAccountKey: string;
      FAzureProtocol: TAzureProtocol;
      FConnectionTimeOut: Integer;
      procedure SetAccountName(AAccountName: string);
      procedure SetAccountKey(AAccountKey: string);
      procedure SetAzureProtocol(AProtocol: TAzureProtocol);
      function FileToArray(AFullFilename: string): TArray<Byte>;
      function StreamToArray(AStream: TStream): TArray<Byte>;
      function ByteContent(ADataStream: TStream): TBytes;
      function GMT2DateTime(const AGmtDate: string):TDateTime;
      function CheckContainer(const AContainer: string) : string;
      function RemoveFirstSlash(const AValue: string) : string;
      function GetMonthDig(AValue: string): Integer;
    public
      constructor Create(AProtocol: TAzureProtocol; AConnectionTimeOut: Integer = 30); overload;
      constructor Create(AAccountName, AAccountKey: string; AProtocol: TAzureProtocol; AConnectionTimeOut: Integer = 30); overload;
      destructor Destroy; override;

      property AccountName: string read FAzureAccountName write SetAccountName;
      property AccountKey: string read FAzureAccountKey write SetAccountKey;
      property Protocol: TAzureProtocol read FAzureProtocol write SetAzureProtocol;
      property ConnectionTimeOut: Integer read FConnectionTimeOut write FConnectionTimeOut;

      function UploadBlob(const AContainer, ASourceFilePath, ABlobName: string; out AResponseInfo: TAzureResponseInfo): Boolean; overload;
      function UploadBlob(const AContainer: string; AStream: TStream; const ABlobName: string; out AResponseInfo: TAzureResponseInfo): Boolean; overload;
      function DownloadBlob(const AContainer, ABlobName, ADestinationFilePath: string; out AResponseInfo: TAzureResponseInfo): Boolean; overload;
      function DownloadBlob(const AContainer, ABlobName: string; out AResponseInfo: TAzureResponseInfo; var AStream: TMemoryStream): Boolean; overload;
      function DownloadBlob(const AContainer, ABlobName: string; out AResponseInfo: TAzureResponseInfo; var AStream: TStream): Boolean; overload;
      function DownloadBlob(const AContainer, ABlobName: string; out AResponseInfo: TAzureResponseInfo): TMemoryStream; overload;
      function CopyBlob(const ASourceContainer, ASourceBlobName: string; ATargetContainer, ATargetBlobName: string; out AResponseInfo: TAzureResponseInfo): Boolean;
      function RenameBlob(const AContainer, ASourceBlobName, ATargetBlobName: string; out AResponseInfo: TAzureResponseInfo): Boolean;
      function ExistsObject(const AContainer, ABlobName: string): Boolean;
      function ExistsFolder(const AContainer, AFolderName: string): Boolean;
      function DeleteBlob(const AContainer, ABlobName: string; out AResponseInfo: TAzureResponseInfo): Boolean;
      function ListBlobs(const AContainer, ABlobsStartWith: string; ARecursive: Boolean; out AResponseInfo: TAzureResponseInfo): TBlobList;
      function ListBlobsNames(const AContainer, ABlobsStartWith: string; ARecursive: Boolean; out AResponseInfo: TAzureResponseInfo): TStrings;
      function ExistsContainer(const AContainer: string): Boolean;
      function CreateContainer(const AContainer: string; APublicAccess: TBlobPublicAccess; out AResponseInfo: TAzureResponseInfo): Boolean;
      function DeleteContainer(const AContainer: string; out AResponseInfo: TAzureResponseInfo): Boolean;
      function RemoveLastChar(const AText: string): string;
      procedure ListContainers(const AStorageAccountName: string; out AResponseInfo: TAzureResponseInfo; var AContainerList: TStringList);
  end;

implementation


constructor TAzureClient.Create(AProtocol: TAzureProtocol; AConnectionTimeOut: Integer);
begin
  inherited Create;
  FAzureConnection := TAzureConnectionInfo.Create(nil);
  SetAzureProtocol(AProtocol);
  FConnectionTimeOut := AConnectionTimeOut;
end;

constructor TAzureClient.Create(AAccountName, AAccountKey: string; AProtocol: TAzureProtocol; AConnectionTimeOut: Integer);
begin
  Self.Create(AProtocol, AConnectionTimeOut);
  SetAccountName(AAccountName);
  SetAccountKey(AAccountKey);
end;

destructor TAzureClient.Destroy;
begin
  if Assigned(FAzureConnection) then
    FAzureConnection.Free;
  inherited;
end;

procedure TAzureClient.SetAccountName(AAccountName: string);
begin
  if FAzureAccountName <> AAccountName  then
  begin
    FAzureAccountName := AAccountName;
    FAzureConnection.AccountName := AAccountName;
  end;
end;

procedure TAzureClient.SetAccountKey(AAccountKey: string);
begin
  if FAzureAccountKey  <> AAccountKey   then
  begin
    FAzureAccountKey := AAccountKey ;
    FAzureConnection.AccountKey := AAccountKey;
  end;
end;

procedure TAzureClient.SetAzureProtocol(AProtocol: TAzureProtocol);
begin
  if FAzureProtocol <> AProtocol then
  begin
    FAzureProtocol := AProtocol;
    if AProtocol = apHTTP then
      FAzureConnection.Protocol := 'HTTP'
    else
      FAzureConnection.Protocol := 'HTTPS';
  end;
end;

function TAzureClient.FileToArray(AFullFilename : string) : TArray<Byte>;
var
  LvFStream: TFileStream;
begin
  LvFStream := TFileStream.Create(AFullFilename, fmOpenRead);
  try
    Result := ByteContent(LvFStream);
  finally
    LvFStream.Free;
  end;
end;

function TAzureClient.StreamToArray(AStream: TStream): TArray<Byte>;
var
  LvBStream : TBytesStream;
begin
  LvBStream := TBytesStream.Create(Result);
  try
    LvBStream.LoadFromStream(AStream);
    Result := LvBStream.Bytes;
  finally
    LvBStream.Free
  end;
end;

function TAzureClient.ByteContent(ADataStream: TStream): TBytes;
var
  LvBuffer: TBytes;
begin
  if not Assigned(ADataStream) then
    Exit(nil);

  SetLength(LvBuffer, ADataStream.Size);
  ADataStream.Position := 0;

  if ADataStream.Size > 0 then
  ADataStream.Read(LvBuffer[0], ADataStream.Size);
  Result := LvBuffer;
end;

function TAzureClient.GetMonthDig(AValue: string):Integer;
const
  CMonth: array[1..12] of string = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to 12 do
  begin
    if CompareText(AValue, CMonth[I]) = 0 then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function TAzureClient.GMT2DateTime(const AGmtDate: string):TDateTime;
var
  I: Integer;
  LvLen: Integer;
  LvDay, LvMonth, LvYear, LvHour, LvMinute, LvSec: Word;
begin
  //GMT Format Sample: 'Mon, 12 Jan 2014 16:20:35 GMT'
  Result := 0;
  LvLen := 0;
  if AGmtDate = EmptyStr then
    Exit;

  try
    for I := 0 to Length(AGmtDate) do
    begin
      if CharInSet(AGmtDate[I], ['0'..'9']) then
      begin
        LvLen := I;
        Break;
      end;
    end;

    //Day
    LvDay := StrToIntDef(Copy(AGmtDate, LvLen, 2), 0);
    if LvDay = 0 then
      Exit;

    Inc(LvLen, 3);

    //Month
    LvMonth := GetMonthDig(Copy(AGmtDate, LvLen, 3));
    if LvMonth = 0 then
      Exit;

    Inc(LvLen, 4);

    //Year
    LvYear := StrToIntDef(Copy(AGmtDate, LvLen, 4), 0);
    if LvYear = 0 then
      Exit;

    Inc(LvLen, 5);

    //Hour
    LvHour := StrToIntDef(Copy(AGmtDate, LvLen, 2), 99);
    if LvHour = 99 then
      Exit;

    Inc(LvLen, 3);

    //Min
    LvMinute := StrToIntDef(Copy(AGmtDate, LvLen, 2), 99);
    if LvMinute = 99 then
       Exit;
    Inc(LvLen, 3);

    //Sec
    LvSec := StrToIntDef(Copy(AGmtDate, LvLen, 2), 99);
    if LvSec = 99 then
      Exit;

    Result := EncodeDate(LvYear, LvMonth, LvDay) + EncodeTime(LvHour, LvMinute, LvSec, 0);
  except
    Result := 0;
  end;
end;

function GetResponseInfo(ResponseInfo : TCloudResponseInfo) : TAzureResponseInfo;
begin
  Result.StatusCode := ResponseInfo.StatusCode;
  Result.StatusMsg := ResponseInfo.StatusMessage;
end;

function TAzureClient.UploadBlob(const AContainer, ASourceFilePath, ABlobName: string; out AResponseInfo: TAzureResponseInfo): Boolean;
var
  LvBlobService: TAzureBlobService;
  LvContent: TArray<Byte>;
  LvCloudResponseInfo: TCloudResponseInfo;
  LvContainer: string;
  LvBlobName: string;
begin
  LvBlobService := TAzureBlobService.Create(FAzureConnection);
  try
    LvContainer := CheckContainer(AContainer);
    LvCloudResponseInfo := TCloudResponseInfo.Create;
    try
      LvBlobService.Timeout := FConnectionTimeOut;
      LvContent := FileToArray(ASourceFilePath);
      if ABlobName = EmptyStr then
        LvBlobName := ASourceFilePath
      else
        LvBlobName := ABlobName;

      if LvBlobName.StartsWith('/') then
        LvBlobName := Copy(LvBlobName, 2, Length(LvBlobName));

      Result := LvBlobService.PutBlockBlob(LvContainer, LvBlobName, LvContent, EmptyStr, nil, nil, LvCloudResponseInfo);
      AResponseInfo := GetResponseInfo(LvCloudResponseInfo);
    finally
      LvCloudResponseInfo.Free;
    end;
  finally
    LvBlobService.Free;
  end;
end;

function TAzureClient.UploadBlob(const AContainer: string; AStream: TStream; const ABlobName: string; out AResponseInfo: TAzureResponseInfo): Boolean;
var
  LvBlobService: TAzureBlobService;
  LvContent: TBytes;
  LvCloudResponseInfo: TCloudResponseInfo;
  LvContainer: string;
  LvBlobName: string;
begin
  Result := False;
  AResponseInfo.StatusCode := 500;
  if AStream.Size = 0 then
  begin
    AResponseInfo.StatusMsg := 'Stream is empty';
    Exit;
  end;

  LvContainer := CheckContainer(AContainer);
  LvBlobName := RemoveFirstSlash(ABlobName);
  try
    LvBlobService := TAzureBlobService.Create(FAzureConnection);
    try
      LvBlobService.Timeout := FConnectionTimeOut;
      LvCloudResponseInfo := TCloudResponseInfo.Create;
      try
        LvContent := ByteContent(AStream);
        Result := LvBlobService.PutBlockBlob(LvContainer, LvBlobName, LvContent, EmptyStr, nil, nil, LvCloudResponseInfo);
        AResponseInfo := GetResponseInfo(LvCloudResponseInfo);
      finally
        LvCloudResponseInfo.Free;
      end;
    finally
      LvBlobService.Free;
    end;
  except on E: Exception do
    begin
      AResponseInfo.StatusCode := 500;
      AResponseInfo.StatusMsg := E.Message;
      Result := False;
    end;
  end;
end;

function TAzureClient.DownloadBlob(const AContainer, ABlobName, ADestinationFilePath: string; out AResponseInfo: TAzureResponseInfo): Boolean;
var
  ABlobService: TAzureBlobService;
  LvFStream: TFileStream;
  LvCloudResponseInfo: TCloudResponseInfo;
  LVContainer: string;
  LvBlobName: string;
begin
  LVContainer := CheckContainer(AContainer);
  LvBlobName := RemoveFirstSlash(ABlobName);
  ABlobService := TAzureBlobService.Create(FAzureConnection);
  try
    ABlobService.Timeout := FConnectionTimeOut;
    LvFStream := TFileStream.Create(ADestinationFilePath, fmCreate);
    try
      try
        LvCloudResponseInfo := TCloudResponseInfo.Create;
        try
          Result := ABlobService.GetBlob(LVContainer, LvBlobName, LvFStream, EmptyStr, LvCloudResponseInfo);
          AResponseInfo := GetResponseInfo(LvCloudResponseInfo);
        finally
          LvCloudResponseInfo.Free;
        end;
      except
        Result := False;
      end;
    finally
      LvFStream.Free;
    end;
  finally
    ABlobService.Free;
  end;
end;

function TAzureClient.DownloadBlob(const AContainer, ABlobName: string; out AResponseInfo: TAzureResponseInfo; var AStream: TMemoryStream): Boolean;
begin
  Result := DownloadBlob(AContainer, ABlobName, AResponseInfo, TStream(AStream));
end;

function TAzureClient.DownloadBlob(const AContainer, ABlobName: string; out AResponseInfo: TAzureResponseInfo): TMemoryStream;
begin
  DownloadBlob(AContainer, ABlobName, AResponseInfo, Result);
end;

function TAzureClient.DownloadBlob(const AContainer, ABlobName: string; out AResponseInfo: TAzureResponseInfo; var AStream: TStream): Boolean;
var
  LvBlobService: TAzureBlobService;
  LvCloudResponseInfo: TCloudResponseInfo;
  LvContainer: string;
  LvBlobName: string;
begin
  LvContainer := CheckContainer(AContainer);
  LvBlobName := RemoveFirstSlash(ABlobName);
  LvBlobService := TAzureBlobService.Create(FAzureConnection);
  try
    LvBlobService.Timeout := FConnectionTimeOut;
    LvCloudResponseInfo := TCloudResponseInfo.Create;
    try
      Result := LvBlobService.GetBlob(LvContainer, LvBlobName, AStream, EmptyStr, LvCloudResponseInfo);
      AResponseInfo := GetResponseInfo(LvCloudResponseInfo);
    finally
      LvCloudResponseInfo.Free;
    end;
  finally
    LvBlobService.Free;
  end;
end;

function TAzureClient.CheckContainer(const AContainer: string): string;
begin
  if AContainer = EmptyStr then
    Result := '$root'
  else
    Result := AContainer;
end;

function TAzureClient.CopyBlob(const ASourceContainer, ASourceBlobName: string; ATargetContainer, ATargetBlobName: string; out AResponseInfo: TAzureResponseInfo): Boolean;
var
  LvBlobService: TAzureBlobService;
  LvCloudResponseInfo: TCloudResponseInfo;
  LvSourceContainer: string;
  LvTargetContainer: string;
  LvSourceBlobName: string;
  LvTargetBlobName: string;
begin
  LvSourceContainer := CheckContainer(ASourceContainer);
  LvTargetContainer := CheckContainer(ATargetContainer);
  LvSourceBlobName := RemoveFirstSlash(ASourceBlobName);
  LvTargetBlobName := RemoveFirstSlash(ATargetBlobName);
  LvBlobService := TAzureBlobService.Create(FAzureConnection);
  try
    LvBlobService.Timeout := FConnectionTimeOut;
    try
      LvCloudResponseInfo := TCloudResponseInfo.Create;
      try
        Result := LvBlobService.CopyBlob(LvTargetContainer, LvTargetBlobName, LvSourceContainer, LvSourceBlobName, EmptyStr, nil, LvCloudResponseInfo);
        AResponseInfo := GetResponseInfo(LvCloudResponseInfo);
      finally
        LvCloudResponseInfo.Free;
      end;
    except on E: Exception do
      begin
        Result := False;
        AResponseInfo.StatusCode := 500;
        AResponseInfo.StatusMsg := E.Message;
      end;
    end;
  finally
    LvBlobService.Free;
  end;
end;

function TAzureClient.RemoveFirstSlash(const AValue: string): string;
begin
  if AValue.StartsWith('/') then
    Result := Copy(AValue, 2, Length(AValue))
  else
    Result := AValue;
end;

function TAzureClient.RemoveLastChar(const AText: string): string;
begin
  Result := AText.Remove(AText.Length - 1);
end;

function TAzureClient.RenameBlob(const AContainer, ASourceBlobName, ATargetBlobName: string; out AResponseInfo: TAzureResponseInfo): Boolean;
var
  LVSurceBlobName: string;
begin
  Result := False;

  if LVSurceBlobName.Contains('%') then
    LVSurceBlobName := ASourceBlobName
  else
    LVSurceBlobName := TIdURI.PathEncode(ASourceBlobName);

  if CopyBlob(AContainer, LVSurceBlobName, AContainer, ATargetBlobName, AResponseInfo) then
    Result := DeleteBlob(AContainer, ASourceBlobName, AResponseInfo);
end;

function TAzureClient.ExistsObject(const AContainer, ABlobName: string): Boolean;
var
  LvBlob: string;
  LvBlobList: TStrings;
  LvResponseInfo: TAzureResponseInfo;
begin
  Result := False;
  LvBlobList := ListBlobsNames(AContainer, ABlobName, False, LvResponseInfo);
  try
    if (LvResponseInfo.StatusCode = 200) and (Assigned(LvBlobList)) then
    begin
      for LvBlob in LvBlobList do
      begin
        if LvBlob = ABlobName then
        begin
          Result := True;
          Break;
        end;
      end;
    end;
  finally
    LvBlobList.Free;
  end;
end;

function TAzureClient.ExistsFolder(const AContainer, AFolderName : string) : Boolean;
var
  LvBlobService: TAzureBlobService;
  LvBlob: TAzureBlob;
  LvBlobList: TList<TAzureBlob>;
  LvCloudResponseInfo: TCloudResponseInfo;
  LvParams: TStrings;
  LvNextMarker: string;
  LvContainer: string;
  LvFolderName: string;
begin
  Result := False;
  LvContainer := CheckContainer(AContainer);
  LvBlobService := TAzureBlobService.Create(FAzureConnection);
  try
    LvBlobService.Timeout := FConnectionTimeOut;
    LvParams := TStringList.Create;
    try
      if not AFolderName.EndsWith('/') then
        LvFolderName := AFolderName + '/'
      else
        LvFolderName := AFolderName;

      LvParams.Values['prefix'] := LvFolderName;
      LvParams.Values['delimiter'] := '/';
      LvParams.Values['maxresults'] := '1';
      LvNextMarker := EmptyStr;
      LvCloudResponseInfo := TCloudResponseInfo.Create;
      try
        LvBlobList := LvBlobService.ListBlobs(LvContainer, LvNextMarker, LvParams, LvCloudResponseInfo);
        try
          if (Assigned(LvBlobList)) and (LvBlobList.Count > 0) and (LvCloudResponseInfo.StatusCode = 200) then
            Result := True;
        finally

          for LvBlob in LvBlobList do
            LvBlob.Free;

          LvBlobList.Free;
        end;
      finally
        LvCloudResponseInfo.Free;
      end;
    finally
      LvParams.Free;
    end;
  finally
    LvBlobService.Free;
  end;
end;

function TAzureClient.DeleteBlob(const AContainer, ABlobName: string; out AResponseInfo: TAzureResponseInfo): Boolean;
var
  LvBlobService: TAzureBlobService;
  LvCloudResponseInfo: TCloudResponseInfo;
  LvContainer: string;
  LvBlobName: string;
begin
  LvContainer := CheckContainer(AContainer);
  LvBlobName := RemoveFirstSlash(ABlobName);
  LvBlobService := TAzureBlobService.Create(FAzureConnection);
  try
    LvBlobService.Timeout := FConnectionTimeOut;
    LvCloudResponseInfo := TCloudResponseInfo.Create;
    try
      Result := LvBlobService.DeleteBlob(LvContainer, LvBlobName, False, EmptyStr, LvCloudResponseInfo);
      AResponseInfo := GetResponseInfo(LvCloudResponseInfo);
    finally
      LvCloudResponseInfo.Free;
    end;
  finally
    LvBlobService.Free;
  end;
end;

{$IFDEF DELPHITOKYO_UP}
function TAzureClient.ListBlobs(const AContainer, ABlobsStartWith: string; ARecursive: Boolean; out AResponseInfo: TAzureResponseInfo): TBlobList;
var
  LvBlobService: TAzureBlobService;
  LvBlob: TAzureBlobItem;
  LvBlobList: TArray<TAzureBlobItem>;
  LvBlobObject: TAzureBlobObject;
  LvCloudResponseInfo: TCloudResponseInfo;
  LvNextMarker: string;
  LvContainer: string;
  LvPrefix: string;
  LvBlobPrefix: TArray<string>;
  LvXmlResponse: string;
  LvFolder: string;
  LvProp: TPair<string,string>;
  LvPreviousMaker: string;
begin
  Result := TBlobList.Create(True);
  LvNextMarker := EmptyStr;
  LvContainer := CheckContainer(AContainer);
  LvBlobService := TAzureBlobService.Create(FAzureConnection);
  try
    if ARecursive then
      LvPrefix := EmptyStr
    else
      LvPrefix := '/';

    LvBlobService.Timeout := FConnectionTimeout;
    repeat
      LvCloudResponseInfo := TCloudResponseInfo.Create;
      try
        LvPreviousMaker := LvNextMarker;
        LvBlobList := LvBlobService.ListBlobs(LvContainer, ABlobsStartWith, '/', LvPreviousMaker, 100, [], LvNextMarker, LvBlobPrefix, LvXmlResponse, LvCloudResponseInfo);
        AResponseInfo := GetResponseInfo(LvCloudResponseInfo);
        if Assigned(LvBlobList) then
          Result.Capacity := High(LvBlobList);

        //get folders (prefix)
        for LvFolder in LvBlobPrefix do
        begin
          LvBlobObject := TAzureBlobObject.Create;
          if LvFolder.EndsWith('/') then
            LvBlobObject.Name := RemoveLastChar(LvFolder)
          else
            LvBlobObject.Name := LvFolder;

          LvBlobObject.Name := Copy(LvBlobObject.Name, LvBlobObject.Name.LastDelimiter('/') + 2, LvBlobObject.Name.Length);
          LvBlobObject.IsDir := True;
          Result.Add(LvBlobObject);
        end;

        //get files (blobs)
        if Assigned(LvBlobList) then
        begin
          for LvBlob in LvBlobList do
          begin
            LvBlobObject := TAzureBlobObject.Create;
            LvBlobObject.Name := LvBlob.Name;
            for LvProp in LvBlob.Properties do
            begin
              if LvProp.Key = 'Content-Length' then
                LvBlobObject.Size := StrToInt64Def(LvProp.Value, 0)
              else if LvProp.Key = 'Last-Modified' then
                LvBlobObject.LastModified := GMT2DateTime(LvProp.Value);
            end;
            LvBlobObject.IsDir := False;
            Result.Add(LvBlobObject);
          end;
        end;
      finally
        LvCloudResponseInfo.Free;
      end;
    until (LvNextMarker = EmptyStr) or (AResponseInfo.StatusCode <> 200);
  finally
    LvBlobService.Free;
  end;
end;
{$ELSE}
function TAzureClient.ListBlobs(const AContainer, ABlobsStartWith: string; ARecursive: Boolean; out AResponseInfo: TAzureResponseInfo): TBlobList;
var
  LvBlobService: TAzureBlobService;
  LvBlob: TAzureBlob;
  LvBlobList: TList<TAzureBlob>;
  LvBlobObject: TAzureBlobObject;
  LvCloudResponseInfo: TCloudResponseInfo;
  LvNextMarker: string;
  LvParams: TStrings;
  LvContainer: string;
  LvXmlResponse: string;
  LvPreviousMarker: string;
begin
  Result := TBlobList.Create(True);
  LvNextMarker := EmptyStr;
  LvContainer := CheckContainer(AContainer);
  LvBlobService := TAzureBlobService.Create(FAzureConnection);
  try
    LvBlobService.Timeout := FConnectionTimeOut;
    repeat
      LvParams := TStringList.Create;
      try
        LvParams.Values['prefix'] := ABlobsStartWith;

        if not ARecursive then
          LvParams.Values['delimiter'] := '/';

        if LvNextMarker <> EmptyStr then
          LvParams.Values['marker'] := LvNextMarker;

        LvCloudResponseInfo := TCloudResponseInfo.Create;
        try
          LvBlobList := LvBlobService.ListBlobs(LvContainer, LvNextMarker, LvParams, LvCloudResponseInfo);
          AResponseInfo := GetResponseInfo(LvCloudResponseInfo);
          if Assigned(LvBlobList) then
          begin
            Result.Capacity := LvBlobList.Count;
            try
              for LvBlob in LvBlobList do
              begin
                LvBlobObject := TAzureBlobObject.Create;
                LvBlobObject.Name := LvBlob.Name;
                LvBlobObject.Size := StrToInt64Def(LvBlob.Properties.Values['Content-Length'], 0);
                LvBlobObject.LastModified := GMT2DateTime(LvBlob.Properties.Values['Last-Modified']);
                Result.Add(LvBlobObject);
              end;
            finally
              for LvBlob in LvBlobList do LvBlob.Free;
                LvBlobList.Free;
            end;
          end;
        finally
          LvCloudResponseInfo.Free;
        end;
      finally
        FreeAndNil(LvParams);
      end;
    until (LvNextMarker = EmptyStr) or (AResponseInfo.StatusCode <> 200);
  finally
    LvBlobService.Free;
  end;
end;
{$ENDIF}

{$IFDEF DELPHITOKYO_UP}
function TAzureClient.ListBlobsNames(const AContainer, ABlobsStartWith: string; ARecursive: Boolean; out AResponseInfo: TAzureResponseInfo): TStrings;
var
  LvBlobService: TAzureBlobService;
  LvBlob: TAzureBlobItem;
  LvBlobList: TArray<TAzureBlobItem>;
  LvBlobObject: TAzureBlobObject;
  LvCloudResponseInfo: TCloudResponseInfo;
  LvNextMarker: string;
  LvContainer: string;
  LvPrefix: string;
  LvBlobPrefix: TArray<string>;
  LvXmlResponse: string;
  LvFolder: string;
  LvPreviousMaker : string;
begin
  Result := TStringList.Create;
  LvNextMarker := EmptyStr;
  LvContainer := CheckContainer(AContainer);
  LvBlobService := TAzureBlobService.Create(FAzureConnection);
  try
    if ARecursive then
      LvPrefix := EmptyStr
    else
      LvPrefix := '/';

    LvBlobService.Timeout := FConnectionTimeOut;
    repeat
      LvCloudResponseInfo := TCloudResponseInfo.Create;
      try
        LvPreviousMaker := LvNextMarker;
        LvBlobList := LvBlobService.ListBlobs(AContainer, ABlobsStartWith, '/', LvPreviousMaker, 100, [], LvNextMarker, LvBlobPrefix, LvXmlResponse, LvCloudResponseInfo);
        AResponseInfo := GetResponseInfo(LvCloudResponseInfo);
        if Assigned(LvBlobList) then
          Result.Capacity := High(LvBlobList);

        //get folders (prefix)
        for LvFolder in LvBlobPrefix do
        begin
          LvBlobObject := TAzureBlobObject.Create;
          if LvFolder.EndsWith('/') then
            LvBlobObject.Name := RemoveLastChar(LvFolder)
          else
            LvBlobObject.Name := LvFolder;

          Result.Add(Copy(LvBlobObject.Name, LvBlobObject.Name.LastDelimiter('/') + 2, LvBlobObject.Name.Length));
        end;

        //get files (blobs)
        if Assigned(LvBlobList) then
        begin
          for LvBlob in LvBlobList do
            Result.Add(LvBlob.Name);
        end;
      finally
        LvCloudResponseInfo.Free;
      end;
    until (LvNextMarker = EmptyStr) or (AResponseInfo.StatusCode <> 200);
  finally
    LvBlobService.Free;
  end;
end;
{$ELSE}
function TAzureClient.ListBlobsNames(const AContainer, ABlobsStartWith: string; ARecursive: Boolean; out AResponseInfo: TAzureResponseInfo) : TStrings;
var
  LvBlobService: TAzureBlobService;
  LvBlob: TAzureBlob;
  LvBlobList: TList<TAzureBlob>;
  LvCloudResponseInfo: TCloudResponseInfo;
  LvNextMarker: string;
  LvParams: TStrings;
  LvContainer: string;
begin
  Result := TStringList.Create;
  LvNextMarker := EmptyStr;
  LvContainer := CheckContainer(AContainer);
  LvBlobService := TAzureBlobService.Create(FAzureConnection);
  LvCloudResponseInfo := TCloudResponseInfo.Create;
  try
    LvBlobService.Timeout := FConnectionTimeOut;
    repeat
      LvParams := TStringList.Create;
      try
        LvParams.Values['prefix'] := ABlobsStartWith;
        if not ARecursive then
          LvParams.Values['delimiter'] := '/';

        if LvNextMarker <> EmptyStr then
          LvParams.Values['marker'] := LvNextMarker;

        LvBlobList := LvBlobService.ListBlobs(LvContainer, LvNextMarker, LvParams, LvCloudResponseInfo);
        AResponseInfo := GetResponseInfo(LvCloudResponseInfo);
        if Assigned(LvBlobList) then
        begin
          Result.Capacity := LvBlobList.Count;
          Result.BeginUpdate;
          try
            for LvBlob in LvBlobList do
              Result.Add(LvBlob.Name);
          finally
            Result.EndUpdate;
            for LvBlob in LvBlobList do LvBlob.Free;
              LvBlobList.Free;
          end;
        end;
      finally
        LvParams.Free;
      end;
    until (LvNextMarker = EmptyStr) or (AResponseInfo.StatusCode <> 200);
  finally
    LvBlobService.Free;
    LvCloudResponseInfo.Free;
  end;
end;
{$ENDIF}

function TAzureClient.ExistsContainer(const AContainer: string): Boolean;
var
  LvContainer: string;
  LvContainerList: TStringList;
  LvResponseInfo: TAzureResponseInfo;
begin
  Result := False;
  LvContainerList := TStringList.Create;
  ListContainers(AContainer, LvResponseInfo, LvContainerList);
  try
    if (LvResponseInfo.StatusCode = 200) and (Assigned(LvContainerList)) then
    begin
      for LvContainer in LvContainerList do
      begin
        if LvContainer = AContainer then
        begin
          Result := True;
          Break;
        end;
      end;
    end;
  finally
    LvContainerList.Free;
  end;
end;

procedure TAzureClient.ListContainers(const AStorageAccountName: string; out AResponseInfo: TAzureResponseInfo; var AContainerList: TStringList);
var
  LvBlobService: TAzureBlobService;
  LvCloudResponseInfo: TCloudResponseInfo;
  LvNextMarker: string;
  LvParams: TStrings;
  LvContainer: TAzureContainer;
  LvContainerList: TList<TAzureContainer>;
begin
  LvNextMarker := EmptyStr;
  LvBlobService := TAzureBlobService.Create(FAzureConnection);
  LvCloudResponseInfo := TCloudResponseInfo.Create;
  try
    LvBlobService.Timeout := FConnectionTimeOut;
    repeat
      LvParams := TStringList.Create;
      try
        if AStorageAccountName <> EmptyStr then
          LvParams.Values['prefix'] := AStorageAccountName;

        if LvNextMarker <> EmptyStr then
          LvParams.Values['marker'] := LvNextMarker;

        LvContainerList := LvBlobService.ListContainers(LvNextMarker, LvParams, LvCloudResponseInfo);
        try
          AResponseInfo := GetResponseInfo(LvCloudResponseInfo);
          if (AResponseInfo.StatusCode = 200) and (Assigned(LvContainerList)) then
          begin
            AContainerList.Capacity := LvContainerList.Count;
            for LvContainer in LvContainerList do
              AContainerList.Add(LvContainer.Name);
          end;
        finally
          if Assigned(LvContainerList) then
          begin
            for LvContainer in LvContainerList do LvContainer.Free;
              LvContainerList.Free;
          end;
        end;
      finally
        LvParams.Free;
      end;
    until (LvNextMarker = EmptyStr) or (AResponseInfo.StatusCode <> 200);
  finally
    LvBlobService.Free;
    LvCloudResponseInfo.Free;
  end;
end;

function TAzureClient.CreateContainer(const AContainer: string; APublicAccess: TBlobPublicAccess; out AResponseInfo: TAzureResponseInfo): Boolean;
var
  LvBlobService: TAzureBlobService;
  LvCloudResponseInfo: TCloudResponseInfo;
  LvMetaData: TPair<string, string>;
begin
  Result := False;
  if AContainer = EmptyStr then
    Exit;

  LvBlobService := TAzureBlobService.Create(FAzureConnection);
  try
    LvBlobService.Timeout := FConnectionTimeOut;
    LvCloudResponseInfo := TCloudResponseInfo.Create;
    try
//      Result := LvBlobService.CreateContainer(AContainer, nil, APublicAccess, LvCloudResponseInfo);
      Result := LvBlobService.CreateContainer(AContainer, LvMetaData, APublicAccess, LvCloudResponseInfo);
      AResponseInfo := GetResponseInfo(LvCloudResponseInfo);
    finally
      LvCloudResponseInfo.Free;
    end;
  finally
    LvBlobService.Free;
  end;
end;

function TAzureClient.DeleteContainer(const AContainer: string; out AResponseInfo: TAzureResponseInfo): Boolean;
var
  LvBlobService: TAzureBlobService;
  LvCloudResponseInfo: TCloudResponseInfo;
begin
  Result := False;
  if AContainer = EmptyStr then
    Exit;

  LvBlobService := TAzureBlobService.Create(FAzureConnection);
  try
    LvBlobService.Timeout := FConnectionTimeOut;
    LvCloudResponseInfo := TCloudResponseInfo.Create;
    try
      Result := LvBlobService.DeleteContainer(AContainer, LvCloudResponseInfo);
      AResponseInfo := GetResponseInfo(LvCloudResponseInfo);
    finally
      LvCloudResponseInfo.Free;
    end;
  finally
    LvBlobService.Free;
  end;
end;

end.
