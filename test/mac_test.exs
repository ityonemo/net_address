defmodule MacTest do
  use ExUnit.Case, async: true
  doctest Mac

  describe "converting string to mac" do
    test "fails when it's malformed" do
      assert_raise ArgumentError, fn ->
        Mac.from_string!("AB:12:34")
      end
      assert_raise ArgumentError, fn ->
        Mac.from_string!("foo")
      end
      assert_raise ArgumentError, fn ->
        Mac.from_string!("123:99:AB:CD:EF:12")
      end
      assert_raise ArgumentError, fn ->
        Mac.from_string!("123:99:AB:CD:EF:12:34")
      end
      assert_raise ArgumentError, fn ->
        Mac.from_string!("123:99:QX:CD:EF:12:34")
      end
    end
  end

  describe "random values are sane" do
    test "when totally random" do
      assert Mac.is_mac(Mac.random())
    end

    test "when masked" do
      assert {0x06, 0x66, _, _, _, _} =
        Mac.random({0x06, 0x66, 0, 0, 0, 0}, 16)
    end
  end
end
