defmodule IP do
  @moduledoc """
  Elixir IP value tool suite.

  Erlang provides a structured IP type, but the tooling around it is
  very squirelly, spread out over several disjoint modules, and not
  ergonomic with respect to structured programming.

  Elixir gives us some better tools (like protocols and guards).

  This module, and its related modules `IP.Range` and `IP.Subnet`
  provide a better view into operator-friendly, composable programming
  that interfaces well with erlang IP primitives.
  """

  @typedoc "ipv4 representation in erlang."
  @type v4 :: {byte, byte, byte, byte}

  @typedoc "16-bit integers"
  @type short :: 0x0..0xFFFF

  @typedoc "ipv6 representation in erlang."
  @type v6 :: {short, short, short, short, short, short, short, short}

  @typedoc "any ip address, either v4 or v6"
  @type addr :: v4 | v6

  import Bitwise

  ####################################################################
  ## guards

  @doc false
  defguard is_byte(n) when is_integer(n) and n >= 0 and n <= 255
  @doc false
  defguard is_short(n) when is_integer(n) and n >= 0 and n <= 0xFFFF

  @doc """
  true if the argument is an ipv4 datatype

  usable in guards.

  ```elixir
  iex> IP.is_ipv4({10, 0, 0, 1})
  true
  iex> IP.is_ipv4(:foo)
  false
  iex> IP.is_ipv4({256, 0, 0, 0})
  false
  ```
  """
  defguard is_ipv4(v4) when is_tuple(v4) and tuple_size(v4) == 4 and
                            is_byte(elem(v4, 0)) and is_byte(elem(v4, 1)) and
                            is_byte(elem(v4, 2)) and is_byte(elem(v4, 3))

  @doc """
  true if the argument is an ipv6 datatype

  usable in guards.

  ```elixir
  iex> IP.is_ipv6({0, 0, 0, 0, 0, 0, 0, 1})
  true
  iex> IP.is_ipv6(:foo)
  false
  iex> IP.is_ipv6({0x10000, 0, 0, 0, 0, 0, 0, 1})
  false
  ```
  """
  defguard is_ipv6(v6) when is_tuple(v6) and tuple_size(v6) == 8 and
                            is_short(elem(v6, 0)) and is_short(elem(v6, 1)) and
                            is_short(elem(v6, 2)) and is_short(elem(v6, 3)) and
                            is_short(elem(v6, 4)) and is_short(elem(v6, 5)) and
                            is_short(elem(v6, 6)) and is_short(elem(v6, 7))

  @doc """
  true if the argument is either ipv6 or ipv4 datatype

  usable in guards.

  ```elixir
  iex> IP.is_ip({0, 0, 0, 0, 0, 0, 0, 1})
  true
  iex> IP.is_ip({127, 0, 0, 1})
  true
  ```
  """
  defguard is_ip(ip) when is_ipv4(ip) or is_ipv6(ip)

  ####################################################################
  ## conversions

  @doc """
  Converts an ip address to a string.

  For some situations, like converting an ip address to a hostname
  you might want hyphens as delimiters instead, in which case you
  should pass :hyphens as the `:style` term.

  Also takes, nil, in which case it emits an empty string.

  ```elixir
  iex> IP.to_string({255, 255, 255, 255})
  "255.255.255.255"

  iex> IP.to_string({255, 255, 255, 255}, :hyphens)
  "255-255-255-255"

  iex> IP.to_string({0, 0, 0, 0, 0, 0, 0, 1})
  "::1"
  ```
  """
  @spec to_string(addr | nil, :dots | :hyphens) :: String.t
  def to_string(ip_addr, style \\ :dots)
  def to_string(nil, _), do: ""
  def to_string({a, b, c, d}, :dots) do
    "#{a}.#{b}.#{c}.#{d}"
  end
  def to_string({a, b, c, d}, :hyphens) do
    "#{a}-#{b}-#{c}-#{d}"
  end
  def to_string(v6, _) when is_ipv6(v6) do
    # cheat by using the erlang builtin function.
    v6
    |> :inet.ntoa
    |> List.to_string
  end

  @doc """
  Converts an ip address from a string.

  ```elixir
  iex> IP.from_string!("255.255.255.255")
  {255, 255, 255, 255}
  ```
  """
  @spec from_string!(String.t) :: addr
  def from_string!(str) do
    case from_string(str) do
      {:ok, v} -> v
      _ -> raise ArgumentError, "malformed ip address string #{str}"
    end
  end

  @doc """
  Finds an ip address in a string, returning an ok or error tuple on failure.
  """
  @spec from_string(String.t) :: {:ok, addr} | {:error, :einval}
  def from_string(str) do
    str
    |> String.to_charlist
    |> :inet.parse_address()
  end

  @spec next(v4) :: v4
  @spec next(v6) :: v6
  @doc """
  returns the next ip address.

  ```elixir
  iex> IP.next({10, 0, 0, 255})
  {10, 0, 1, 0}
  iex> IP.next({0, 0, 0, 0, 0, 0, 0, 0xFFFF})
  {0, 0, 0, 0, 0, 0, 1, 0}
  ```
  """
  def next(ip) when is_ipv4(ip), do: from_integer(to_integer(ip) + 1, :v4)
  def next(ip) when is_ipv6(ip), do: from_integer(to_integer(ip) + 1, :v6)

  @spec prev(v4) :: v4
  @spec prev(v6) :: v6
  @doc """
  returns the previous ip address.

  ```elixir
  iex> IP.prev({10, 0, 1, 0})
  {10, 0, 0, 255}

  iex> IP.prev({0, 0, 0, 0, 0, 0, 1, 0})
  {0, 0, 0, 0, 0, 0, 0, 0xFFFF}
  ```
  """
  def prev(ip) when is_ipv4(ip), do: from_integer(to_integer(ip) - 1, :v4)
  def prev(ip) when is_ipv6(ip), do: from_integer(to_integer(ip) - 1, :v6)

  @spec mask(0..32, :v4_int) :: 0..0xFFFF_FFFF
  @spec mask(0..32, :v4_bin) :: <<_::32>>
  @spec mask(0..32, :v4)     :: v4
  @spec mask(0..32, :v6_int) :: 0..0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
  @spec mask(0..32, :v6_bin) :: <<_::128>>
  @spec mask(0..32, :v6)     :: v6
  @doc """
  generates an ip mask with specified bit_length.

  Can also generate raw integer or raw binary forms.

  Defaults to IPv4.

  ```elixir
  iex> IP.mask(32, :v4_int)
  0xFFFF_FFFF

  iex> IP.mask(32, :v4_bin)
  <<255, 255, 255, 255>>

  iex> IP.mask(32, :v4)
  {255, 255, 255, 255}

  iex> IP.mask(24, :v4)
  {255, 255, 255, 0}

  iex> IP.mask(0)
  {0, 0, 0, 0}

  iex> IP.mask(128, :v6)
  {0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF}

  iex> IP.mask(0, :v6)
  {0, 0, 0, 0, 0, 0, 0, 0}
  """
  def mask(bit_length, mode \\ :v4)
  def mask(0, :v4_int), do: 0
  def mask(bit_length, :v4_int) do
    <<i::unsigned-integer-size(32)>> = <<(-1 <<< (32-bit_length))::32>>
    i
  end
  def mask(bit_length, :v4_bin) do
    <<mask(bit_length, :v4_int)::unsigned-integer-size(32)>>
  end
  def mask(bit_length, :v4) do
    bit_length
    |> mask(:v4_int)
    |> from_integer(:v4)
  end
  def mask(0, :v6_int), do: 0
  def mask(bit_length, :v6_int) do
    <<i::unsigned-integer-size(128)>> = <<(-1 <<< (128-bit_length))::128>>
    i
  end
  def mask(bit_length, :v6) do
    bit_length
    |> mask(:v6_int)
    |> from_integer(:v6)
  end

  @spec prefix(v4, 0..32) :: v4
  @spec prefix(v6, 0..128) :: v6
  @doc """
  generates an the subnet prefix for a given ip address.

  ```elixir
  iex> IP.prefix({10, 0, 1, 23}, 24)
  {10, 0, 1, 0}
  ```
  """
  def prefix(ip, bit_length) when is_ipv4(ip) do
    ip
    |> to_integer
    |> Bitwise.&&&(mask(bit_length, :v4_int))
    |> from_integer(:v4)
  end
  def prefix(ip, bit_length) when is_ipv6(ip) do
    ip
    |> to_integer
    |> Bitwise.&&&(mask(bit_length, :v6_int))
    |> from_integer(:v6)
  end

  @spec localhost(:v4) :: v4
  @spec localhost(:v6) :: v6
  @doc """
  returns the canonical ip address of localhost.  Defaults to ipv4.

  ```elixir
  iex> IP.localhost()
  {127, 0, 0, 1}

  iex> IP.localhost(:v6)
  {0, 0, 0, 0, 0, 0, 0, 1}
  ```
  """
  def localhost(mode \\ :v4)
  def localhost(:v4), do: {127, 0, 0, 1}
  def localhost(:v6), do: {0, 0, 0, 0, 0, 0, 0, 1}

  ####################################################################
  ## random

  @doc """
  picks a random ip address from a range or a subnet.

  You may exclude individual ip addresses, ranges, or subnets to the
  `excludes` parameter and they won't be picked.

  Note that subnets will pick the prefix and broadcast addresses, if
  you would like to exclude those, you must add them explicitly to
  the `excludes` parameter.

  Warning: this algorithm is rather bad, so use only with blocks of
  less than about 1024.
  """
  def random(range_or_subnet, excludes \\ [])
  def random(range_or_subnet, excludes) do
    range_or_subnet
    |> Enum.map(&(&1))
    |> Kernel.--(expand(excludes))
    |> Enum.random
  end

  defp expand(excludes) do
    Enum.flat_map(excludes, fn
      exclude when is_ip(exclude) -> [exclude]
      exclude = %type{} when type in [IP.Range, IP.Subnet]->
        Enum.map(exclude, &(&1))
    end)
  end

  ####################################################################
  ## ETC

  @spec sigil_i(Macro.t, [byte]) :: Macro.t
  @doc """
  allows you to use the convenient ~i sigil to declare an IP address
  in its normal string form, instead of using the tuple form.

  ```elixir
  iex> import IP
  iex> ~i"10.0.0.1"
  {10, 0, 0, 1}
  ```

  also works for cidr-form subnet blocks
  ```elixir
  iex> import IP
  iex> ~i"10.0.0.0/24"
  %IP.Subnet{routing_prefix: {10, 0, 0, 0}, bit_length: 24}
  ```

  and generic IP ranges
  ```
  iex> import IP
  iex> ~i"10.0.0.3..10.0.0.7"
  %IP.Range{first: {10, 0, 0, 3}, last: {10, 0, 0, 7}}
  ```

  and socket addresses:
  ```
  iex> import IP
  iex> ~i"10.0.0.1:1234"
  %IP.SockAddr{family: :inet, port: 1234, addr: {10, 0, 0, 1}}
  ```

  and ip/subnet combinations for configuration:
  ```
  iex> import IP
  iex> ~i"10.0.0.4/24"config
  {{10, 0, 0, 4}, %IP.Subnet{routing_prefix: {10, 0, 0, 0}, bit_length: 24}}
  ```

  You can also use `~i` for ip addresses and subnets with the `m` suffix
  in the context of matches.

  ```
  iex> import IP
  iex> fn -> ~i"10.0.x.3"m = {10, 0, 1, 3}; x end.()
  1
  ```
  """
  defmacro sigil_i({:<<>>, meta, [definition]}, 'm') do
    caller_meta = Keyword.merge([file: __CALLER__.file, line: __CALLER__.line], meta)
    unless __CALLER__.context == :match do
      s(caller_meta, "~s/#{definition}/m must be used inside of a match")
    end
    # perform matching
    case String.split(definition, ".") do
      ip = [_, _, _, _] ->
        {:{}, meta, Enum.map(ip, &token_to_matchv(&1, caller_meta))}
      _ ->
        s(caller_meta, "invalid ip match #{definition}")
    end
  end
  defmacro sigil_i({:<<>>, meta, [definition]}, 'config') do
    caller_meta = Keyword.merge([file: __CALLER__.file, line: __CALLER__.line], meta)
    case String.split(definition, "/") do
      [ip_str, bit_size] ->
        ip = IP.from_string!(ip_str)
        subnet = IP.Subnet.of(ip, String.to_integer(bit_size))
        {ip, subnet}
      _ ->
        s(caller_meta, "invalid configuration definition #{definition}")
    end
    |> Macro.escape()
  end
  defmacro sigil_i({:<<>>, _meta, [definition]}, []) do
    # check to see if it has a slash, in which case it's an ip range
    cond do
      String.contains?(definition, "/") ->
        IP.Subnet.from_string!(definition)
      String.contains?(definition, "..") ->
        IP.Range.from_string!(definition)
      # only one colon is the sign of an ipv4 socket address
      match?([_ , _], String.split(definition, ":")) ->
        IP.SockAddr.from_string!(definition)
      true ->
        IP.from_string!(definition)
    end
    |> Macro.escape()
  end

  defp s(caller, msg), do: raise SyntaxError, caller ++ [description: msg]

  @ctx [context: Elixir, import: Kernel]
  defp token_to_matchv(<<x>> <> _ = int_str, meta) when x in ?0..?9 do
    int_val = String.to_integer(int_str)
    unless int_val in 0..255 do
      s(meta, "#{int_val} is out of the range for ipv4 addresses")
    end
    int_val
  end
  defp token_to_matchv(<<?^>> <> var, meta) do
    {:^, meta, [token_to_matchv(var, meta)]}
  end
  defp token_to_matchv(var, meta) do
    {:var!, @ctx, [{String.to_atom(var), meta, Elixir}]}
  end

  ####################################################################
  ## PRIVATE API

  # to_integer and from_integer are strictly private calls, only to be
  # called from within the IP.* family of modules

  @doc false
  @spec to_integer(addr) :: integer
  def to_integer(ip = {a, b, c, d}) when is_ipv4(ip) do
    <<i::unsigned-integer-size(32)>> = <<a, b, c, d>>
    i
  end
  def to_integer(ip = {a, b, c, d, e, f, g, h}) when is_ipv6(ip) do
    <<i::unsigned-integer-size(128)>> =
      <<a::unsigned-integer-size(16),
        b::unsigned-integer-size(16),
        c::unsigned-integer-size(16),
        d::unsigned-integer-size(16),
        e::unsigned-integer-size(16),
        f::unsigned-integer-size(16),
        g::unsigned-integer-size(16),
        h::unsigned-integer-size(16)>>
    i
  end

  @doc false
  @spec from_integer(integer, :v4) :: v4
  @spec from_integer(integer, :v6) :: v6
  def from_integer(i, :v4) when is_integer(i) and i >= 0 and i <= 0xFFFF_FFFF do
    <<a, b, c, d>> = <<i::unsigned-integer-size(32)>>
    {a, b, c, d}
  end
  def from_integer(i, :v6) when is_integer(i) do
    <<a::unsigned-integer-size(16),
      b::unsigned-integer-size(16),
      c::unsigned-integer-size(16),
      d::unsigned-integer-size(16),
      e::unsigned-integer-size(16),
      f::unsigned-integer-size(16),
      g::unsigned-integer-size(16),
      h::unsigned-integer-size(16)>> = <<i::128>>
    {a, b, c, d, e, f, g, h}
  end

  @doc false
  @spec type(v4) :: :v4
  @spec type(v6) :: :v6
  def type(addr) when is_ipv4(addr), do: :v4
  def type(addr) when is_ipv6(addr), do: :v6

  # useful for some guards
  @doc false
  defmacro octet_4(ip) do
    quote do elem(unquote(ip), 3) end
  end

  @doc false
  defmacro octet_34(ip) do
    quote do
      Bitwise.<<<(elem(unquote(ip), 2), 8) +
      elem(unquote(ip), 3)
    end
  end

  @doc false
  defmacro octet_24(ip) do
    quote do
      Bitwise.<<<(elem(unquote(ip), 1), 16) +
      Bitwise.<<<(elem(unquote(ip), 2), 8) +
      elem(unquote(ip), 3)
    end
  end

  @doc false
  defmacro octet_14(ip) do
    quote do
      Bitwise.<<<(elem(unquote(ip), 0), 24) +
      Bitwise.<<<(elem(unquote(ip), 1), 16) +
      Bitwise.<<<(elem(unquote(ip), 2), 8) +
      elem(unquote(ip), 3)
    end
  end

  @doc false
  defmacro octet_1(ip) do
    quote do Bitwise.<<<(elem(unquote(ip), 0), 24) end
  end

  @doc false
  defmacro octet_12(ip) do
    quote do
      Bitwise.<<<(elem(unquote(ip), 0), 24) +
      Bitwise.<<<(elem(unquote(ip), 1), 16)
    end
  end

  @doc false
  defmacro octet_13(ip) do
    quote do
      Bitwise.<<<(elem(unquote(ip), 0), 24) +
      Bitwise.<<<(elem(unquote(ip), 1), 16) +
      Bitwise.<<<(elem(unquote(ip), 2), 8)
    end
  end

end
