#!/usr/bin/env python3
"""
Convert MovieLens .dat files (delimiter '::') to CSV with an optional year filter for ratings.

Usage examples:
  python convert_movielens_pandas.py --ratings /path/ratings.dat --movies /path/movies.dat --outdir ./out
  python convert_movielens_pandas.py --ratings ratings.dat --movies movies.dat --outdir ./out --start-year 2000 --end-year 2005

Notes:
- The script expects MovieLens 1M legacy .dat files with '::' delimiter.
- It writes two CSVs: ratings_subset.csv (filtered if a year range is provided) and movies.csv.
"""

import argparse
import os
import pandas as pd

def convert_ratings(ratings_path: str, outdir: str, start_year: int = None, end_year: int = None, chunksize: int = 0):
    cols = ["userId","movieId","rating","timestamp"]
    out_csv = os.path.join(outdir, "ratings_subset.csv")

    if chunksize and chunksize > 0:
        # Chunked processing (memory-friendly)
        dfs = []
        for chunk in pd.read_csv(ratings_path, sep="::", engine="python", names=cols, chunksize=chunksize):
            if start_year is not None and end_year is not None:
                chunk["datetime"] = pd.to_datetime(chunk["timestamp"], unit="s")
                mask = (chunk["datetime"].dt.year >= start_year) & (chunk["datetime"].dt.year <= end_year)
                chunk = chunk.loc[mask, cols]  # keep only required cols
            else:
                chunk = chunk[cols]
            dfs.append(chunk)
        result = pd.concat(dfs, ignore_index=True)
        result.to_csv(out_csv, index=False)
    else:
        # Single-shot processing
        df = pd.read_csv(ratings_path, sep="::", engine="python", names=cols, encoding="latin-1")

        if start_year is not None and end_year is not None:
            df["datetime"] = pd.to_datetime(df["timestamp"], unit="s")
            df = df[(df["datetime"].dt.year >= start_year) & (df["datetime"].dt.year <= end_year)]
            df = df[cols]
        df.to_csv(out_csv, index=False)

    return out_csv

def convert_movies(movies_path: str, outdir: str):
    cols = ["movieId","title","genres"]
    out_csv = os.path.join(outdir, "movies.csv")
    df = pd.read_csv(movies_path, sep="::", engine="python", names=cols, encoding="latin-1")

    df.to_csv(out_csv, index=False)
    return out_csv

def main():
    ap = argparse.ArgumentParser(description="Convert MovieLens .dat files ('::' delimited) to CSV with optional ratings year filter.")
    ap.add_argument("--ratings", required=True, help="Path to ratings.dat")
    ap.add_argument("--movies", required=True, help="Path to movies.dat")
    ap.add_argument("--outdir", required=True, help="Output directory")
    ap.add_argument("--start-year", type=int, default=None, help="Start year for ratings filter (inclusive)")
    ap.add_argument("--end-year", type=int, default=None, help="End year for ratings filter (inclusive)")
    ap.add_argument("--chunksize", type=int, default=0, help="Optional pandas chunk size for memory-friendly processing")
    args = ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)

    ratings_csv = convert_ratings(args.ratings, args.outdir, args.start_year, args.end_year, args.chunksize)
    movies_csv  = convert_movies(args.movies, args.outdir)

    print("Conversion completed.")
    print("Ratings CSV:", ratings_csv)
    print("Movies  CSV:", movies_csv)

if __name__ == "__main__":
    main()
