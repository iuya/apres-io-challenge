# Build
FROM elixir:1.13.3-alpine as build

ARG service_version

RUN apk update && apk add --no-cache --update git make bash inotify-tools util-linux openssl
RUN mix local.hex --force && mix local.rebar --force

ENV ERL_AFLAGS="-kernel shell_history enabled"
ENV MIX_ENV prod

WORKDIR /app
COPY . .

RUN mix do deps.get --only prod, deps.compile
RUN mix release --overwrite

# Release
FROM alpine:latest
RUN apk add --no-cache --update bash libstdc++

WORKDIR /app

COPY --from=build /app/_build/prod/rel/credit_forecast ./

ENV HTTP_PORT=8080 BEAM_PORT=8081 ERL_EPMD_PORT=8082
EXPOSE $HTTP_PORT $BEAM_PORT $ERL_EPMD_PORT

CMD ["/app/bin/credit_forecast", "start"]
