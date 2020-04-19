defmodule StrictURI do
  @moduledoc File.read!(__DIR__ <> "/../README.md")

  @type uri_reason :: {:uri, :invalid_type}
    | {:scheme, :required}
    | {:host, :required}
    | {:port, :invalid_value}
    | {:port, :invalid_format}

  @type uri_option :: {:scheme, boolean()}

  defguard is_port_number(p) when p in 0..65_535

  @doc """
  Parses well-formatted URIs.

  Successful parsing returns `{:ok, URI.t()}` and a failure parsing returns
  an error tuple.

  Examples:

      iex> parse_uri("custom://fakeurlthing.co.uk")
      {:ok, %URI{scheme: "custom", host: "fakeurlthing.co.uk", authority: "fakeurlthing.co.uk"}}

      iex> parse_uri("fakeurlthing.co.uk")
      {:ok, %URI{scheme: nil, host: "fakeurlthing.co.uk", authority: "fakeurlthing.co.uk"}}

      iex> parse_uri("protokawl://fakeurlthing.co.uk:60000000")
      {:error, {:port, :invalid_value}}

      iex> parse_uri("p://fakeurlthing.co.uk", scheme: true)
      {:ok, %URI{scheme: "p", host: "fakeurlthing.co.uk", authority: "fakeurlthing.co.uk"}}

      iex> parse_uri("fakeurlthing.co.uk", scheme: true)
      {:error, {:scheme, :required}}

      iex> parse_uri("p://fakeurlthing.co.uk", scheme: false)
      {:error, {:scheme, :not_allowed}}
  """
  @spec parse_uri(any(), [uri_option()]) :: {:ok, URI.t()} | {:error, uri_reason}
  def parse_uri(str, opts \\ []) do
    with(
      :ok <- ensure(str, &is_binary/1, {:uri, :invalid_type}),
      {:ok, kind} <- uri_parser_kind(str, opts),
      {:ok, uri} <- do_parse_uri(str, opts, kind)
    ) do
      {:ok, uri}
    else
      {:error, _} = err -> err
    end
  end

  defp uri_parser_kind(str, opts) do
    case Keyword.fetch(opts, :scheme) do
      :error -> uri_parser_kind_from_str(str)
      {:ok, true} -> {:ok, :scheme_required}
      {:ok, false} -> {:ok, :scheme_not_allowed}
      {:ok, got} -> invalid_option(:scheme, got, "Must be a boolean.")
    end
  end

  defp uri_parser_kind_from_str(str) do
    if string_has_scheme?(str) do
      {:ok, :scheme_required}
    else
      {:ok, :scheme_not_allowed}
    end
  rescue
    CaseClauseError -> {:error, {:uri, :invalid_format}}
  end

  defp string_has_scheme?(str) do
    case String.split(str, "://") do
      [^str] -> false
      [_scheme, _rest] -> true
    end
  end

  defp invalid_option(key, val, extra) do
    raise "Invalid value for #{inspect(key)} option. #{extra} Got: #{inspect(val)}"
  end

  defp do_parse_uri(str, opts, :scheme_required) do
    str
    |> URI.parse()
    |> validate_uri(str, opts)
  end

  defp do_parse_uri(str, opts, :scheme_not_allowed) do
    with(
      :ok <- check_no_scheme(str),
      {:ok, uri} <- do_parse_uri("stub://" <> str, opts, :scheme_required)
    ) do
      {:ok, %URI{uri | scheme: nil}}
    else
      {:error, _} = err -> err
    end
  end

  defp validate_uri(%URI{scheme: scheme, host: host, port: port} = uri, str, _opts) do
    with(
      :ok <- ensure(scheme, &is_binary/1, {:scheme, :required}),
      :ok <- ensure(host, &is_binary/1, {:host, :required}),
      :ok <- check_port_value(port),
      {:ok, port_string} <- capture_port_string(str, host),
      :ok <- check_port_format(port, port_string)
    ) do
      {:ok, uri}
    else
      {:error, _} = err -> err
    end
  end

  defp check_no_scheme(str) do
    if string_has_scheme?(str) do
      {:error, {:scheme, :not_allowed}}
    else
      :ok
    end
  end

  defp check_port_value(nil), do: :ok
  defp check_port_value(p) when is_port_number(p), do: :ok
  defp check_port_value(_), do: {:error, {:port, :invalid_value}}

  defp capture_port_string(str, host) do
    str
    |> part_after_host(host)
    |> regex_port_string()
  end

  defp part_after_host(str, host) do
    # there could be more duplicates the host value after the first
    # so we put a _ on the rest
    [_, after_host | _] = String.split(str, host)
    after_host
  end

  @port_string_regex ~r/^:\d*/

  defp regex_port_string(after_host) do
    @port_string_regex
    |> Regex.run(after_host)
    |> case do
      [":"] ->
        {:error, {:port, :invalid_format}}
      [":" <> _ = port_string] ->
        {:ok, port_string}
      nil ->
        {:ok, ""}
      _ ->
        {:error, {:url, :invalid_format}}
    end
  end

  defp check_port_format(nil, _str), do: :ok
  defp check_port_format(n, "") when is_port_number(n), do: :ok
  defp check_port_format(0, ":0"), do: :ok
  defp check_port_format(num, port_string) when is_integer(num) and is_binary(port_string) do
    if ":#{num}" == port_string do
      :ok
    else
      # the integer of the port had leading zeroes
      {:error, {:port, :invalid_format}}
    end
  end

  defp ensure(val, verifier, reason) when is_function(verifier, 1) do
    if verifier.(val) do
      :ok
    else
      {:error, reason}
    end
  end
end
