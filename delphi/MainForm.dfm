object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = #25163#26426#21495#24402#23646#22320#25209#37327#26597#35810
  ClientHeight = 640
  ClientWidth = 1008
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1008
    Height = 73
    Align = alTop
    TabOrder = 0
    object lblFile: TLabel
      Left = 16
      Top = 14
      Width = 29
      Height = 15
      Caption = #25991#20214':'
    end
    object lblColumn: TLabel
      Left = 16
      Top = 45
      Width = 42
      Height = 15
      Caption = #21495#30721#21015':'
    end
    object edtFile: TEdit
      Left = 56
      Top = 10
      Width = 492
      Height = 23
      TabOrder = 0
    end
    object btnBrowse: TButton
      Left = 556
      Top = 9
      Width = 75
      Height = 25
      Caption = #27983#35272'...'
      TabOrder = 1
      OnClick = btnBrowseClick
    end
    object cboColumn: TComboBox
      Left = 72
      Top = 41
      Width = 160
      Height = 23
      TabOrder = 2
    end
    object btnLoad: TButton
      Left = 248
      Top = 40
      Width = 90
      Height = 25
      Caption = #36733#20837#25991#20214
      TabOrder = 3
      OnClick = btnLoadClick
    end
    object btnQuery: TButton
      Left = 346
      Top = 40
      Width = 100
      Height = 25
      Caption = #26597#35810#24402#23646#22320
      TabOrder = 4
      OnClick = btnQueryClick
    end
    object btnSaveCsv: TButton
      Left = 454
      Top = 40
      Width = 90
      Height = 25
      Caption = #21478#23384'CSV'
      TabOrder = 5
      OnClick = btnSaveCsvClick
    end
    object btnSaveExcel: TButton
      Left = 552
      Top = 40
      Width = 90
      Height = 25
      Caption = #21478#23384'Excel'
      TabOrder = 6
      OnClick = btnSaveExcelClick
    end
    object btnAbout: TButton
      Left = 650
      Top = 40
      Width = 60
      Height = 25
      Caption = #20851#20110
      TabOrder = 7
      OnClick = btnAboutClick
    end
    object btnPaste: TButton
      Left = 648
      Top = 9
      Width = 80
      Height = 25
      Caption = #30452#25509#31896#36148
      TabOrder = 8
      OnClick = btnPasteClick
    end
  end
  object pcMain: TPageControl
    Left = 0
    Top = 73
    Width = 1008
    Height = 544
    ActivePage = tsDetail
    Align = alClient
    TabOrder = 1
    object tsDetail: TTabSheet
      Caption = #26126#32454
      object grdDetail: TStringGrid
        Left = 0
        Top = 0
        Width = 1000
        Height = 514
        Align = alClient
        ColCount = 2
        DefaultColWidth = 100
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goRowSelect]
        TabOrder = 0
      end
    end
    object tsIsp: TTabSheet
      Caption = #25353#36816#33829#21830#32479#35745
      ImageIndex = 1
      object grdIsp: TStringGrid
        Left = 0
        Top = 0
        Width = 1000
        Height = 514
        Align = alClient
        ColCount = 3
        DefaultColWidth = 120
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goRowSelect]
        TabOrder = 0
      end
    end
    object tsProvince: TTabSheet
      Caption = #25353#24402#23646#30465#32479#35745
      ImageIndex = 2
      object grdProvince: TStringGrid
        Left = 0
        Top = 0
        Width = 1000
        Height = 514
        Align = alClient
        ColCount = 3
        DefaultColWidth = 120
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goRowSelect]
        TabOrder = 0
      end
    end
  end
  object sbMain: TStatusBar
    Left = 0
    Top = 617
    Width = 1008
    Height = 23
    Panels = <>
    SimplePanel = True
    SimpleText = #23601#32490
  end
  object dlgOpen: TOpenDialog
    Left = 640
    Top = 16
  end
  object dlgSave: TSaveDialog
    Options = [ofOverwritePrompt, ofEnableSizing]
    Left = 680
    Top = 16
  end
end
