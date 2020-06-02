defmodule IP.SockAddr do

  @moduledoc """
  Tools for handling the `t::socket.sockaddr_in4/0` type.

  Unless you're using the `:socket` library, for low level socket
  access you probably won't need this module!

  Support for inet6 forthcoming.
  """

  @enforce_keys [:family, :addr, :port]
  defstruct @enforce_keys ++ [:flowinfo, :scope_id]

  @type t :: :socket.sockaddr_in4 |
             :socket.sockaddr_in6

  @spec from_string!(String.t) :: t
  @doc """
  Creates an elixir struct, which is compatible with `:socket` module's
  sockaddr_in4 type.

  You may pass this, for example to `:socket.bind/2`
  """
  def from_string!(sockaddr_str) do
    case from_string(sockaddr_str) do
      {:ok, sockaddr} -> sockaddr
      _ ->
        raise ArgumentError, "invalid sockaddr string: \"#{sockaddr_str}\""
    end
  end

  @spec from_string(String.t) :: {:ok, t} | {:error, term}
  @doc """
  Like `from_string/1`, but returns an ok or error tuple on failure.
  """
  def from_string(sockaddr_str) do
    with [addr_str, port_str] <- String.split(sockaddr_str, ":"),
         {:ok, addr} <- IP.from_string(addr_str),
         {port, ""} when 0 <= port and port <= 65535 <- Integer.parse(port_str) do

      {:ok, %__MODULE__{family: :inet, addr: addr, port: port}}

    else
      list when is_list(list) -> {:error, :einval}
      :error -> {:error, :einval}
      {port, ""} -> {:error, "port #{port} not in range"}
      error -> error
    end
  end

  @spec to_string(t) :: String.t
  @doc """
  converts a `t::socket.sockaddr_in4` value to

  Compatible with sockaddr maps returned by the socket library, not
  selective on the `IP.SockAddr` struct.
  """
  def to_string(sockaddr = %{family: :inet}) do
    "#{IP.to_string sockaddr.addr}:#{sockaddr.port}"
  end

end

defimpl Inspect, for: IP.SockAddr do
  import Inspect.Algebra

  def inspect(subnet, _opts) do
    concat(["~i\"", IP.SockAddr.to_string(subnet) , "\""])
  end
end
