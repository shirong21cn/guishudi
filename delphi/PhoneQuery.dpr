program PhoneQuery;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {frmMain},
  PasteForm in 'PasteForm.pas' {frmPaste};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
