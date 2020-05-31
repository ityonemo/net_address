defmodule IPTest.IPRangeTest do
  use ExUnit.Case, async: true
  doctest IP.Range

  alias IP.Range
  import IP

  describe "new/2" do
    test "the basics work" do
      assert %Range{
        first: ~i"10.0.0.0",
        last: ~i"10.0.0.1"
      } == Range.new(~i"10.0.0.0", ~i"10.0.0.1")
    end

    test "function clause errors if the values aren't ip addresses" do
      assert_raise FunctionClauseError, fn -> Range.new("foo", "10.0.0.1") end
      assert_raise FunctionClauseError, fn -> Range.new("10.0.0.0", "foo") end
    end

    test "argument errors if the range values are flipped in order" do
      assert_raise ArgumentError, fn -> Range.new(~i"10.0.0.1", ~i"10.0.0.0") end
    end
  end

  describe "to_string/1" do
    test "works" do
      assert "10.0.0.0..10.0.0.1" = Range.to_string(Range.new(~i"10.0.0.0", ~i"10.0.0.1"))
    end
  end

  describe "from_string/1" do
    test "correctly figures out an ipv4 subnet" do
      assert %Range{
        first: ~i"10.0.0.0",
        last: ~i"10.0.0.1"
      } == Range.from_string("10.0.0.0..10.0.0.1")
    end

    test "raises an argument error if something strange is passed" do
      assert_raise ArgumentError, fn -> Range.from_string("foo") end
      assert_raise ArgumentError, fn -> Range.from_string("10.0.0.2") end
      assert_raise ArgumentError, fn -> Range.from_string("10.0.0.2/24") end
    end
  end

  describe "inspecting the Range struct" do
    test "works as expected" do
      assert ~s(~i"10.0.0.0..10.0.0.1") == inspect(%Range{
        first: {10, 0, 0, 0},
        last: {10, 0, 0, 1}
      })
    end
  end

  describe "type/1" do
    test "correctly identifies ipv4 subnet" do
      assert :v4 == Range.type(~i"10.0.0.0..10.0.0.1")
    end
  end

  # GUARD TEST

  require Range

  describe "is_range/1" do
    test "works on basic ip lasce-" do
      assert Range.is_range(~i"10.0.0.0..10.0.0.3")
    end

    test "fails if it's not a proper struct" do
      refute Range.is_range(:foo)
      refute Range.is_range(%{
        first: ~i"10.0.0.0",
        last: ~i"10.0.0.3"
      })
    end

    test "fails if range has bounding values" do
      refute Range.is_range(%Range{
        first: ~i"10.0.0.0",
        last: ~i"::1"
      })
      refute Range.is_range(%Range{
        first: ~i"10.0.0.3",
        last: ~i"10.0.0.1"
      })
    end
  end
end
