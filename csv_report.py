
# csv_report.py
# Simple CLI to filter, aggregate and visualize a CSV using pandas.
# Usage example:
#   python csv_report.py --input sales.csv --filter "status=completed" --group-by region --agg sum:amount --out report.csv --plot report.png

import argparse
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

def parse_filters(filters):
    conds = []
    for f in filters:
        # Support operators: =, !=, >, <, >=, <= for numeric; = and != for strings
        for op in [">=", "<=", "!=", ">", "<", "="]:
            if op in f:
                key, val = f.split(op, 1)
                key = key.strip()
                val = val.strip().strip('"').strip("'")
                conds.append((key, op, val))
                break
    return conds

def apply_filters(df, conds):
    for key, op, val in conds:
        if key not in df.columns:
            raise SystemExit(f"Column '{key}' not in data")
        series = df[key]
        # Try numeric comparison if possible
        try:
            val_num = float(val)
            is_num = pd.api.types.is_numeric_dtype(series)
        except ValueError:
            val_num = None
            is_num = False
        if op == "=":
            df = df[series == (val_num if is_num else val)]
        elif op == "!=":
            df = df[series != (val_num if is_num else val)]
        elif op == ">":
            df = df[series.astype(float) > float(val)]
        elif op == "<":
            df = df[series.astype(float) < float(val)]
        elif op == ">=":
            df = df[series.astype(float) >= float(val)]
        elif op == "<=":
            df = df[series.astype(float) <= float(val)]
    return df

def main():
    ap = argparse.ArgumentParser(description="Filter, aggregate and visualize CSV")
    ap.add_argument("--input", "-i", required=True, help="Path to input CSV")
    ap.add_argument("--filter", "-f", action="append", default=[], help="Filter like col=value or col>=10; can repeat")
    ap.add_argument("--group-by", "-g", nargs="*", default=[], help="Columns to group by")
    ap.add_argument("--agg", "-a", nargs="*", default=[], help="Aggregations like sum:amount avg:price count:*")
    ap.add_argument("--out", "-o", default="report.csv", help="Output CSV path")
    ap.add_argument("--plot", "-p", default=None, help="Optional bar chart PNG path")
    args = ap.parse_args()

    df = pd.read_csv(args.input)
    if args.filter:
        df = apply_filters(df, parse_filters(args.filter))

    if args.group_by and args.agg:
        agg_map = {}
        for spec in args.agg:
            fn, col = (spec.split(":", 1) + ["*"])[:2]
            if col == "*" and fn.lower() == "count":
                # count rows per group
                out = df.groupby(args.group_by).size().reset_index(name="count")
                out.to_csv(args.out, index=False)
                if args.plot and len(args.group_by) == 1:
                    out.plot(kind="bar", x=args.group_by[0], y="count", legend=False)
                    plt.tight_layout(); plt.savefig(args.plot); plt.close()
                return
            agg_map[col] = fn
        out = df.groupby(args.group_by).agg(agg_map).reset_index()
    else:
        out = df

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(args.out, index=False)

    # Optional plot: if one grouping column and a single numeric metric
    if args.plot and args.group_by:
        numeric_cols = [c for c in out.columns if c not in args.group_by]
        if len(args.group_by) == 1 and len(numeric_cols) == 1:
            out.plot(kind="bar", x=args.group_by[0], y=numeric_cols[0], legend=False)
            plt.tight_layout(); plt.savefig(args.plot); plt.close()

    print(f"Saved table to {args.out}" + (f" and chart to {args.plot}" if args.plot else ""))

if __name__ == "__main__":
    main()
