# -*- coding: utf-8 -*-
"""
手机号归属地批量查询工具 write by laopi （www.2pascal.com）
用法:
    python phone_query.py <输入文件.csv/.xlsx> <号码列名> [-o 输出文件]
示例:
    python phone_query.py data.xlsx 手机号
    python phone_query.py data.csv 电话 -o result.xlsx

数据来源 GitHub ggwork/phone_location（2026-04 版，516470 条记录）
"""
import argparse
import sys
from pathlib import Path

import pandas as pd

DB_PATH = Path(__file__).parent / "phone_location.csv"


def load_db():
    """加载号段库，返回 {7位号段: (省, 市, 运营商, 邮编)} 字典"""
    df = pd.read_csv(DB_PATH, dtype=str, encoding="utf-8-sig",
                     usecols=["phone", "province", "city", "isp", "post_code"])
    df = df.drop_duplicates(subset="phone")
    return {r.phone: (r.province, r.city, r.isp, r.post_code)
            for r in df.itertuples()}


def normalize_number(value):
    """提取纯数字号码，处理浮点、86前缀等情况"""
    if pd.isna(value):
        return ""
    s = str(value).strip()
    if s.endswith(".0"):          # excel 读出的浮点尾巴
        s = s[:-2]
    s = "".join(ch for ch in s if ch.isdigit())
    if len(s) == 13 and s.startswith("86"):
        s = s[2:]
    return s


def lookup(value, db):
    s = normalize_number(value)
    if len(s) < 7:
        return ("未知", "未知", "未知", "未知")
    return db.get(s[:7], ("未知", "未知", "未知", "未知"))


def read_input(path: Path) -> pd.DataFrame:
    suffix = path.suffix.lower()
    if suffix == ".csv":
        return pd.read_csv(path, dtype=str, encoding="utf-8-sig")
    if suffix in (".xlsx", ".xls"):
        return pd.read_excel(path, dtype=str)
    sys.exit(f"不支持的文件类型: {suffix}（仅支持 .csv/.xlsx/.xls）")


def make_stats(df):
    by_isp = (df.groupby("运营商", dropna=False).size()
                .reset_index(name="数量").sort_values("数量", ascending=False))
    by_prov = (df.groupby("归属省", dropna=False).size()
                 .reset_index(name="数量").sort_values("数量", ascending=False))
    by_city = (df.groupby(["归属省", "归属市"], dropna=False).size()
                 .reset_index(name="数量").sort_values("数量", ascending=False))
    for t in (by_isp, by_prov, by_city):
        total = t["数量"].sum()
        t["占比"] = (t["数量"] / total * 100).round(2).astype(str) + "%"
    return by_isp, by_prov, by_city


def main():
    ap = argparse.ArgumentParser(description="手机号归属地批量查询")
    ap.add_argument("input", help="输入文件 (.csv/.xlsx/.xls)")
    ap.add_argument("column", help="号码所在列的列名")
    ap.add_argument("-o", "--output", help="输出文件名（默认: 原名_已标注.后缀）")
    args = ap.parse_args()

    in_path = Path(args.input)
    if not in_path.exists():
        sys.exit(f"文件不存在: {in_path}")

    df = read_input(in_path)
    if args.column not in df.columns:
        sys.exit(f"列名 '{args.column}' 不存在，现有列: {list(df.columns)}")

    print("加载号段库 ...")
    db = load_db()

    print(f"共 {len(df)} 行，开始查询 ...")
    result = df[args.column].map(lambda v: lookup(v, db))
    df[["归属省", "归属市", "运营商", "邮编"]] = pd.DataFrame(
        result.tolist(), index=df.index)

    # 输出文件
    if args.output:
        out_path = Path(args.output)
    else:
        out_path = in_path.with_name(f"{in_path.stem}_已标注{in_path.suffix}")

    by_isp, by_prov, by_city = make_stats(df)

    if out_path.suffix.lower() in (".xlsx", ".xls"):
        with pd.ExcelWriter(out_path) as w:
            df.to_excel(w, index=False, sheet_name="明细")
            by_isp.to_excel(w, index=False, sheet_name="按运营商统计")
            by_prov.to_excel(w, index=False, sheet_name="按归属省统计")
            by_city.to_excel(w, index=False, sheet_name="按归属市统计")
    else:
        df.to_csv(out_path, index=False, encoding="utf-8-sig")
        stats_path = out_path.with_name(f"{out_path.stem}_统计.csv")
        with open(stats_path, "w", encoding="utf-8-sig", newline="") as f:
            f.write("=== 按运营商统计 ===\n")
            by_isp.to_csv(f, index=False)
            f.write("\n=== 按归属省统计 ===\n")
            by_prov.to_csv(f, index=False)
            f.write("\n=== 按归属市统计 ===\n")
            by_city.to_csv(f, index=False)
        print(f"统计文件: {stats_path}")

    matched = (df["运营商"] != "未知").sum()
    print(f"\n查询完成: {matched}/{len(df)} 条匹配成功，{len(df)-matched} 条未匹配")
    print(f"输出文件: {out_path}")

    pd.set_option("display.unicode.east_asian_width", True)
    print("\n===== 按运营商统计 =====")
    print(by_isp.to_string(index=False))
    print("\n===== 按归属省统计 =====")
    print(by_prov.to_string(index=False))
    print("\n===== 按归属市统计 =====")
    print(by_city.to_string(index=False))


if __name__ == "__main__":
    main()
