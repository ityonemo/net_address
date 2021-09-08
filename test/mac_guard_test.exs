defmodule MacTest.GuardTest do
  use ExUnit.Case, async: true

  require Mac

  def mac?(mac) when Mac.is_mac(mac), do: true
  def mac?(mac), do: false

  test "is_mac/1" do
    refute mac?(:foo)
    refute mac?("06:66:66:66:66:66")
    assert mac?({0x06, 0x66, 0x66, 0x66, 0x66, 0x66})
    refute mac?({257, 0x66, 0x66, 0x66, 0x66, 0x66})
    refute mac?({-1, 0x66, 0x66, 0x66, 0x66, 0x66})
  end

end

defmodule MacTest.GuardAsFunTest do
  use ExUnit.Case, async: true

  require Mac

  test "is_mac/1" do
    refute Mac.is_mac(:foo)
    refute Mac.is_mac("06:66:66:66:66:66")
    assert Mac.is_mac({0x06, 0x66, 0x66, 0x66, 0x66, 0x66})
    refute Mac.is_mac({257, 0x66, 0x66, 0x66, 0x66, 0x66})
    refute Mac.is_mac({-1, 0x66, 0x66, 0x66, 0x66, 0x66})
  end

end
