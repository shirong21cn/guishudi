unit PasteForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmPaste = class(TForm)
    lblHint: TLabel;
    pnlBottom: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    memoNums: TMemo;
  end;

implementation

{$R *.dfm}

end.
