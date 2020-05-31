defmodule IPTest.GuardTest do
  use ExUnit.Case, async: true

  require IP

  test "is_byte/1" do
    refute IP.is_byte(-1)
    refute IP.is_byte(256)
    assert IP.is_byte(0)
    assert IP.is_byte(128)
  end

  test "is_short/1" do
    refute IP.is_short(-1)
    refute IP.is_short(0x1_0000)
    assert IP.is_short(0x0FF0)
    assert IP.is_short(0)
  end

  test "is_ipv4/1" do
    refute IP.is_ipv4(:foo)
    refute IP.is_ipv4("10.0.0.1")
    assert IP.is_ipv4({10, 0, 0, 1})
    refute IP.is_ipv4({257, 0, 0, 0})
    refute IP.is_ipv4({0, -1, 0, 0})
    refute IP.is_ipv4({0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00})
  end

  test "is_ipv6/1" do
    refute IP.is_ipv6(:foo)
    refute IP.is_ipv6("10.0.0.1")
    assert IP.is_ipv6({0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00})
    refute IP.is_ipv6({0x1_0000, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00})
    refute IP.is_ipv6({-1, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00})
  end

end
