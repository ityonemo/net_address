defmodule IPTest.IPRandomTest do
  use ExUnit.Case, async: true

  use ExUnitProperties

  @moduletag :property

  property "random numbers fall in their subnet" do
    check all address_int <- integer(0..0xFFFF_FFFF),
              cidr <- integer(0..12) do
      subnet = address_int
      |> IP.from_integer(:v4)
      |> IP.Subnet.of(32 - cidr)

      assert IP.random(subnet) in subnet
    end
  end

  property "random numbers fall in their range" do
    check all first_int <- integer(0..0xFFFF_FFFF),
              count <- integer(0..0xFFF) do

      first = IP.from_integer(first_int, :v4)
      last = first_int + count
      |> min(0xFFFF_FFFF)
      |> IP.from_integer(:v4)

      range = IP.Range.new(first, last)

      assert IP.random(range) in range
    end
  end

  property "individual ip addresses can be excluded" do
    import Bitwise

    check all address_int <- integer(0..0xFFFF_FFFF),
              cidr <- integer(1..12),
              exclusions <- integer(1..(1 <<< (cidr - 1))) do

      subnet = address_int
      |> IP.from_integer(:v4)
      |> IP.Subnet.of(32 - cidr)

      exclude = for _ <- 1..exclusions, do: IP.random(subnet)

      pick = IP.random(subnet, exclude)

      assert pick in subnet
      refute pick in exclude
    end
  end

  property "subnets can be excluded" do
    check all address_int <- integer(0..0xFFFF_FFFF),
              cidr <- integer(1..12),
              ex_cidr <- integer(0..cidr - 1) do

      subnet = address_int
      |> IP.from_integer(:v4)
      |> IP.Subnet.of(32 - cidr)

      ex_cidr = subnet
      |> IP.random
      |> IP.Subnet.of(32 - ex_cidr)

      pick = IP.random(subnet, [ex_cidr])

      assert pick in subnet
      refute pick in ex_cidr
    end
  end

  property "ranges can be excluded" do
    import Bitwise
    check all address_int <- integer(0..0xFFFF_FFFF),
              cidr <- integer(1..12),
              range_first_delta <- integer(1..(1 <<< cidr)),
              range_count <- integer(1..(1 <<< cidr)) do

      subnet = address_int
      |> IP.from_integer(:v4)
      |> IP.Subnet.of(32 - cidr)

      prefix_int = subnet
      |> IP.Subnet.prefix
      |> IP.to_integer

      bcast_int = subnet
      |> IP.Subnet.broadcast
      |> IP.to_integer

      range_first_int = min(prefix_int + range_first_delta, bcast_int)
      range_last_int = min(range_first_int + range_count, bcast_int)

      range_first = IP.from_integer(range_first_int, :v4)
      range_last = IP.from_integer(range_last_int, :v4)
      ex_range = IP.Range.new(range_first, range_last)

      pick = IP.random(subnet, [ex_range])

      assert pick in subnet
      refute pick in ex_range
    end
  end

end
