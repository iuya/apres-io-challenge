# CreditForecast

## How to run

```bash
# Start postgres
docker compose up postgres

# Load all env vars

./.envrc

# Compile and migrate the database
mix deps.get
mix ecto.setup

# Start the HTTP server
mix phx.server
```

## Test request

```bash
curl --location --request POST 'localhost:4000/api/query' \
--header 'Content-Type: application/json' \
--data-raw '{
    "column": "AGE",
    "operator": "eq",
    "values": "early 30s"
}'
```
