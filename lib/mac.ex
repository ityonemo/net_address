defmodule Mac do
  @moduledoc """
  Mac Address value tool module.
  """

  @typedoc "general mac addresses are six octets."
  @type t :: {byte, byte, byte, byte, byte, byte}

  require IP

  #############################################################################
  ## GUARDS

  @spec is_mac(any) :: Macro.t
  @doc """
  checks to see if a value is a mac address.

  usable in guards.

  ```elixir
  iex> Mac.is_mac({10, 0, 0, 1, 1, 1})
  true
  iex> Mac.is_mac(:foo)
  false
  iex> Mac.is_mac({0x100, 0, 0, 1, 1, 1})
  false
  iex> Mac.is_mac({10, 0, 0, 1, 1, 1, 1})
  false
  ```
  """
  defguard is_mac(mac_addr) when is_tuple(mac_addr) and
    (tuple_size(mac_addr) == 6) and
    (IP.is_byte(elem(mac_addr, 0))) and
    (IP.is_byte(elem(mac_addr, 1))) and
    (IP.is_byte(elem(mac_addr, 2))) and
    (IP.is_byte(elem(mac_addr, 3))) and
    (IP.is_byte(elem(mac_addr, 4))) and
    (IP.is_byte(elem(mac_addr, 5)))

  @spec is_local_mac(any) :: Macro.t
  @doc """
  checks to see if a value is a local mac address, by convention
  it means it has been assigned by a VM system.

  usable in guards.

  ```elixir
  iex> Mac.is_local_mac({0xF2, 0, 0, 1, 1, 1})
  true
  iex> Mac.is_local_mac({0xF0, 0, 0, 1, 1, 1})
  false
  ```
  """
  defguard is_local_mac(mac_addr) when is_mac(mac_addr) and
    ((elem(mac_addr, 0) - div(elem(mac_addr, 0), 4) * 4) in [2, 3])

  @spec is_universal_mac(any) :: Macro.t
  @doc """
  checks to see if a value is a local mac address, by convention
  it means it has been assigned by the hardware manufacturer

  usable in guards.

  ```elixir
  iex> Mac.is_universal_mac({0xF2, 0, 0, 1, 1, 1})
  false
  iex> Mac.is_universal_mac({0xF0, 0, 0, 1, 1, 1})
  true
  ```
  """
  defguard is_universal_mac(mac_addr) when is_mac(mac_addr) and
  ((elem(mac_addr, 0) - div(elem(mac_addr, 0), 4) * 4) in [0, 1])

  #############################################################################
  ## API

  @spec to_string(t) :: String.t
  @doc """
  Converts a mac address to a string

  ```elixir
  iex> Mac.to_string({255, 255, 255, 255, 255, 255})
  "FF:FF:FF:FF:FF:FF"

  iex> Mac.to_string({6, 1, 2, 3, 4, 5})
  "06:01:02:03:04:05"
  ```
  """
  def to_string(mac_addr) do
    mac_addr
    |> Tuple.to_list
    |> Enum.map(fn val ->
      case Integer.to_string(val, 16) do
        <<a>> -> <<"0", a>>
        any -> any
      end
    end)
    |> Enum.join(":")
  end

  @spec from_string(String.t) :: t
  @doc """
  converts a mac address string and turns it into a proper
  mac address datatype.  Supports standard colon format,
  BMC hyphen format, and arista/cisco switch dot format.

  ```elixir
  iex> Mac.from_string("06:AA:07:FB:B6:1E")
  {0x06, 0xAA, 0x07, 0xFB, 0xB6, 0x1E}

  iex> Mac.from_string("06:aa:07:fb:b6:1e")
  {0x06, 0xAA, 0x07, 0xFB, 0xB6, 0x1E}

  iex> Mac.from_string("06-AA-07-FB-B6-1E")
  {0x06, 0xAA, 0x07, 0xFB, 0xB6, 0x1E}

  iex> Mac.from_string("06aa.07fb.b61e")
  {0x06, 0xAA, 0x07, 0xFB, 0xB6, 0x1E}
  ```
  """
  def from_string(mac_string = <<a::binary-size(2), ?:,
                                 b::binary-size(2), ?:,
                                 c::binary-size(2), ?:,
                                 d::binary-size(2), ?:,
                                 e::binary-size(2), ?:,
                                 f::binary-size(2)>>) do
    from_list([a, b, c, d, e, f], mac_string)
  end
  def from_string(mac_string = <<a::binary-size(2), ?-,
                                 b::binary-size(2), ?-,
                                 c::binary-size(2), ?-,
                                 d::binary-size(2), ?-,
                                 e::binary-size(2), ?-,
                                 f::binary-size(2)>>) do
    from_list([a, b, c, d, e, f], mac_string)
  end
  def from_string(mac_string = <<a::binary-size(2),
                                 b::binary-size(2), ?.,
                                 c::binary-size(2),
                                 d::binary-size(2), ?.,
                                 e::binary-size(2),
                                 f::binary-size(2)>>) do
    from_list([a, b, c, d, e, f], mac_string)
  end
  def from_string(mac_string) when is_binary(mac_string) do
    raise ArgumentError, "malformed mac address string #{mac_string}"
  end
  def from_string(mac_string) do
    raise ArgumentError, "#{inspect mac_string} is not a string"
  end

  defp from_list(list, source) do
    list
    |> Enum.map(&String.to_integer(&1, 16))
    |> List.to_tuple
  rescue
    _ -> reraise ArgumentError, "malformed mac address string #{source}", __STACKTRACE__
  end

  @top_val 0x1_0000_0000_0000
  @spec mask(0..48, :integer) :: 0..0xFFFF_FFFF_FFFF
  @spec mask(0..48, :binary) :: <<_::48>>
  @spec mask(0..48, :mac) :: t
  @doc """
  generates a mask for the first n bits of the mac address.

  ```elixir
  iex> Mac.mask(1)
  {0x80, 0, 0, 0, 0, 0}
  iex> Mac.mask(16)
  {0xFF, 0xFF, 0, 0, 0, 0}
  ```

  you may pass another mode to the second parameter for other formats.

  ```elixir
  iex> Mac.mask(16, :binary)
  <<0xFF, 0xFF, 0, 0, 0, 0>>
  iex> Mac.mask(16, :integer)
  0xFFFF_0000_0000
  ```
  """
  def mask(bits, mode \\ :mac) when is_integer(bits) and 0 <= bits and bits <= 48 do
    import Bitwise
    int_val = @top_val - (@top_val >>> bits)
    case mode do
      :integer -> int_val
      :binary -> <<int_val :: 48>>
      :mac -> from_integer(int_val)
    end
  end

  @spec random() :: t
  @spec random(nil, 48) :: t
  @spec random(t, 0..48) :: t
  @doc """
  generates a random mac address from another, with a mask value
  """
  def random(src \\ nil, bits \\ 48)
  def random(nil, 48) do
    0..0xFFFF_FFFF_FFFF
    |> Enum.random
    |> from_integer
  end
  def random(src, bits) when is_mac(src) and
      is_integer(bits) and 0 <= bits and bits <= 48 do

    import Bitwise
    mask = mask(bits, :integer)
    <<rbits::unsigned-integer-size(48)>> = :crypto.strong_rand_bytes(6)
    rval = rbits &&& (~~~mask)

    src
    |> to_integer
    |> Bitwise.&&&(mask)
    |> Bitwise.|||(rval)
    |> from_integer
  end

  @spec sigil_m(Macro.t, [byte]) :: Macro.t
  @doc """
  allows you to use the convenient ~m sigil to declare a Mac address
  in its normal string form, instead of using the tuple form.

  ```elixir
  iex> import Mac
  iex> ~m"06:66:F4:12:34:56"
  {0x06, 0x66, 0xF4, 0x12, 0x34, 0x56}
  ```
  """
  defmacro sigil_m({:<<>>, _meta, [string]}, _) do
    content = Mac.from_string(string)

    quote do
      unquote(Macro.escape(content))
    end
  end

  ####################################################################
  ## PRIVATE API

  # to_integer and from_integer are strictly private calls, only to be
  # called from within the IP.* family of modules

  @doc false
  @spec to_integer(t) :: integer
  def to_integer(mac = {a, b, c, d, e, f}) when is_mac(mac) do
    <<i::unsigned-integer-size(48)>> = <<a, b, c, d, e, f>>
    i
  end

  @doc false
  @spec from_integer(integer) :: t
  def from_integer(i) when is_integer(i) and i >= 0 and i <= 0xFFFF_FFFF_FFFF do
    <<a, b, c, d, e, f>> = <<i::unsigned-integer-size(48)>>
    {a, b, c, d, e, f}
  end

end
