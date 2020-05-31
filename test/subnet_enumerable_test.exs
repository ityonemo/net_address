defmodule IPTest.SubnetEnumerableTest do
  use ExUnit.Case, async: true

  import IP

  describe "count/2" do
    test "works with ipv4 subnets" do
      assert 256 == Enum.count(~i"10.0.0.0/24")
      assert 1 == Enum.count(~i"10.0.0.0/32")
    end
  end

  describe "Kernel.in/2" do
    test "works with Subnets" do
      assert ~i"10.0.0.0" in ~i"10.0.0.0/24"
      assert ~i"10.0.0.128" in ~i"10.0.0.0/24"
      assert ~i"10.0.0.255" in ~i"10.0.0.0/24"

      refute ~i"10.0.1.0" in ~i"10.0.0.0/24"
    end
  end

  describe "reduce-based list generation" do
    test "works with subnets" do
      assert [{10, 0, 0, 0}, {10, 0, 0, 1}] ==
        Enum.to_list(~i"10.0.0.0/31")
    end
  end

  describe "slice-based list generation" do
    test "works with subnets" do
      assert [{10, 0, 0, 0}, {10, 0, 0, 1}] ==
        Enum.slice(~i"10.0.0.0/31", 0..2)
    end
  end
end
