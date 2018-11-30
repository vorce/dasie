defmodule Dasie.CuckooFilterTest do
  use ExUnit.Case

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
  end
end
