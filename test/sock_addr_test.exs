defmodule IPTest.SockAddrTest do
  use ExUnit.Case, async: true
  doctest IP.Range

  alias IP.SockAddr
  import IP

  describe "from_string!/1" do
    test "converts the socket address correctly" do
      assert %{family: :inet, addr: {127, 0, 0, 1}, port: 0} =
        SockAddr.from_string!("127.0.0.1:0")
    end

    test "fails with argument error on malformed strings" do
      assert_raise ArgumentError, fn -> SockAddr.from_string!("foo") end
      assert_raise ArgumentError, fn -> SockAddr.from_string!("foo:bar") end
      assert_raise ArgumentError, fn -> SockAddr.from_string!("127.0.0.1:foo") end
      assert_raise ArgumentError, fn -> SockAddr.from_string!("127.0.0.1:-1") end
      assert_raise ArgumentError, fn -> SockAddr.from_string!("127.0.0.1:70000") end
    end
  end

  describe "to_string/1" do
    test "converts socket addresses back to strings" do
      assert "127.0.0.1:0" =
        SockAddr.to_string(%{family: :inet, addr: {127, 0, 0, 1}, port: 0})
    end
  end
end
