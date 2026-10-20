object frmPaste: TfrmPaste
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #31896#36148#25163#26426#21495
  ClientHeight = 400
  ClientWidth = 440
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 15
  object lblHint: TLabel
    Left = 0
    Top = 0
    Width = 440
    Height = 24
    Align = alTop
    Alignment = taCenter
    Caption = #27599#34892#19968#20010#25163#26426#21495#65292#19981#21547#21015#21517#65306
    Layout = tlCenter
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 359
    Width = 440
    Height = 41
    Align = alBottom
    TabOrder = 1
    object btnOK: TButton
      Left = 248
      Top = 8
      Width = 75
      Height = 25
      Caption = #30830#23450
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object btnCancel: TButton
      Left = 335
      Top = 8
      Width = 75
      Height = 25
      Cancel = True
      Caption = #21462#28040
      ModalResult = 2
      TabOrder = 1
    end
  end
  object memoNums: TMemo
    Left = 0
    Top = 24
    Width = 440
    Height = 335
    Align = alClient
    ScrollBars = ssVertical
    TabOrder = 0
  end
end
