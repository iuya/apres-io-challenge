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

## Improvements

1. Unit Tests, there are 0 as I did the development by testing directly against the given CSV using `iex`
and `Postman` (colection in the repo)

2. The Journal is a plain list that has to be reversed and iterated to generate a snapshot every
time the caller wants to do current/next/prev. Depending on the size of this journal and the time
it takes to apply the operations, we would also need a separate decision object that contains the
snapshot and is updated every time a new operation is added to the journal.

3. There are some reverse operations which are O(n). I didn't find a good way to remove these
operations but to be frank at this stage, trying to do something way more complicated to remove them
smells like premature optimization.

4. I am not happy with the way I am handling metrics; I want them extracted from the service itself
but currently they seem a little flimsy to me. If I knew the plans for this service, I could have
set the base for something more permanent, but as of now, it seems enough.

5. And also very related to the metrics, the way I handle generating the raw is looking like
 spaghetti already but it's supposed to be a quick way to dump the whole query for auditing purposes
