# barista

Task runner framework that supports concurrent builds against a graph of dependencies.

Usage: see `examples/coffee_shop.cr`

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     barista:
       gitlab: skinnyjames/barista
   ```

2. Run `shards install`

## Usage

Run the example

```
docker build -t coffeeshop .
docker run -it coffeeshop bash

./coffee-shop build --workers=4
```

## Development

## Contributing

1. Fork it (<https://gitlab.com/skinnyjames/barista/-/forks/new>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Sean Gregory](https://gitlab.com/skinnyjames) - creator and maintainer
