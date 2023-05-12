# Barista

Barista was designed to be an extensible framework for writing and running a dependency graph of tasks concurrently. It privileges extensibility over providing a DSL, and provides tooling and behaviors for orchestrating tasks.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     barista:
       gitlab: skinnyjames/barista
   ```

2. Run `shards install`

## Run example

1. `docker build -t coffee_shop .`
1. `docker run -it coffee_shop bash`
1. `/coffee-shop build --workers=5`

A package should be present in `/opt/barista/package`

## Documentation

Documentation is [available here](https://skinnyjames.gitlab.io/barista/)
