defmodule IPTest.RangeEnumerableTest do
  use ExUnit.Case, async: true

  import IP

  describe "count/2" do
    test "works with ipv4 ranges" do
      assert 5 == Enum.count(~i"10.0.0.3..10.0.0.7")
      assert 1 == Enum.count(~i"10.0.0.0..10.0.0.0")
    end
  end

  describe "Kernel.in/2" do
    test "works with ipv4 ranges" do
      assert ~i"10.0.0.0" in ~i"10.0.0.0..10.0.0.0"
      assert ~i"10.0.0.7" in ~i"10.0.0.3..10.0.0.7"
      assert ~i"10.0.0.15" in ~i"10.0.0.0..10.0.0.32"

      refute ~i"10.0.1.0" in ~i"10.0.0.0..10.0.0.255"
    end
  end

  describe "reduce-based list generation" do
    test "works with ipv4 ranges" do
      assert [{10, 0, 0, 3}, {10, 0, 0, 4}, {10, 0, 0, 5}] ==
        Enum.to_list(~i"10.0.0.3..10.0.0.5")
    end
  end

  describe "slice-based list generation" do
    test "works with subnets" do
      assert [{10, 0, 0, 3}, {10, 0, 0, 4}, {10, 0, 0, 5}] ==
        Enum.slice(~i"10.0.0.3..10.0.0.5", 0..4)
    end
  end
end
