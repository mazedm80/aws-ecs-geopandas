FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y libexpat1 
# create a virtualenv
ENV VENV_PATH=/opt/venv
RUN python -m venv ${VENV_PATH}
ENV PATH="${VENV_PATH}/bin:$PATH"

WORKDIR /app

# copy requirements and install into venv
COPY requirements.txt /app/requirements.txt
RUN pip install --upgrade pip
RUN pip install -r /app/requirements.txt

# copy app and data files
COPY ./src/main.py /app/main.py

# default env vars (can be overridden in ECS task definition)
ENV DATA_DIR=/data/
ENV GADM_FILE_NAME=gadm41_DEU_4.json
ENV RASTER_FILE_NAME=DEU_wind-speed_10m.tif

ENTRYPOINT ["python3", "/app/main.py"]