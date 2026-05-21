# Tigrbl KMS

Standalone key management service package for Tigrbl.

## Features

- Manage symmetric keys with versioning and rotation.
- Ship a ready-to-run FastAPI application.
- Extend cryptography behavior through `swarmauri_crypto_*` plugins.
- Back key metadata with SQLAlchemy and Pydantic models.

## Quick Start

### Run the built-in app

Tigrbl KMS ships a FastAPI application at `tigrbl_kms.app:app`. Configure the database URL if needed and launch it with uvicorn:

```bash
export KMS_DATABASE_URL=sqlite+aiosqlite:///./kms.db
uv run uvicorn tigrbl_kms.app:app --host 127.0.0.1 --port 8000 --reload
```

### Verify

Once the service starts, verify it is running:

```bash
curl http://127.0.0.1:8000/system/healthz
```

The endpoint returns `{"ok": true}` when deployment succeeds.

## Build a Custom App

You can construct a bespoke Tigrbl KMS service by creating your own `TigrblApp` and adding the KMS resources:

```python
from tigrbl import TigrblApp
from tigrbl.engine import engine
from tigrbl_kms.orm import Key, KeyVersion
from swarmauri_standard.key_providers import InMemoryKeyProvider
from swarmauri_crypto_pgp import PgpCrypto

db = engine("sqlite+aiosqlite:///./kms.db")
crypto = PgpCrypto()
key_provider = InMemoryKeyProvider()

async def add_services(ctx):
    ctx["crypto"] = crypto
    ctx["key_provider"] = key_provider

app = TigrblApp(engine=db, api_hooks={"*": {"PRE_TX_BEGIN": [add_services]}})
app.include_models([Key, KeyVersion], base_prefix="/kms")
app.mount_jsonrpc(prefix="/kms/rpc")
app.attach_diagnostics(prefix="/system")

@app.on_event("startup")
async def startup():
    await app.initialize()
```

Any compatible `swarmauri_crypto_*` plugin can replace `PgpCrypto`.

## Create a Key and Encrypt Data

Create a key:

```bash
curl -s -X POST http://127.0.0.1:8000/kms/Key \
  -H "Content-Type: application/json" \
  -d '{"name":"demo","algorithm":"AES256_GCM"}'
```

Encrypt base64-encoded plaintext with that key:

```bash
PLAINTEXT=$(echo -n 'hello world' | base64)
curl -s -X POST http://127.0.0.1:8000/kms/Key/<KEY_ID>/encrypt \
  -H "Content-Type: application/json" \
  -d "{\"plaintext_b64\":\"$PLAINTEXT\"}"
```

## License

This project is licensed under the terms of the [Apache 2.0](LICENSE) license.
