# Apres.io challenge

## Case: A Consumer Lending Data Story

Data referred here linked: [credit_forecast_sample.csv](priv/credit_forecast_sample.csv)

AVANT BANK offers home loans to individuals towards the purchase of a new home through a mortgage. The first step in the home loan application is a quick forecast of the credit limit i.e. the maximum amount that the customer can borrow from the bank. This initial credit limit is determined by a machine learning model that predicts a single number based on input variables in the loan application.
 
### Data Description

Each line in credit_forecast_sample.csv represents a unique prediction with the following information:

* Demographic data provided by the individual such as AGE, SEX, MARRIAGE, EDUCATION from the loan application
* Payment data gathered from bank sources for the individual such as 
* AVERAGE BILL: annual current credit card/loan bill
* AVERAGE PAYMENT: current monthly payments made by individual
* LAST PAYMENT: metadata about last payment
* Third party data purchased by the bank
* CREDIT SCORES: representing the latest credit score for the individual
* The PREDICTED TARGET: output of the machine learning model

Use this data to answer the following questions, in the pages below:

1. What is the general structure of my data? General Schema and SQL 
2. How can I find specific decisions with an API? Query and API Design
3. How can I process a batch of decisions efficiently? State Management

### Part 1. General Schema and SQL
Develop a two table schema consisting of 
* Columns 
* Decisions

Columns should contain a list of available columns from the CSV with their name and data type

Decisions should contain one row per decision in the CSV, ideally stored as a JSONB type column within PostgreSQL. (Rather than have explicit columns in the table like age, average bill, etc., consider a single column called row that is of type JSONB and can hold an entire decision as JSON)

Given a schema in PostgreSQL that has been populated with these two tables, develop two Elixir functions
One to read the list of columns from the Columns table, returning a list of maps, containing name and data type
One to read the list of decisions from the Decisions table, returning a list of maps, with a single element called row, which is itself a map representing a decision

Feel free to create the tables and load the data directly using SQL or any other approach you prefer.

### Part 2. Query Design 

Develop an Elixir function that can take the following parameters

* Column name
* Operator
* Value

For example

```json
{
    "column": "age",
    "operator": "eq",
    "values": "early 30s"
}
```

and returns the list of Decisions satisfying the query criteria.

You will need to consider a request that takes a single condition expressed as JSON, and generate a SQL statement to query the decisions table. You may find it necessary to query the columns table to ensure that the correct data type is used while generating a valid SQL statement.The function should return a list of decisions, in this example, where the value of age is equal to "early 30s".

For simplicity, only consider two operators, eq and gt (representing greater than which would apply to numeric columns only)

### Part 3. State Management

If you were to consider the query function you developed above as part of an API that allowed the user to cycle through a set of decisions, how would you design a state management concept within Elixir?

The use case would be as follows

The loan officers at AVANT BANK, who are the primary communications channel between the bank and the loan applicants need to be perform the following process

* Select a set of decisions to work on based on some criteria, for example all decisions with a forecasted amount > 200,000.
* Get a single decision and examine it
* Override a decision if needed by updating the Forecast column with a comment
* Move to the next decision in the set
* Move to a previous decision in the set
* At the end of the set, understand
    * How many decisions were changed?
    * What was the average change made to the forecasts at the end of the set?

The changes may be saved at the end of a set or held for further review, so the loan officer is not updating a decision record but recording the changes that would be made for audit purposes before committing them.

You don’t have to build this out in detail, but the idea would be to build upon the query function and hold the list of decisions in a form that can support
* Temporary updates
* Next decision
* Previous decision

## Solution

Part 1 and 2 are just directly implementable, but part 3 is more open so here are my initial proposals (and possible future improvements)

* Use a GenServer to hold the state between HTTP calls.
* In order to offer multi-user and/or multi-query support, the call that begins the "stateful query" must return an ID to identify the GenServer that holds the state later on.
* If we are going to employ multiple instances we need to clusterise them using something like swarm so we have a single source of truth (GenServer) for every ID and it can be called from whatever instance is serving the HTTP request.
* The Genserver itself will only consist of 2 lists to represent the list of decisions and a pointer (basically a zipper so we can access the current element of the list at O(1) time)
* The list of decisions will not be only the "raw" decision, I will expand the decision struct `%Decision{row: map()}` with a journal of operations resulting in something like `%Decision{row: map(), operations: [operation.t()]}` This also allows us to get the number of decisions w/ updates and the average change of forecast at the end of the query by iterating over the decision list once (although I have to think if we could generate these metrics while doing the changes so we skip an extra "iterating over the whole list" operation) 
* `Operation.t()` can be left as a list representing `operation_name` and `args` (i.e: change forecast to 500000 would be something like `["update", "FORECAST", 500000]` this is generic enough that we don't need to know the operations beforehand and can be easily expanded.
* Actually applying the operations would be done by a module separate from the GenServer (or eventually even a completely different service receiving the operations and the row_id) Although I think that's outside the scope of the challenge.

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
