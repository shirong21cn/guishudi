unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.StrUtils,
  System.Generics.Collections, System.Generics.Defaults,
  System.IOUtils, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.Grids, Vcl.ComCtrls, Vcl.ExtCtrls;

type
  TPhoneInfo = record
    Province: string;
    City: string;
    Isp: string;
    PostCode: string;
  end;

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblFile: TLabel;
    edtFile: TEdit;
    btnBrowse: TButton;
    lblColumn: TLabel;
    cboColumn: TComboBox;
    btnLoad: TButton;
    btnQuery: TButton;
    btnSaveCsv: TButton;
    btnAbout: TButton;
    btnPaste: TButton;
    pcMain: TPageControl;
    tsDetail: TTabSheet;
    tsIsp: TTabSheet;
    tsProvince: TTabSheet;
    grdDetail: TStringGrid;
    grdIsp: TStringGrid;
    grdProvince: TStringGrid;
    sbMain: TStatusBar;
    dlgOpen: TOpenDialog;
    dlgSave: TSaveDialog;
    procedure btnBrowseClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnQueryClick(Sender: TObject);
    procedure btnSaveCsvClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
    procedure btnPasteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FHeaders: TArray<string>;
    FRows: TArray<TArray<string>>;
    FOutRows: TArray<TArray<string>>;
    FDb: TDictionary<string, TPhoneInfo>;
    FDbLoaded: Boolean;
    procedure LoadPhoneDb;
    function DetectFileEncoding(const AFileName: string): TEncoding;
    function ReadCsvFile(const AFileName: string): TArray<TArray<string>>;
    function ReadXlsxFile(const AFileName: string): TArray<TArray<string>>;
    function SplitCsvLine(const ALine: string): TArray<string>;
    function NormalizeNumber(const AValue: string): string;
    function CsvEscape(const AValue: string): string;
    procedure SaveGridToCsv(AGrid: TStringGrid; const AFileName: string);
    procedure FillDetailGrid;
    procedure BuildStats;
    procedure Status(const AMsg: string);
    procedure RunPasteQuery(ALines: TStrings);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  System.Win.ComObj,
  PasteForm;

{ ---------- Form events ---------- }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FDb := TDictionary<string, TPhoneInfo>.Create;
  FDbLoaded := False;
  dlgOpen.Filter :=
    '表格文件 (*.csv;*.xlsx;*.xls)|*.csv;*.xlsx;*.xls|' +
    'CSV 文件 (*.csv)|*.csv|' +
    'Excel 文件 (*.xlsx;*.xls)|*.xlsx;*.xls';
  dlgSave.Filter := 'CSV 文件 (*.csv)|*.csv';
  dlgSave.DefaultExt := 'csv';
  sbMain.SimplePanel := True;
  sbMain.SimpleText := '就绪';
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FDb.Free;
end;

{ ---------- Helpers ---------- }

procedure TfrmMain.Status(const AMsg: string);
begin
  sbMain.SimpleText := AMsg;
end;

function TfrmMain.SplitCsvLine(const ALine: string): TArray<string>;
var
  sb: TStringBuilder;
  inQ: Boolean;
  i: Integer;
  ch: Char;
  list: TList<string>;
begin
  list := TList<string>.Create;
  sb := TStringBuilder.Create;
  try
    inQ := False;
    i := 1;
    while i <= Length(ALine) do
    begin
      ch := ALine[i];
      if ch = '"' then
      begin
        if inQ and (i < Length(ALine)) and (ALine[i + 1] = '"') then
        begin
          sb.Append('"');
          Inc(i, 2);
          Continue;
        end
        else
          inQ := not inQ;
      end
      else if (ch = ',') and not inQ then
      begin
        list.Add(sb.ToString);
        sb.Clear;
      end
      else
        sb.Append(ch);
      Inc(i);
    end;
    list.Add(sb.ToString);
    Result := list.ToArray;
  finally
    sb.Free;
    list.Free;
  end;
end;

function TfrmMain.NormalizeNumber(const AValue: string): string;
var
  sb: TStringBuilder;
  ch: Char;
  s: string;
begin
  sb := TStringBuilder.Create;
  try
    for ch in AValue do
      if CharInSet(ch, ['0'..'9']) then
        sb.Append(ch);
    s := sb.ToString;
  finally
    sb.Free;
  end;
  if (Length(s) = 13) and (Copy(s, 1, 2) = '86') then
    Delete(s, 1, 2);
  if Length(s) >= 7 then
    Result := Copy(s, 1, 7)
  else
    Result := '';
end;

function TfrmMain.CsvEscape(const AValue: string): string;
begin
  if (Pos(',', AValue) > 0) or (Pos('"', AValue) > 0) or
     (Pos(#13, AValue) > 0) or (Pos(#10, AValue) > 0) then
    Result := '"' + StringReplace(AValue, '"', '""', [rfReplaceAll]) + '"'
  else
    Result := AValue;
end;

{ ---------- Load / Read files ---------- }

procedure TfrmMain.LoadPhoneDb;
var
  path: string;
  sr: TStreamReader;
  line: string;
  parts: TArray<string>;
  info: TPhoneInfo;
  cnt: Integer;
  savedFilter: string;
begin
  if FDbLoaded then Exit;
  path := TPath.Combine(ExtractFilePath(Application.ExeName), 'phone_location.csv');
  if not TFile.Exists(path) then
  begin
    savedFilter := dlgOpen.Filter;
    dlgOpen.Filter := 'CSV 文件 (*.csv)|*.csv';
    dlgOpen.Title := '请选择 phone_location.csv 号段库文件';
    try
      if not dlgOpen.Execute then
      begin
        Status('未选择号段库文件');
        Exit;
      end;
      path := dlgOpen.FileName;
    finally
      dlgOpen.Filter := savedFilter;
    end;
  end;
  Screen.Cursor := crHourGlass;
  cnt := 0;
  Status('正在加载号段库 ...');
  Application.ProcessMessages;
  try
    sr := TStreamReader.Create(path, DetectFileEncoding(path), True);
    try
      while not sr.EndOfStream do
      begin
        line := sr.ReadLine;
        if line = '' then Continue;
        parts := SplitCsvLine(line);
        if (Length(parts) < 8) or SameText(parts[0], 'id') then Continue;
        info.Province := parts[3];
        info.City := parts[4];
        info.Isp := parts[5];
        info.PostCode := parts[7];
        if not FDb.ContainsKey(parts[2]) then
          FDb.Add(parts[2], info);
        Inc(cnt);
        if cnt mod 100000 = 0 then
        begin
          sbMain.SimpleText := Format('正在加载号段库 ... %d 条', [cnt]);
          Application.ProcessMessages;
        end;
      end;
    finally
      sr.Free;
    end;
    FDbLoaded := True;
    Status(Format('号段库加载完成，共 %d 条', [FDb.Count]));
  finally
    Screen.Cursor := crDefault;
  end;
end;

function TfrmMain.DetectFileEncoding(const AFileName: string): TEncoding;
{ 先按 BOM 判断；无 BOM 时对前 64KB 做严格 UTF-8 校验，
  通过则视为 UTF-8，否则回退系统 ANSI(GBK) }
var
  fs: TFileStream;
  buf: TBytes;
  n, i, extra, j, len: Integer;

  function LeadExtra(b: Byte): Integer;  // 返回多字节序列的后续字节数，非法前导返回 -1
  begin
    if (b = $C0) or (b = $C1) or (b >= $F5) then
      Result := -1                        // 非法前导字节
    else if (b and $E0) = $C0 then
      Result := 1
    else if (b and $F0) = $E0 then
      Result := 2
    else if (b and $F8) = $F0 then
      Result := 3
    else
      Result := -1;
  end;

begin
  fs := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(buf, Integer(Min(65536, fs.Size)));
    n := fs.Read(buf, 0, Length(buf));
  finally
    fs.Free;
  end;
  SetLength(buf, n);

  if (n >= 3) and (buf[0] = $EF) and (buf[1] = $BB) and (buf[2] = $BF) then
    Exit(TEncoding.UTF8);
  if (n >= 2) and (buf[0] = $FF) and (buf[1] = $FE) then
    Exit(TEncoding.Unicode);
  if (n >= 2) and (buf[0] = $FE) and (buf[1] = $FF) then
    Exit(TEncoding.BigEndianUnicode);

  len := n;
  i := 0;
  while i < len do
  begin
    if buf[i] < $80 then
      Inc(i)
    else
    begin
      extra := LeadExtra(buf[i]);
      if extra < 0 then
        Exit(TEncoding.Default);
      if i + extra >= len then Break;      // 采样边界截断，视为合法
      for j := 1 to extra do
        if (buf[i + j] and $C0) <> $80 then
          Exit(TEncoding.Default);
      Inc(i, extra + 1);
    end;
  end;
  Result := TEncoding.UTF8;
end;

function TfrmMain.ReadCsvFile(const AFileName: string): TArray<TArray<string>>;
var
  sr: TStreamReader;
  line: string;
  list: TList<TArray<string>>;
begin
  sr := TStreamReader.Create(AFileName, DetectFileEncoding(AFileName), True);
  list := TList<TArray<string>>.Create;
  try
    while not sr.EndOfStream do
    begin
      line := sr.ReadLine;
      if line = '' then Continue;
      list.Add(SplitCsvLine(line));
    end;
    Result := list.ToArray;
  finally
    sr.Free;
    list.Free;
  end;
end;

function TfrmMain.ReadXlsxFile(const AFileName: string): TArray<TArray<string>>;
var
  excel, wb, ws, data: OleVariant;
  r, c, rMax, cMax: Integer;
  list: TList<TArray<string>>;
  row: TArray<string>;
  v: Variant;
begin
  try
    excel := CreateOleObject('Excel.Application');
  except
    raise Exception.Create('无法创建 Excel 对象，请确认已安装 Microsoft Excel。');
  end;
  list := TList<TArray<string>>.Create;
  try
    excel.Visible := False;
    excel.DisplayAlerts := False;
    wb := excel.Workbooks.Open(AFileName, 0, True);
    try
      ws := wb.Worksheets[1];
      data := ws.UsedRange.Value2;
      if VarIsArray(data) then
      begin
        rMax := VarArrayHighBound(data, 1);
        cMax := VarArrayHighBound(data, 2);
        for r := 1 to rMax do
        begin
          SetLength(row, cMax);
          for c := 1 to cMax do
          begin
            v := data[r, c];
            if VarIsEmpty(v) or VarIsNull(v) then
              row[c - 1] := ''
            else if VarIsFloat(v) then
              row[c - 1] := FormatFloat('0.######', v)
            else
              row[c - 1] := VarToStrDef(v, '');
          end;
          list.Add(row);
        end;
      end
      else
      begin
        SetLength(row, 1);
        row[0] := VarToStrDef(data, '');
        list.Add(row);
      end;
    finally
      wb.Close(False);
    end;
  finally
    excel.Quit;
    Result := list.ToArray;
    list.Free;
  end;
end;

{ ---------- UI Actions ---------- }

procedure TfrmMain.btnBrowseClick(Sender: TObject);
begin
  if dlgOpen.Execute then
    edtFile.Text := dlgOpen.FileName;
end;

procedure TfrmMain.btnLoadClick(Sender: TObject);
var
  ext: string;
  all: TArray<TArray<string>>;
  s: string;
  i: Integer;
begin
  if not TFile.Exists(edtFile.Text) then
  begin
    Status('文件不存在');
    Exit;
  end;
  ext := LowerCase(ExtractFileExt(edtFile.Text));
  Screen.Cursor := crHourGlass;
  try
    if (ext = '.xlsx') or (ext = '.xls') then
      all := ReadXlsxFile(edtFile.Text)
    else
      all := ReadCsvFile(edtFile.Text);
  except
    on E: Exception do
    begin
      Screen.Cursor := crDefault;
      Status('读文件失败: ' + E.Message);
      Exit;
    end;
  end;

  if Length(all) = 0 then
  begin
    Screen.Cursor := crDefault;
    Status('文件为空');
    Exit;
  end;

  FHeaders := all[0];
  SetLength(FRows, Length(all) - 1);
  for i := 1 to High(all) do
    FRows[i - 1] := all[i];

  cboColumn.Clear;
  for s in FHeaders do
    cboColumn.Items.Add(s);
  if cboColumn.Items.Count > 0 then
    cboColumn.ItemIndex := 0;

  SetLength(FOutRows, 0);
  grdDetail.RowCount := 2;
  grdDetail.ColCount := 1;
  grdIsp.RowCount := 2;
  grdIsp.ColCount := 1;
  grdProvince.RowCount := 2;
  grdProvince.ColCount := 1;

  Status(Format('文件已加载，共 %d 行，%d 列', [Length(FRows), Length(FHeaders)]));
  Screen.Cursor := crDefault;
end;

procedure TfrmMain.btnQueryClick(Sender: TObject);
var
  colIdx, i, c, n, matched: Integer;
  key: string;
  info: TPhoneInfo;
  row, outRow: TArray<string>;
  colName: string;
  found: Boolean;
begin
  if Length(FRows) = 0 then
  begin
    Status('请先载入文件');
    Exit;
  end;

  colName := Trim(cboColumn.Text);
  colIdx := -1;
  found := False;
  for i := 0 to High(FHeaders) do
    if SameText(FHeaders[i], colName) then
    begin
      colIdx := i;
      found := True;
      Break;
    end;
  if not found then
  begin
    Status(Format('列名 %s 不存在', [colName]));
    Exit;
  end;

  LoadPhoneDb;
  if not FDbLoaded then Exit;

  n := Length(FHeaders);
  SetLength(FOutRows, Length(FRows));
  matched := 0;
  Screen.Cursor := crHourGlass;
  try
    for i := 0 to High(FRows) do
    begin
      row := FRows[i];
      SetLength(outRow, n + 4);
      for c := 0 to n - 1 do
        if c < Length(row) then outRow[c] := row[c] else outRow[c] := '';

      key := '';
      if colIdx < Length(row) then
        key := NormalizeNumber(row[colIdx]);

      if (key <> '') and FDb.TryGetValue(key, info) then
      begin
        outRow[n]   := info.Province;
        outRow[n+1] := info.City;
        outRow[n+2] := info.Isp;
        outRow[n+3] := info.PostCode;
        Inc(matched);
      end
      else
      begin
        outRow[n]   := '未知';
        outRow[n+1] := '未知';
        outRow[n+2] := '未知';
        outRow[n+3] := '未知';
      end;
      FOutRows[i] := outRow;

      if (i + 1) mod 5000 = 0 then
      begin
        Status(Format('正在查询 ... %d / %d', [i + 1, Length(FRows)]));
        Application.ProcessMessages;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  FillDetailGrid;
  BuildStats;
  Status(Format('查询完成，匹配 %d / %d 条', [matched, Length(FRows)]));
  pcMain.ActivePage := tsDetail;
end;

procedure TfrmMain.FillDetailGrid;
var
  n, r, c: Integer;
const
  NewCols: array[0..3] of string = ('归属省', '归属市', '运营商', '邮编');
begin
  n := Length(FHeaders);
  grdDetail.RowCount := Length(FOutRows) + 1;
  grdDetail.ColCount := n + 4;
  grdDetail.FixedRows := 1;

  for c := 0 to n - 1 do
    grdDetail.Cells[c, 0] := FHeaders[c];
  for c := 0 to 3 do
    grdDetail.Cells[n + c, 0] := NewCols[c];

  grdDetail.Perform(WM_SETREDRAW, 0, 0);
  try
    for r := 0 to High(FOutRows) do
    begin
      for c := 0 to n + 3 do
        grdDetail.Cells[c, r + 1] := FOutRows[r][c];
    end;
  finally
    grdDetail.Perform(WM_SETREDRAW, 1, 0);
    grdDetail.Invalidate;
  end;
end;

procedure TfrmMain.BuildStats;
var
  n: Integer;
  dIsp, dProv: TDictionary<string, Integer>;
  i, total: Integer;
  k: string;
  comp: IComparer<TPair<string, Integer>>;
  procedure FillGrid(AGrid: TStringGrid; const ATitle: string;
                     const ADict: TDictionary<string, Integer>);
  var
    a: TArray<TPair<string, Integer>>;
    rr: Integer;
    p: Double;
  begin
    a := ADict.ToArray;
    TArray.Sort<TPair<string, Integer>>(a, comp);
    AGrid.RowCount := Length(a) + 1;
    AGrid.ColCount := 3;
    AGrid.FixedRows := 1;
    AGrid.Cells[0, 0] := ATitle;
    AGrid.Cells[1, 0] := '数量';
    AGrid.Cells[2, 0] := '占比';
    for rr := 0 to High(a) do
    begin
      AGrid.Cells[0, rr + 1] := a[rr].Key;
      AGrid.Cells[1, rr + 1] := IntToStr(a[rr].Value);
      p := IfThen(total = 0, 0, a[rr].Value * 100.0 / total);
      AGrid.Cells[2, rr + 1] := FormatFloat('0.00', p) + '%';
    end;
  end;
begin
  n := Length(FHeaders);
  dIsp := TDictionary<string, Integer>.Create;
  dProv := TDictionary<string, Integer>.Create;
  try
    total := Length(FOutRows);
    for i := 0 to High(FOutRows) do
    begin
      k := FOutRows[i][n + 2];   // 运营商
      if k = '' then k := '未知';
      if dIsp.ContainsKey(k) then
        dIsp[k] := dIsp[k] + 1
      else
        dIsp.Add(k, 1);

      k := FOutRows[i][n];       // 归属省
      if k = '' then k := '未知';
      if dProv.ContainsKey(k) then
        dProv[k] := dProv[k] + 1
      else
        dProv.Add(k, 1);
    end;

    comp := TComparer<TPair<string, Integer>>.Construct(
      function(const L, R: TPair<string, Integer>): Integer
      begin
        Result := R.Value - L.Value;
      end);

    FillGrid(grdIsp, '运营商', dIsp);
    FillGrid(grdProvince, '归属省', dProv);
  finally
    dIsp.Free;
    dProv.Free;
  end;
end;

procedure TfrmMain.SaveGridToCsv(AGrid: TStringGrid; const AFileName: string);
var
  sw: TStreamWriter;
  sb: TStringBuilder;
  r, c: Integer;
begin
  sw := TStreamWriter.Create(AFileName, False, TEncoding.UTF8);
  sb := TStringBuilder.Create;
  try
    for r := 0 to AGrid.RowCount - 1 do
    begin
      sb.Clear;
      for c := 0 to AGrid.ColCount - 1 do
      begin
        if c > 0 then sb.Append(',');
        sb.Append(CsvEscape(AGrid.Cells[c, r]));
      end;
      sw.WriteLine(sb.ToString);
    end;
  finally
    sb.Free;
    sw.Free;
  end;
end;

procedure TfrmMain.btnSaveCsvClick(Sender: TObject);
var
  baseName, suffix: string;
  grid: TStringGrid;
begin
  if Length(FOutRows) = 0 then
  begin
    Status('没有可保存的数据，请先查询');
    Exit;
  end;

  baseName := ChangeFileExt(ExtractFileName(edtFile.Text), '');
  if baseName = '' then
    baseName := '粘贴数据';
  if pcMain.ActivePage = tsIsp then
  begin
    grid := grdIsp;
    suffix := '_按运营商统计';
  end
  else if pcMain.ActivePage = tsProvince then
  begin
    grid := grdProvince;
    suffix := '_按归属省统计';
  end
  else
  begin
    grid := grdDetail;
    suffix := '_已标注';
  end;

  dlgSave.FileName := baseName + suffix;
  if not dlgSave.Execute then Exit;

  SaveGridToCsv(grid, dlgSave.FileName);
  Status('已保存: ' + dlgSave.FileName);
end;

procedure TfrmMain.btnAboutClick(Sender: TObject);
begin
  Application.MessageBox(
    PChar(
      '手机号归属地批量查询' + sLineBreak + sLineBreak +
      '作者：老皮' + sLineBreak +
      'QQ：30922884' + sLineBreak +
      '网站：www.2pascal.com' + sLineBreak +
      'GitHub：GitHub shirong21cn' + sLineBreak + sLineBreak +
      '数据来源：GitHub ggwork/phone_location'),
    '关于', MB_ICONINFORMATION);
end;

procedure TfrmMain.btnPasteClick(Sender: TObject);
var
  f: TfrmPaste;
begin
  f := TfrmPaste.Create(Self);
  try
    if f.ShowModal = mrOk then
      RunPasteQuery(f.memoNums.Lines);
  finally
    f.Free;
  end;
end;

procedure TfrmMain.RunPasteQuery(ALines: TStrings);
var
  i, cnt: Integer;
  s: string;
begin
  cnt := 0;
  for i := 0 to ALines.Count - 1 do
    if Trim(ALines[i]) <> '' then
      Inc(cnt);
  if cnt = 0 then
  begin
    Status('未粘贴任何号码');
    Exit;
  end;

  SetLength(FHeaders, 1);
  FHeaders[0] := '手机号';
  SetLength(FRows, cnt);
  cnt := 0;
  for i := 0 to ALines.Count - 1 do
  begin
    s := Trim(ALines[i]);
    if s = '' then Continue;
    SetLength(FRows[cnt], 1);
    FRows[cnt][0] := s;
    Inc(cnt);
  end;

  cboColumn.Clear;
  cboColumn.Items.Add('手机号');
  cboColumn.ItemIndex := 0;
  edtFile.Text := '';
  btnQueryClick(nil);
end;

end.
