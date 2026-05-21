FROM python:3.12-slim

RUN apt-get update && \
    apt-get install --yes --no-install-recommends build-essential git curl && \
    pip install --no-cache-dir uv && \
    apt-get purge -y build-essential && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN uv pip install --system .

EXPOSE 8000
ENV KMS_DATABASE_URL=""

CMD ["python", "-m", "tigrbl_kms"]
