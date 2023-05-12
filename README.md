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

* `shards build coffee_shop && ./bin/coffee_shop build`

## Documentation

Documentation is [available here](https://skinnyjames.gitlab.io/barista/)
