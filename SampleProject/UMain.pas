unit UMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Imaging.jpeg, Cloud.Client.Azure;

type
  TAzureOperations = class(TForm)
    Btn_ExistsFolder: TButton;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    Btn_LoadContainers: TButton;
    Panel1: TPanel;
    Img_Blob: TImage;
    Btn_DownloadBlob: TButton;
    Btn_RenameBlob: TButton;
    Btn_LoadBlobs: TButton;
    Btn_UploadBlob: TButton;
    Btn_CopyBlob: TButton;
    procedure Btn_ExistsFolderClick(Sender: TObject);
    procedure Btn_LoadContainersClick(Sender: TObject);
    procedure Btn_DownloadBlobClick(Sender: TObject);
    procedure Btn_RenameBlobClick(Sender: TObject);
    procedure Btn_LoadBlobsClick(Sender: TObject);
    procedure Btn_UploadBlobClick(Sender: TObject);
    procedure Btn_CopyBlobClick(Sender: TObject);
  private
    procedure LoadImageFromStream(AImage: TImage; AData: TStream);
    function LoadContainersList(AStorageAccountName: string; out AContainerList: TStringList): Boolean;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AzureOperations: TAzureOperations;

const cStorageAccount = 'Your Azure Storage Account';
      cAccountKey = 'Your Azure Account Key';

implementation

{$R *.dfm}

procedure TAzureOperations.Btn_ExistsFolderClick(Sender: TObject);
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

procedure TAzureOperations.Btn_LoadBlobsClick(Sender: TObject);//List blobs starting with a pattern (recursively or not)
var
  LvAzureResponseInfo: TAzureResponseInfo;
  LvBlobObj: TAzureBlobObject;
  LvAzureClient: TAzureClient;
  LvBlobList: TBlobList;
begin
  LvAzureClient := TAzureClient.Create(cStorageAccount, cAccountKey, apHTTPS);
  try
    LvBlobList := LvAzureClient.ListBlobs('testcontainer', EmptyStr, True, LvAzureResponseInfo);
    for LvBlobObj in LvBlobList do
      Memo1.Lines.Add(LvBlobObj.Name);
  finally
    LvAzureClient.Free;
    if Assigned(LvBlobList) then
      LvBlobList.Free;
  end;
end;

procedure TAzureOperations.Btn_LoadContainersClick(Sender: TObject);
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

procedure TAzureOperations.Btn_CopyBlobClick(Sender: TObject);
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

procedure TAzureOperations.Btn_DownloadBlobClick(Sender: TObject); //Download a blob file to a stream
var
  LvTmpStream : TMemoryStream;
  LvAzureResponseInfo: TAzureResponseInfo;
  LvAzureClient: TAzureClient;
begin
  LvAzureClient := TAzureClient.Create(cStorageAccount, cAccountKey, apHTTPS);
  try

    LvTmpStream := TMemoryStream.Create;
    try
      if LvAzureClient.DownloadBlob('testcontainer', 'Embarcadero.jpg', LvAzureResponseInfo, LvTmpStream) then
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

procedure TAzureOperations.Btn_RenameBlobClick(Sender: TObject); //Rename a blob
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

procedure TAzureOperations.Btn_UploadBlobClick(Sender: TObject);
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
        ShowMessage('Uploaded!')
    end;
  finally
    LvAzureClient.Free;
  end;
end;

function TAzureOperations.LoadContainersList(AStorageAccountName: string; out AContainerList: TStringList): Boolean;
var
  LvAzureResponseInfo: TAzureResponseInfo;
  LvAzureClient: TAzureClient;
begin
  Result := True;
  LvAzureClient := TAzureClient.Create(cStorageAccount, cAccountKey, apHTTPS);
  try
    LvAzureClient.ListContainers(AStorageAccountName, LvAzureResponseInfo, AContainerList);
    if (AContainerList.Count = 0) and (LvAzureResponseInfo.StatusCode <> 200) then
    begin
      Result := False;
      ShowMessage('Operation Failed!' + #13 + LvAzureResponseInfo.StatusMsg);
    end;
  finally
    LvAzureClient.Free;
  end;
end;

procedure TAzureOperations.LoadImageFromStream(AImage: TImage; AData: TStream);
var
  JPEGImage: TJPEGImage;
begin
  AData.Position := 0;
  JPEGImage := TJPEGImage.Create;
  try
    JPEGImage.LoadFromStream(AData);
    AImage.Picture.Assign(JPEGImage);
  finally
    JPEGImage.Free;
  end;
end;

end.
