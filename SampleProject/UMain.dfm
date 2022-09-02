object AzureOperations: TAzureOperations
  Left = 0
  Top = 0
  Caption = 'Azure Client Operations.'
  ClientHeight = 175
  ClientWidth = 452
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object Btn_ExistsFolder: TButton
    Left = 8
    Top = 142
    Width = 115
    Height = 25
    Caption = 'Exists Folder?'
    TabOrder = 0
    OnClick = Btn_ExistsFolderClick
  end
  object Memo1: TMemo
    Left = 125
    Top = 8
    Width = 86
    Height = 161
    TabOrder = 1
  end
  object Btn_LoadContainers: TButton
    Left = 8
    Top = 8
    Width = 115
    Height = 25
    Caption = 'Load Container List'
    TabOrder = 2
    OnClick = Btn_LoadContainersClick
  end
  object Panel1: TPanel
    Left = 217
    Top = 8
    Width = 227
    Height = 159
    TabOrder = 3
    object Img_Blob: TImage
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 219
      Height = 151
      Align = alClient
      Stretch = True
      ExplicitLeft = -1
      ExplicitTop = 0
      ExplicitWidth = 228
      ExplicitHeight = 159
    end
  end
  object Btn_DownloadBlob: TButton
    Left = 8
    Top = 62
    Width = 115
    Height = 25
    Caption = 'Download Blob'
    TabOrder = 4
    OnClick = Btn_DownloadBlobClick
  end
  object Btn_RenameBlob: TButton
    Left = 8
    Top = 115
    Width = 115
    Height = 25
    Caption = 'Rename Blob'
    TabOrder = 5
    OnClick = Btn_RenameBlobClick
  end
  object Btn_LoadBlobs: TButton
    Left = 8
    Top = 35
    Width = 114
    Height = 25
    Caption = 'Load Blobs List'
    TabOrder = 6
    OnClick = Btn_LoadBlobsClick
  end
  object Btn_UploadBlob: TButton
    Left = 8
    Top = 88
    Width = 115
    Height = 25
    Caption = 'Upload Blob'
    TabOrder = 7
    OnClick = Btn_UploadBlobClick
  end
  object OpenDialog1: TOpenDialog
    Left = 312
    Top = 72
  end
end
