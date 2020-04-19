# StrictURI

StrictURI is a utility for parsing URLs and domains with or without the scheme included.

In Elixir, `URI.parse/1` is THE function for parsing URIs, but its use is often accompanied by checking the output for correctness. The issue is that there is no invalid string for `URI.parse/1`; it will always parse a string into a URI struct. However, not every string is a valid URL.

StrictURI takes the stance that parsing a URI *can* fail in very specific ways.

When using StrictURI, instead of parsing any string and outputting a URI struct, StrictURI ensures that a host is included and that the
port (whether included in the URL or not) is valid for both its value and its format in the URL.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `strict_uri` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:strict_uri, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/strict_uri](https://hexdocs.pm/strict_uri).

