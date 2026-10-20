# 手机号归属地批量查询工具

输入包含手机号的 CSV/Excel 文件（或直接粘贴号码），根据 `phone_location.csv` 号段库批量查询每个号码的 **归属省、归属市、运营商、邮编**，追加到源数据后输出，同时生成 **按运营商** 和 **按归属省** 的分类统计（数量 + 占比）。

提供两个版本：Python 命令行版 和 Delphi 13 桌面版。

## 目录结构

```
guishudi\
├── 1.txt.csv               测试数据
├── phone_query.py          Python 命令行版主程序
├── phone_location.csv      号段库（本工具实际使用，约 45MB / 67 万+ 条）
├── phone_location.db       号段库 SQLite 版（备用，未使用）
├── phone_location.json     号段库 JSON 版（备用，未使用）
├── phone_location.sql      号段库 SQL 导入脚本（备用，未使用）
├── 归属地查询.exe           Delphi 版编译产物，双击即用（需号段库在同目录）
├── README.md               本说明文档
└── delphi\                 Delphi 13 (RAD Studio 13) 源码工程
    ├── PhoneQuery.dpr        工程主文件
    ├── PhoneQuery.dproj      工程配置文件
    ├── PhoneQuery.res        资源文件（编译生成）
    ├── MainForm.pas / .dfm   主窗体：文件载入、号段匹配、统计、CSV 导出全部逻辑
    ├── PasteForm.pas / .dfm  「直接粘贴」弹窗
    └── *.dcu                 编译中间文件，可删除
```

## 匹配原理

号段库 `phone_location.csv` 的 `phone` 列为 7 位号段前缀，取手机号前 7 位做精确匹配：

```
id,pref,phone,province,city,isp,isp_type,post_code,city_code,area_code,create_time
1,130,1300000,山东,济南,中国联通,2,250000,0531,370100,...
```

号码清洗规则：去除非数字字符、自动剥离 `86` 国际前缀；Excel 数字单元格自动还原科学计数法；匹配失败标记为「未知」。

## Python 版

文件：`phone_query.py`

**依赖**：`pandas`（读 Excel 需另装 `openpyxl`）

**用法**：

```powershell
python phone_query.py <输入文件.csv/.xlsx> <号码列名> [-o 输出文件]

python phone_query.py data.xlsx 手机号
python phone_query.py data.csv 电话 -o result.xlsx
```

**输出**：

- 默认生成 `原名_已标注.后缀`，在源数据后追加 4 列：`归属省`、`归属市`、`运营商`、`邮编`
- Excel 输出含 3 个 sheet：明细 / 按运营商统计 / 按归属省统计
- CSV 输出额外生成 `原名_已标注_统计.csv`
- 统计结果同时在控制台打印，CSV 为 UTF-8 带 BOM（Excel 直接打开不乱码）

## Delphi 13 版

工程：`delphi\PhoneQuery.dpr`（VCL 应用，含 `MainForm`、`PasteForm` 两个单元）

**准备**：编译依赖 [Excel4Delphi](https://github.com/DelphiComponents/Excel4Delphi)（zexmlss 的分支改名版），将其 `source` 目录加入 IDE 的 Library Path 即可，无需安装组件包；读取旧版 .xls 另需本机已安装的 XLSSuit7（仅用其读取，写入不用）；编译后将 `phone_location.csv` 放到 exe 同目录，不在时会弹框手动选择，只需选一次。

**界面操作**：

1. `浏览...` 选择 .csv/.xlsx/.xls 文件 → `载入文件`（表头自动填入「号码列」下拉框）
2. 在下拉框选择号码所在列 → `查询归属地`，状态栏显示匹配进度与成功率
3. 或使用「直接粘贴」：弹窗中每行粘贴一个手机号（不含列名），确定后立即查询
4. 结果区三个页签均为可见表格：明细（源列+4 列）/ 按运营商统计 / 按归属省统计（按数量降序）
5. `另存CSV` / `另存Excel` 按当前激活页签导出对应内容，默认文件名分别为 `原名_已标注.*`、`_按运营商统计.*`、`_按归属省统计.*`；粘贴模式下文件名为 `粘贴数据_*.*`
6. 「关于」显示作者信息

**说明**：

- Excel 文件（.xlsx）通过 **Excel4Delphi** 组件读写，**不再需要安装 Microsoft Excel**；旧版 .xls（BIFF 二进制格式）通过 **XLSSuit7** 读取（已实测 5 万行无截断；试用版仅写入时 A1 有水印，读取无限制，本程序只用其读取）
- 输入 CSV 编码自动识别：先探测 BOM，无 BOM 时严格校验 UTF-8，否则回退系统 ANSI(GBK)
- 导出的 CSV 统一为 UTF-8 带 BOM，Excel 直接打开不乱码
- 另存 Excel 统一输出 .xlsx（Excel4Delphi 写）

**作者**：老皮　QQ 30922884　[www.2pascal.com　github/shirong21cn](http://www.2pascal.com　github/shirong21cn)

## 数据来源

号段库来自 GitHub 开源项目 [ggwork/phone\_location](https://github.com/ggwork/phone_location)，本工具仅使用其中的 `phone_location.csv` 做离线查询，未对数据做任何修改。数据的准确性、时效性以原项目为准。
