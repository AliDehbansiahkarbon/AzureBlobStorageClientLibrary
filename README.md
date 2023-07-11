# Tiny Azure Data Storage client library for Embarcadero Delphi.

A super easy-to-use library to work with Azure storage using Embarcadero Delphi.
No need for documentation! just read the code, it will speak by itself!
You may use this library to upload blob, download blob, rename blob, copy blob, list containers, list blobs, delete blob, create containers, etc in the Azure storage environment directly from your Delphi project.

## Screenshot
![image](https://github.com/AliDehbansiahkarbon/AzureStorageClientLibrary/assets/5601608/a3964219-b0c8-4f24-a77f-62bd2ee3f434)


## Quick Start!

### Load Container List

```pascal
var
  LvContainerList: TStringList;
begin
  LvContainerList := TStringList.Create;
  try
    if LoadContainersList(cStorageAccount, LvContainerList) then
       Memo1.Lines.Text := LvContainerList.Text;
  finally
    LvContainerList.Free;
  end;
end;
```

### Load Blobs List
```pascal
var
  LvAzureResponseInfo: TAzureResponseInfo;
  LvBlobObj: TAzureBlobObject;
  LvAzureClient: TAzureClient;
  LvBlobList: TBlobList;
begin
  LvAzureClient := TAzureClient.Create(cStorageAccount, cAccountKey, apHTTPS);
  try
    LvBlobList := LvAzureClient.ListBlobs('00854ab1af294ae10f44dafcd0140e6e76e43f21b229209a991cad7bf30cac9', EmptyStr, True, LvAzureResponseInfo);
    for LvBlobObj in LvBlobList do
      Memo1.Lines.Add(LvBlobObj.Name);
  finally
    LvAzureClient.Free;
    if Assigned(LvBlobList) then
      LvBlobList.Free;
  end;
end;
```
### Download Blob
```pascal
var
  LvTmpStream : TMemoryStream;
  LvAzureResponseInfo: TAzureResponseInfo;
  LvAzureClient: TAzureClient;
begin
  LvAzureClient := TAzureClient.Create(cStorageAccount, cAccountKey, apHTTPS);
  try

    LvTmpStream := TMemoryStream.Create;
    try
      if LvAzureClient.DownloadBlob('00854ab1af294ae10f44dafcd0140e6e76e43f21b229209a991cad7bf30cac9',
            '26c914cb94d476cf5c57a733b93f5ebf046ca887c1083956954c8a6b520452d', LvAzureResponseInfo, LvTmpStream) then
        LoadImageFromStream(Img_Blob, LvTmpStream)
      else
        ShowMessage(LvAzureResponseInfo.StatusMsg);
    finally
      LvTmpStream.Free;
    end;
  finally
    LvAzureClient.Free;
  end;
end;
```
### Upload Blob
```pascal
var
  LvAzureClient: TAzureClient;
  LvAzureResponseInfo: TAzureResponseInfo;
begin
  //Create a new Container and upload a file into it.
  {By the Azure rules, CONTAINER name may only contain lowercase letters, numbers, and hyphens,
   and must begin with a letter or a number. Each hyphen must be preceded
   and followed by a non-hyphen character. The name must also be between 3 and 63 characters long!}

  LvAzureClient :=  TAzureClient.Create(cStorageAccount, cAccountKey, apHTTPS);
  try
    if OpenDialog1.Execute then
    begin
      if not LvAzureClient.UploadBlob('newcontainer', OpenDialog1.FileName, 'FirstUploadedImage.jpg', LvAzureResponseInfo) then
        ShowMessage(LvAzureResponseInfo.StatusMsg)
      else
        ShowMessage('Uploaded!');
    end;
  finally
    LvAzureClient.Free;
  end;
end;
```
### Rename Blob
```pascal
var
  LvAzureClient: TAzureClient;
  LvAzureResponseInfo: TAzureResponseInfo;
begin
  LvAzureClient := TAzureClient.Create(cStorageAccount, cAccountKey, apHTTPS);
  try
    if LvAzureClient.RenameBlob('testcontainer', 'ddd18eec-5aa0-4302-8046-0e7d6286020f.jpg', 'Embarcadero.jpg', LvAzureResponseInfo) then
      ShowMessage('Done!');
  finally
    LvAzureClient.Free;
  end;
end;
```
### Exists Folder?
```pascal
var
  LvAzureResponseInfo: TAzureResponseInfo;
  LvTempStr: string;
  LvAzureClient: TAzureClient;
begin
  LvAzureClient :=  TAzureClient.Create(cStorageAccount, cAccountKey, apHTTPS);
  try
    LvTempStr := EmptyStr; //Means root directory!

    //Check if exists a folder
    if LvAzureClient.ExistsFolder('testcontainer', LvTempStr) then
      ShowMessage('Exists!');
  finally
    LvAzureClient.Free;
  end;
end;
```
### Copy Blob
```pascal
var
  LvAzureResponseInfo: TAzureResponseInfo;
  LvAzureClient: TAzureClient;
begin
  LvAzureClient :=  TAzureClient.Create(cStorageAccount, cAccountKey, apHTTPS);
  try
    //Copy a blob from a container to another container.
    if LvAzureClient.CopyBlob('testcontainer', 'Embarcadero.jpg', 'newcontainer', 'newEmbarcadero.jpg', LvAzureResponseInfo) then
      ShowMessage('Done!')
    else
      ShowMessage('Failed!' + #13 + LvAzureResponseInfo.StatusMsg);
  finally
    LvAzureClient.Free;
  end
end;
```
