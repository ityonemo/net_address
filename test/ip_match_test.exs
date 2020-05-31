defmodule IPTest.IPMatchTest do
  use ExUnit.Case, async: true

  @moduletag :match

  import IP

  test "ip addresses can match" do
    ~i"192.168.x.32"m = {192, 168, 10, 32}
    assert x == 10

    assert_raise MatchError, fn ->
      ~i"192.168.x.32"m = {192, 167, 10, 32}
    end

    ~i"192.168.a.b"m = {192, 168, 10, 32}
    assert a == 10
    assert b == 32
  end

  test "ip address matches can pin values" do
    v = 10
    ~i"192.168.^v.x"m = {192, 168, 10, 32}
    assert_raise MatchError, fn ->
      ~i"192.168.^v.x"m = {192, 168, 9, 32}
    end
  end

  test "ip address matches can match blank values" do
    ~i"192.168._.x"m = {192, 168, 10, 32}
    assert x = 32

    ~i"192.168._.y"m = {192, 168, 9, 32}
    assert y = 32
  end
end
