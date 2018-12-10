defmodule Dasie.CuckooFilterTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Dasie.CuckooFilter

  describe "new/1" do
    test "creates a new default struct" do
      assert %CuckooFilter{} = CuckooFilter.new()
    end

    test "creates a new struct with specified max_keys" do
      max_keys = 100
      assert %CuckooFilter{max_keys: max_keys} = CuckooFilter.new(max_keys: max_keys)
    end
  end

  describe "insert/2" do
    test "can insert single entry" do
      result = CuckooFilter.insert(CuckooFilter.new(), "hello")
      assert Map.size(result.buckets) == 1

      bucket = result.buckets |> Map.values() |> List.first()
      assert MapSet.size(bucket.entries) == 1
    end

    test "returns error tuple when filter is full" do
      cuckoo = CuckooFilter.new(max_keys: 1, bucket_size: 1)

      result =
        cuckoo
        |> CuckooFilter.insert(1)

      assert %CuckooFilter{} = result

      result = CuckooFilter.insert(result, 2)

      assert result == {:error, :full}
    end

    test "will relocate to make space" do
      cuckoo = CuckooFilter.new(max_keys: 4, bucket_size: 1)

      result =
        cuckoo
        |> CuckooFilter.insert(1)
        |> CuckooFilter.insert(2)
        |> CuckooFilter.insert(3)
        |> CuckooFilter.insert(4)

      assert result == :ok
    end
  end

  describe "member?/2" do
    property "returns true if the item was inserted" do
      check all item <- StreamData.binary() do
        cuckoo =
          CuckooFilter.new()
          |> CuckooFilter.insert(item)

        assert CuckooFilter.member?(cuckoo, item)
      end
    end

    test "returns false if the item was not inserted" do
      check all item <- StreamData.binary() do
        refute CuckooFilter.new()
               |> CuckooFilter.insert(item)
               |> CuckooFilter.member?("something highly improbable to be generated here :)")
      end
    end
  end

  describe "delete/2" do
    test "removes item" do
      item = "first item"
      keeper = "keeper item"

      cuckoo =
        CuckooFilter.new()
        |> CuckooFilter.insert(item)
        |> CuckooFilter.insert(keeper)
        |> CuckooFilter.delete(item)

      refute CuckooFilter.member?(cuckoo, item)
    end

    # property "removes item" do
    #   check all item <- StreamData.tuple() StreamData.binary(),
    #             keeper <- StreamData.binary() do
    #     cuckoo =
    #       CuckooFilter.new()
    #       |> CuckooFilter.insert(item)
    #       |> CuckooFilter.insert(keeper)
    #       |> CuckooFilter.delete(item)
    #
    #     refute CuckooFilter.member?(cuckoo, item)
    #   end
    # end
  end
end
