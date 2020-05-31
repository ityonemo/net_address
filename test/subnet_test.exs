defmodule IPTest.IPSubnetTest do
  use ExUnit.Case, async: true
  doctest IP.Subnet

  alias IP.Subnet
  import IP

  describe "new/2" do
    test "the basics work" do
      assert %Subnet{
        routing_prefix: ~i"10.0.0.0",
        bit_length: 24
      } == Subnet.new(~i"10.0.0.0", 24)
    end

    test "function clause errors if the routing prefix isn't an ip address" do
      assert_raise FunctionClauseError, fn -> Subnet.new("foo", 24) end
    end

    test "function clause errors if the bit length doesn't match the ip address size" do
      assert_raise FunctionClauseError, fn -> Subnet.new(~i"10.0.0.0", -1) end
      assert_raise FunctionClauseError, fn -> Subnet.new(~i"10.0.0.0", 33) end
    end

    test "argument errors if the routing prefix isn't the proper root" do
      assert_raise ArgumentError, fn -> Subnet.new(~i"10.0.0.1", 24) end
    end
  end

  describe "of/2" do
    test "the basics work" do
      assert %Subnet{
        routing_prefix: ~i"10.0.0.0",
        bit_length: 24
      } == Subnet.of(~i"10.0.0.3", 24)
    end

    test "function clause errors if the routing prefix isn't an ip address" do
      assert_raise FunctionClauseError, fn -> Subnet.of("foo", 24) end
    end

    test "function clause errors if the bit length doesn't match the ip address size" do
      assert_raise FunctionClauseError, fn -> Subnet.of(~i"10.0.0.0", -1) end
      assert_raise FunctionClauseError, fn -> Subnet.of(~i"10.0.0.0", 33) end
    end
  end

  describe "to_string/1" do
    test "works" do
      assert "10.0.0.0/24" = Subnet.to_string(~i"10.0.0.0/24")
    end
  end

  describe "from_string/1" do
    test "correctly figures out an ipv4 subnet" do
      assert ~i"10.0.0.0/24" == Subnet.from_string("10.0.0.0/24")
    end
    test "raises an argument error if something strange is passed" do
      assert_raise ArgumentError, fn -> Subnet.from_string("foo") end
      assert_raise ArgumentError, fn -> Subnet.from_string("10.0.0.2") end
      assert_raise ArgumentError, fn -> Subnet.from_string("10.0.0.2/24") end
    end
  end

  describe "inspecting the Subnet struct" do
    test "works as expected" do
      assert ~s(~i"10.0.0.0/24") == inspect(%Subnet{
        routing_prefix: {10, 0, 0, 0},
        bit_length: 24
      })
    end
  end

  describe "type/1" do
    test "correctly identifies ipv4 subnet" do
      assert :v4 == Subnet.type(~i"10.0.0.0/24")
    end
  end

  # GUARD TEST

  require Subnet

  describe "is_subnet/1" do
    test "works on basic subnets" do
      assert Subnet.is_subnet(~i"10.0.0.0/24")
    end

    test "fails if it's not a proper struct" do
      refute Subnet.is_subnet(:foo)
      refute Subnet.is_subnet(%{
        routing_prefix: (~i"10.0.0.0"),
        bit_length: -1
      })
    end

    test "fails if subnet has invalid bit lengths" do
      refute Subnet.is_subnet(%Subnet{
        routing_prefix: (~i"10.0.0.0"),
        bit_length: -1
      })

      refute Subnet.is_subnet(%Subnet{
        routing_prefix: (~i"10.0.0.0"),
        bit_length: 46
      })
    end
  end
end
