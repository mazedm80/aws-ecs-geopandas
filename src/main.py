#!/usr/bin/env python3

import requests
import os
import sys
import logging
from pathlib import Path

import boto3
import numpy as np
import rasterio as rs
import geopandas as gpd
from botocore.exceptions import ClientError
from geopandas import GeoDataFrame

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s %(levelname)s: %(message)s"
)
logger = logging.getLogger(__name__)


def download_file(url: str, output_dir: str, filename: str) -> None:
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    logger.info(
        "Downloading %s to %s", url, os.path.join(output_dir, filename)
    )
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        with open(os.path.join(output_dir, filename), "wb") as f:
            f.write(response.content)
    except requests.RequestException as e:
        logger.error("Error downloading file: %s", e)


def upload_file_to_s3(file_name, bucket, object_name=None):
    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = os.path.basename(file_name)

    # Upload the file
    s3_client = boto3.client("s3")
    try:
        s3_client.upload_file(file_name, bucket, object_name)
    except ClientError as e:
        logging.error(e)
        return False
    return True


def load_gdf(path: str) -> GeoDataFrame:
    logger.info("Loading GeoDataFrame from %s", path)
    gdf = gpd.read_file(path)
    if gdf.crs is None:
        logger.info("Input has no CRS — assuming EPSG:4326 (WGS84).")
        gdf.set_crs(epsg=4326, inplace=True)
    return gdf


def compute_centroid_column(
    gdf: GeoDataFrame, centroid_col: str = "centroid"
) -> GeoDataFrame:
    proj_crs: int = 3857
    logger.info(f"Setting projection to {proj_crs}.")
    gdf_proj = gdf.to_crs(epsg=3857)

    cent = gdf_proj.geometry.centroid
    cent_geo = cent.to_crs(gdf.crs)
    gdf[centroid_col] = cent_geo
    return gdf


def keep_and_rename(
    gdf: GeoDataFrame, centroid_col: str = "centroid"
) -> GeoDataFrame:
    # keep only the columns we want
    keep = ["NAME_4", centroid_col]
    gdf = gdf[keep].copy()
    # rename common names and set centroid as active geometry if desired
    gdf.rename(
        columns={"NAME_4": "town", centroid_col: "geometry"}, inplace=True
    )
    gdf = gdf.set_geometry("geometry")
    return gdf


def sample_raster_value(
    gdf: GeoDataFrame, raster_path: str, out_prefix: str = "wind_speed"
) -> GeoDataFrame:
    if not Path(raster_path).exists():
        raise FileNotFoundError(f"Raster not found: {raster_path}")
    with rs.open(raster_path) as src:
        logger.info(
            "Opened raster %s (CRS=%s, bands=%d, nodata=%s)",
            raster_path,
            src.crs,
            src.count,
            src.nodata,
        )
        # reproject points to raster CRS
        if gdf.crs != src.crs:
            pts = gdf.to_crs(src.crs)
        else:
            pts = gdf
        coords = [(p.x, p.y) for p in pts.geometry]
        samples = list(src.sample(coords))
        arr = np.array(samples).flatten()
        gdf[out_prefix] = arr
    return gdf


def export_as_geoparquet(gdf: GeoDataFrame, output_path: str) -> None:
    if not os.path.exists(output_path):
        os.makedirs(output_path)
    logger.info("Exporting GeoDataFrame to Parquet format at %s", output_path)
    gdf.to_parquet(f"{output_path}wind_speed.parquet", engine="pyarrow")


def main():
    DATA_DIR = os.environ.get("DATA_DIR", "./data/")
    GADM_FILE_NAME = os.environ.get("GADM_FILE_NAME", "gadm41_DEU_4.json")
    RASTER_FILE_NAME = os.environ.get(
        "RASTER_FILE_NAME", "DEU_wind-speed_10m.tif"
    )
    BUCKET_NAME = os.environ.get("BUCKET_NAME")

    download_file(
        f"https://gwa.cdn.nazkamapps.com/country_tifs_v4/{RASTER_FILE_NAME}",
        DATA_DIR,
        RASTER_FILE_NAME,
    )
    download_file(
        f"https://geodata.ucdavis.edu/gadm/gadm4.1/json/{GADM_FILE_NAME}",
        DATA_DIR,
        GADM_FILE_NAME,
    )

    try:
        gdf = load_gdf(os.path.join(DATA_DIR, GADM_FILE_NAME))
        gdf = compute_centroid_column(gdf, centroid_col="centroid")
        gdf = keep_and_rename(gdf, centroid_col="centroid")
        result = sample_raster_value(
            gdf, os.path.join(DATA_DIR, RASTER_FILE_NAME), out_prefix="wind"
        )
        export_as_geoparquet(result, os.path.join(DATA_DIR, "output/"))
        logger.info("Preview:\n%s", result.head().to_string())
        if BUCKET_NAME:
            output_file = os.path.join(DATA_DIR, "output/wind_speed.parquet")
            if upload_file_to_s3(output_file, BUCKET_NAME):
                logger.info(
                    "Uploaded %s to S3 bucket %s", output_file, BUCKET_NAME
                )
            else:
                logger.error(
                    "Failed to upload %s to S3 bucket %s",
                    output_file,
                    BUCKET_NAME,
                )
    except Exception as e:
        logger.exception("An error occurred: %s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
