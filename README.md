# memcached

Pure Crystal implementation of a Memcached client (work in progress).

## Installation

Add it to `Projectfile`

```crystal
deps do
  github "[comandeo]/crystal-memcached"
end
```

## Usage

```crystal
require "memcached"

client = Memcached::Client.new
client.set("Key", "Value")
value = client.get("Key")

```

## Development

TODO: Write instructions for development

## Contributing

1. Fork it ( https://github.com/comandeo/crystal-memcached/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [comandeo](https://github.com/[comandeo]) Dmitry Rybakov - creator, maintainer