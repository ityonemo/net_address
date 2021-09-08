defmodule IPTest.GuardTest do
  use ExUnit.Case, async: true

  require IP

  defp byte?(byte) when IP.is_byte(byte), do: true
  defp byte?(byte), do: false

  defp short?(short) when IP.is_short(short), do: true
  defp short?(short), do: false

  defp ipv4?(ipv4) when IP.is_ipv4(ipv4), do: true
  defp ipv4?(ipv4), do: false

  defp ipv6?(ipv6) when IP.is_ipv6(ipv6), do: true
  defp ipv6?(ipv6), do: false

  test "is_byte/1" do
    refute byte?(-1)
    refute byte?(256)
    assert byte?(0)
    assert byte?(128)
  end

  test "is_short/1" do
    refute short?(-1)
    refute short?(0x1_0000)
    assert short?(0x0FF0)
    assert short?(0)
  end

  test "is_ipv4/1" do
    refute ipv4?(:foo)
    refute ipv4?("10.0.0.1")
    assert ipv4?({10, 0, 0, 1})
    refute ipv4?({257, 0, 0, 0})
    refute ipv4?({0, -1, 0, 0})
    refute ipv4?({0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00})
  end

  test "is_ipv6/1" do
    refute ipv6?(:foo)
    refute ipv6?("10.0.0.1")
    assert ipv6?({0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00})
    refute ipv6?({0x1_0000, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00})
    refute ipv6?({-1, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00, 0xFF00})
  end

end

defmodule IPTest.GuardAsFunTest do
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
