defmodule IPTest do
  use ExUnit.Case, async: true
  doctest IP

  test "malformed ip addresses don't parse" do
    assert_raise ArgumentError, fn ->
      IP.from_string!("this.is.not.an.ip")
    end
  end

  describe "type function" do
    test "identifies ipv4" do
      assert :v4 == IP.type({10, 0, 0, 1})
    end
    test "identifies ipv6" do
      assert :v6 == IP.type({0, 0, 0, 0, 0, 0, 0, 1})
    end
  end
end
