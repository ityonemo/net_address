defmodule IPTest.IPMatchTest do
  use ExUnit.Case, async: true

  @moduletag :match

  import IP

  test "ip addresses can match" do
    ~i"192.168.x.32"m = {192, 168, 10, 32}
    assert x == 10

    assert_raise MatchError, fn ->
      ~i"192.168._x.32"m = {192, 167, 10, 32}
    end

    ~i"192.168.a.b"m = {192, 168, 10, 32}
    assert a == 10
    assert b == 32
  end

  test "ip address matches can pin values" do
    v = 10
    ~i"192.168.^v._x"m = {192, 168, 10, 32}
    assert_raise MatchError, fn ->
      ~i"192.168.^v._x"m = {192, 168, 9, 32}
    end
  end

  test "ip address matches can match blank values" do
    ~i"192.168._.x"m = {192, 168, 10, 32}
    assert x = 32

    ~i"192.168._.y"m = {192, 168, 9, 32}
    assert y = 32
  end

  describe "sigil_i" do
    test "raises on invalid ip forms" do
      assert_raise SyntaxError,
        "nofile:2: invalid ip match 10.1.1.1.1",
        fn ->
          Code.compile_string("""
          import IP
          ~i"10.1.1.1.1"m = {10, 1, 1, 1}
          """)
        end

      assert_raise SyntaxError,
        "nofile:2: 1000 is out of the range for ipv4 addresses",
        fn ->
          Code.compile_string("""
          import IP
          ~i"10.1000.3.1"m = {10, 1, 1, 1}
          """)
        end

      assert_raise SyntaxError,
        "nofile:2: ~s/10.1.1.1/m must be used inside of a match",
        fn ->
          Code.compile_string("""
          import IP
          ~i"10.1.1.1"m
          """)
        end
    end
  end
end
