program SampleProject;

uses
  Vcl.Forms,
  UMain in 'UMain.pas' {AzureOperations};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TAzureOperations, AzureOperations);
  ReportMemoryLeaksOnShutdown := True;
  Application.Run;
end.
