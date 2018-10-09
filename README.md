# Paramnoia - Params for the paranoid

Paramnoia is a library that allows for parameter coercion into type-safe
crystal structures.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  paramnoia:
    github: jreinert/paramnoia
```

## Usage

tldr; Works exactly like `JSON::Serializable`. Hint: run `make` in the cloned
project, start up `crystal play` and play around! The following
examples are runnable in the Workbook tab!

### Basic flat params

```crystal
require "paramnoia"

struct Params
  include Paramnoia::Params

  getter foo : String
  getter bar : Int32
end

pp Params.from_urlencoded("foo=hello&bar=3")
```

### Arrays

```crystal
require "paramnoia"

struct Params
  include Paramnoia::Params

  getter foo : Array(Float64)
end

pp Params.from_urlencoded("foo[]=1&foo[]=2.3&foo[]=-3")
```

### Booleans

```crystal
require "paramnoia"

struct Params
  include Paramnoia::Params

  getter foo : Bool
  getter bar : Bool
  getter baz : Bool
  getter foobar : Bool
  getter foobaz : Bool
end

pp Params.from_urlencoded("foo=1&bar=2&baz=0&foobar=FALSE&foobaz=false")
```

### Enums

```crystal
require "paramnoia"

enum Foobar
  Foo
  Bar
  Baz
end

struct Params
  include Paramnoia::Params

  getter foo : Foobar
end

pp Params.from_urlencoded("foo=Bar")
```

### Defaults and nilable

```crystal
require "paramnoia"

struct Params
  include Paramnoia::Params

  getter foo : String?
  getter bar : String = "bar"
  getter baz : Int32
end

pp Params.from_urlencoded("baz=3")
```

### Nested

```crystal
require "paramnoia"

struct Nested
  include Paramnoia::Params

  getter bar : String
  getter baz : Array(Int32)
end

struct Params
  include Paramnoia::Params

  getter foo : Nested
  getter bar : String
end

pp Params.from_urlencoded("foo[bar]=nested%20bar&foo[baz][]=1&foo[baz][]=2&bar=bar")
```

### Key renaming and converters

```crystal
require "paramnoia"

module BazConverter
  # You will be passed all matching param values from the HTTP::Params
  def self.from_params(values : Array(String))
    values.last.split(",").map { |i| Int32.new(i) }
  end
end

struct Params
  include Paramnoia::Params

  @[Paramnoia::Params::Field(key: "fooBar")]
  getter foo_bar : String
  @[Paramnoia::Params::Field(converter: BazConverter)]
  getter baz : Array(Int32)
end

pp Params.from_urlencoded("fooBar=foo&baz=1,2,3,4")
```

### Strict parsing

```crystal
require "paramnoia"

@[Paramnoia::Settings(strict: true)]
struct Params
  include Paramnoia::Params

  getter foo : String
end

begin
  Params.from_urlencoded("foo=bar&baz=1")
rescue ex : Exception
  puts ex.message
end
```

### From JSON

```crystal
require "paramnoia"

struct Params
  include Paramnoia::Params

  getter foo : String
  getter bar : Int32
end

pp Params.from_json(%|{"foo":"foo","bar":1}|)
```

## Development

### TODO

- [x] Parsing from HTTP::Params
- [x] Parsing from JSON
- [ ] Parsing from Form Data
- [ ] Parsing from Path Params
- [ ] Specs
- [ ] CI
- [ ] Refactoring/splitting up macro code

## Contributing

1. Fork it (<https://github.com/jreinert/paramnoia/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [jreinert](https://github.com/jreinert) Joakim Reinert - creator, maintainer
