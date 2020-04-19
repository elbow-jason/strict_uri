defmodule StrictURITest do
  use ExUnit.Case, async: true
  import StrictURI
  doctest StrictURI

  describe "parse_uri/1" do
    test "returns an ok-tuple with a URI struct for valid url strings" do
      url = "thingy://example.com"
      assert {:ok, uri} = StrictURI.parse_uri(url)
      assert %URI{scheme: "thingy", host: "example.com"} = uri
    end

    test "assumes port 80 with valid http url" do
      url = "http://example.com"
      assert {:ok, uri} = StrictURI.parse_uri(url)
      assert %URI{scheme: "http", host: "example.com", authority: "example.com", port: 80} == uri
    end

    test "assumes port 443 with http scheme" do
      url = "https://example.com"
      assert {:ok, uri} = StrictURI.parse_uri(url)
      assert %URI{scheme: "https", host: "example.com", authority: "example.com", port: 443} == uri
    end

    test "assumes port 21 with ftp scheme" do
      url = "ftp://example.com"
      assert {:ok, uri} = StrictURI.parse_uri(url)
      assert %URI{scheme: "ftp", host: "example.com", authority: "example.com", port: 21} == uri
    end

    test "errors for non-strings" do
      assert {:error, {:uri, :invalid_type}} = StrictURI.parse_uri(1)
    end

    test "works for a url without a scheme" do
      url = "example.com/path/here"
      assert {:ok, uri} = StrictURI.parse_uri(url)
      assert %URI{
        authority: "example.com",
        host: "example.com",
        path: "/path/here",
      } == uri
    end

    test "works with a valid port number" do
      url = "ftp://example.com:4001"
      assert {:ok, uri} = StrictURI.parse_uri(url)
      assert %URI{scheme: "ftp", host: "example.com", authority: "example.com:4001", port: 4001} == uri
    end

    test "errors for a url with a negative port number" do
      url = "yea://example.com:-4001"
      assert {:error, {:port, :invalid_format}} = StrictURI.parse_uri(url)
    end

    test "errors for a url with a port number greater than max" do
      valid_port = "ppl://example.com:65535"
      assert {:ok, _} = StrictURI.parse_uri(valid_port)
      port_too_high = "ppl://example.com:65536"
      assert {:error, {:port, :invalid_value}} = StrictURI.parse_uri(port_too_high)
    end
    test "errors for a url with a invalid value where the port goes" do
      strange_port = "ppl://example.com:port"
      assert {:error, {:port, :invalid_format}} = StrictURI.parse_uri(strange_port)
    end
  end

  describe "parse_uri/2 with option scheme: true" do
    test "allows urls with scheme" do
      url = "protokawl://example.com"
      assert {:ok, uri} = StrictURI.parse_uri(url, scheme: true)
      assert %URI{scheme: "protokawl", host: "example.com", authority: "example.com"} == uri
    end

    test "requires urls with scheme" do
      url = "example.com"
      assert {:error, {:scheme, :required}} = StrictURI.parse_uri(url, scheme: true)
    end
  end

  describe "parse_uri/2 with option scheme: false" do
    test "does not allow scheme" do
      url = "protokawl://example.com"
      assert {:error, {:scheme, :not_allowed}} = StrictURI.parse_uri(url, scheme: false)
    end

    test "parses a uri without a scheme" do
      url = "example.com"
      assert {:ok, _} = StrictURI.parse_uri(url, scheme: false)
    end
  end
end
