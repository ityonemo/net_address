defmodule IP.Subnet do
  @moduledoc """
  Convenience type which encapsulates the idea of an IP subnet.  See:
  https://en.wikipedia.org/wiki/Subnetwork

  ### NB
  The distinction between an `IP.Range` and an `IP.Subnet` is that a Subnet
  must have its bounds at certain powers-of-two and multiple thereof that
  are governed by the subnet bit-length.  A range is not constrained and
  is a simple "dumb list of ip addresses".  Typically ranges will be proper
  subsets of Subnets.

  ### Enumerable

  Implements the Enumerable protocol, so the following sorts of things
  are possible:

  ```elixir
  iex> import IP
  iex> Enum.map(~i"10.0.0.4/30", &IP.to_string/1)
  ["10.0.0.4", "10.0.0.5", "10.0.0.6", "10.0.0.7"]
  ```
  """

  @enforce_keys [:routing_prefix, :bit_length]

  defstruct @enforce_keys ++ [:__enum__]

  require IP

  @typedoc "ip subnet typed to ipv4 or ipv6"
  @type t(ip_type) :: %__MODULE__{
    routing_prefix: ip_type,
    bit_length: 0..128
  }

  @typedoc "generic ip subnet"
  @type t :: t(IP.v4) | t(IP.v6)

  @spec is_subnet(any) :: Macro.t
  @doc """
  true if the term is a subnet struct, and it's valid.

  usable in guards.

  ```elixir
  iex> import IP
  iex> IP.Subnet.is_subnet(~i"10.0.0.0/32")
  true
  iex> IP.Subnet.is_subnet(:foo)
  false
  iex> IP.Subnet.is_subnet(%IP.Subnet{routing_prefix: {10, 0, 0, 0}, bit_length: 33})
  false
  ```
  """
  defguard is_subnet(subnet) when is_struct(subnet) and
    :erlang.map_get(:__struct__, subnet) == __MODULE__ and
    ((IP.is_ipv4(:erlang.map_get(:routing_prefix, subnet)) and
      :erlang.map_get(:bit_length, subnet) <= 32 and
      :erlang.map_get(:bit_length, subnet) >= 0) or
     (IP.is_ipv6(:erlang.map_get(:routing_prefix, subnet)) and
      :erlang.map_get(:bit_length, subnet) <= 128 and
      :erlang.map_get(:bit_length, subnet) >= 0))

  @spec new(IP.v4, 0..32) :: t(IP.v4)
  @spec new(IP.v6, 0..128) :: t(IP.v6)
  @doc """
  creates a new IP Subnet struct from a routing prefix and bit length.

  The routing prefix must be an actual routing prefix for the bit length,
  otherwise it will raise `ArgumentError`.  If you are attempting to find the
  subnet for a given ip address, use `of/2`
  """
  def new(routing_prefix, bit_length)
    when IP.is_ipv4(routing_prefix) and
         0 <= bit_length and bit_length <= 32 do

    unless routing_prefix == IP.prefix(routing_prefix, bit_length) do
      raise ArgumentError, "the routing prefix is not a proper ip subnet prefix.  Use IP.Subnet.of/2 instead."
    end

    %__MODULE__{
      routing_prefix: routing_prefix,
      bit_length: bit_length
    }
  end
  def new(routing_prefix, bit_length)
    when IP.is_ipv6(routing_prefix) and
         0 <= bit_length and bit_length <= 128 do

    unless routing_prefix == IP.prefix(routing_prefix, bit_length) do
      raise ArgumentError, "the routing prefix is not a proper ip subnet prefix.  Use IP.Subnet.of/2 instead."
    end

    %__MODULE__{
      routing_prefix: routing_prefix,
      bit_length: bit_length
    }
  end

  @spec of(IP.v4, 0..32) :: t(IP.v4)
  @spec of(IP.v6, 0..128) :: t(IP.v6)
  @doc """
  creates a corresponding IP subnet associated with a given IP address and
  bit length.
  """
  def of(ip_addr, bit_length)
    when IP.is_ipv4(ip_addr) and 0 <= bit_length and bit_length <= 32 do

    %__MODULE__{
      routing_prefix: IP.prefix(ip_addr, bit_length),
      bit_length: bit_length
    }
  end
  def of(ip_addr, bit_length)
    when IP.is_ipv6(ip_addr) and 0 <= bit_length and bit_length <= 128 do

    %__MODULE__{
      routing_prefix: IP.prefix(ip_addr, bit_length),
      bit_length: bit_length
    }
  end

  @spec to_string(t) :: String.t
  @doc """
  converts an ip subnet to standard CIDR-form, with a slash delimiter.

  ```elixir
  iex> IP.Subnet.to_string(%IP.Subnet{routing_prefix: {10, 0, 0, 0}, bit_length: 24})
  "10.0.0.0/24"
  ```
  """
  def to_string(subnet) when is_subnet(subnet) do
    "#{IP.to_string(subnet.routing_prefix)}/#{subnet.bit_length}"
  end

  @spec from_string!(String.t) :: t | no_return
  @doc """
  converts a string to an ip subnet.

  The delimiter must be "..", as this is compatible with both
  ipv4 and ipv6 addresses

  checks if the values are sensible.

  ```elixir
  iex> import IP
  iex> IP.Subnet.from_string!("10.0.0.0/24")
  %IP.Subnet{
    routing_prefix: {10, 0, 0, 0},
    bit_length: 24
  }
  ```
  """
  def from_string!(subnet_str) do
    case from_string(subnet_str) do
      {:ok, subnet} -> subnet
      {:error, :einval} ->
        raise ArgumentError, "malformed subnet string #{subnet_str}"
      {:error, :invalid_subnet} ->
        raise ArgumentError, "invalid subnet value in #{subnet_str}"
      {:error, :not_a_binary} ->
        raise ArgumentError, "invalid input #{inspect subnet_str}"
    end
  end

  @doc """
  Finds an ip subnet in a string, returning an ok or error tuple on failure.
  """
  def from_string(subnet_str) when is_binary(subnet_str) do
    with [routing_prefix_str, bit_length_str] <- String.split(subnet_str, "/"),
         {:ok, routing_prefix} <- IP.from_string(routing_prefix_str),
         {bit_length, ""} <- Integer.parse(bit_length_str),
         true <- valid_subnet(routing_prefix, bit_length) do
      {:ok, of(routing_prefix, bit_length)}
    else
      list when is_list(list) -> {:error, :einval}
      :error -> {:error, :invalid_subnet}
      false -> {:error, :invalid_subnet}
      {int, _} when is_integer(int) -> {:error, :einval}
      error -> error
    end
  end
  def from_string(_), do: {:error, :not_a_binary}

  @doc """
  finds an ip address and subnet together from a `config representation`
  (this is an ip/cidr string where the ip is not necessarily the routing
  prefix for the cidr block).

  returns `{:ok, ip, subnet}` if the config string is valid;
  `{:error, reason}` otherwise.
  """
  def config_from_string(config_str) when is_binary(config_str) do
    with [ip_str, bit_length_str] <- String.split(config_str, "/"),
         {:ok, ip} <- IP.from_string(ip_str),
         {bit_length, ""} <- Integer.parse(bit_length_str),
         true <- valid_subnet(ip, bit_length) do
      {:ok, ip, of(ip, bit_length)}
    else
      list when is_list(list) -> {:error, :einval}
      :error -> {:error, :invalid_subnet}
      false -> {:error, :invalid_subnet}
      {int, _} when is_integer(int) -> {:error, :einval}
      error -> error
    end
  end
  def config_from_string(_), do: {:error, :not_a_binary}

  @doc """
  finds an ip address and subnet together from a `config representation`
  (this is an ip/cidr string where the ip is not necessarily the routing
  prefix for the cidr block).

  returns `{ip, subnet}` if the config string is valid; raises otherwise.
  """
  def config_from_string!(config_str) do
    case config_from_string(config_str) do
      {:ok, ip, subnet} -> {ip, subnet}
      {:error, :einval} ->
        raise ArgumentError, "malformed subnet string #{config_str}"
      {:error, :invalid_subnet} ->
        raise ArgumentError, "invalid subnet value in #{config_str}"
      {:error, :not_a_binary} ->
        raise ArgumentError, "invalid input #{inspect config_str}"
    end
  end

  require IP
  defp valid_subnet(ip, length) when IP.is_ipv4(ip), do: length in 0..32
  defp valid_subnet(ip, length) when IP.is_ipv6(ip), do: length in 0..128

  @spec broadcast(t(IP.v4)) :: IP.v4
  @doc """
  finds the broadcast address for a subnet

  ```elixir
  iex> import IP
  iex> IP.Subnet.broadcast(~i"10.0.0.0/23")
  {10, 0, 1, 255}
  """
  def broadcast(subnet = %{routing_prefix: rp, bit_length: bl}) when is_subnet(subnet) do
    mask = bl
    |> IP.mask(:v4)
    |> IP.to_integer

    inv_mask = Bitwise.bxor(mask, 0xFFFF_FFFF)

    rp
    |> IP.to_integer
    |> Bitwise.&&&(mask)
    |> Bitwise.|||(inv_mask)
    |> IP.from_integer(:v4)
  end

  @spec prefix(t) :: IP.addr
  @doc """
  retrieves the routing prefix from a subnet.

  ```elixir
  iex> import IP
  iex> IP.Subnet.prefix(~i"10.0.0.0/24")
  {10, 0, 0, 0}
  ```
  """
  def prefix(%{routing_prefix: rp}), do: rp

  @spec bitlength(t(IP.v4)) :: 0..32
  @spec bitlength(t(IP.v6)) :: 0..128
  @doc """
  retrieves the bitlength from a subnet.

  ```elixir
  iex> import IP
  iex> IP.Subnet.bitlength(~i"10.0.0.0/24")
  24
  ```
  """
  def bitlength(%{bit_length: bl}), do: bl

  @spec netmask(t) :: IP.addr
  @doc """
  computes the netmask for a subnet.

  ```elixir
  iex> import IP
  iex> IP.Subnet.netmask(~i"10.0.0.0/24")
  {255, 255, 255, 0}
  ```
  """
  def netmask(%{routing_prefix: rp, bit_length: bl})
    when IP.is_ipv4(rp), do: IP.mask(bl, :v4)
  def netmask(%{routing_prefix: rp, bit_length: _bl})
    when IP.is_ipv6(rp), do: raise "not implemented yet"

  ###################################################################
  ## PRIVATE API
  @spec type(t(IP.v4)) :: :v4
  @spec type(t(IP.v6)) :: :v6
  @doc false
  def type(subnet) when is_subnet(subnet), do: IP.type(subnet.routing_prefix)

end

defimpl Inspect, for: IP.Subnet do
  import Inspect.Algebra

  def inspect(subnet, _opts) do
    concat(["~i\"", IP.Subnet.to_string(subnet) , "\""])
  end
end

defimpl Enumerable, for: IP.Subnet do
  alias IP.Subnet

  @spec count(Subnet.t) :: {:ok, non_neg_integer}
  def count(subnet) do
    import Bitwise
    {:ok, 2 <<< (31 - subnet.bit_length)}
  end

  @spec member?(Subnet.t, IP.addr) :: {:ok, boolean}
  def member?(subnet, this_ip) do
    {:ok, subnet.routing_prefix <= this_ip and
          this_ip <= Subnet.broadcast(subnet)}
  end

  @spec reduce(Subnet.t, Enumerable.acc, fun) :: Enumerable.result
  def reduce(_subnet, {:halt, acc}, _), do: {:halted, acc}
  def reduce(subnet, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(subnet, &1, fun)}
  def reduce(subnet = %{__enum__: nil}, {:cont, acc}, fun) do
    placeholder = {IP.next(subnet.routing_prefix), Subnet.broadcast(subnet)}
    reduce(%{subnet | __enum__: placeholder},
      fun.(subnet.routing_prefix, acc), fun)
  end
  def reduce(subnet = %{__enum__: {this, last}}, {:cont, acc}, fun) when this <= last do
    placeholder = {IP.next(this), last}
    reduce(%{subnet | __enum__: placeholder}, fun.(this, acc), fun)
  end
  def reduce(_, {:cont, acc}, _fun), do: {:done, acc}

  @spec slice(Subnet.t) :: {:ok, non_neg_integer, Enumerable.slicing_fun}
  def slice(subnet) do
    type = Subnet.type(subnet)
    {:ok, count} = count(subnet)

    {:ok, count, fn start, length ->
      first_int = IP.to_integer(subnet.routing_prefix) + start
      last_int = first_int + length - 1
      Enum.map(first_int..last_int, &IP.from_integer(&1, type))
    end}
  end
end
