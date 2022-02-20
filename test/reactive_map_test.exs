defmodule Dasie.ReactiveMapTest do
  use ExUnit.Case

  alias Dasie.ReactiveMap

  describe "put_ref/3" do
    test "identity" do
      map =
        ReactiveMap.new()
        |> ReactiveMap.put(:a, 1)
        |> ReactiveMap.put_ref(:b, :a)

      assert ReactiveMap.get(map, :b) == ReactiveMap.get(map, :a)
    end

    test "with read function" do
      map =
        ReactiveMap.new()
        |> ReactiveMap.put(:a, 1)
        |> ReactiveMap.put_ref(:b, :a, fn a -> a + 1 end)

      assert ReactiveMap.get(map, :b) == ReactiveMap.get(map, :a) + 1
    end

    test "invalid reference" do
      map =
        ReactiveMap.new()
        |> ReactiveMap.put_ref(:b, :a, fn a -> a + 1 end)

      assert ReactiveMap.get(map, :b, :default) == :default
    end

    test "consistency" do
      map =
        ReactiveMap.new()
        |> ReactiveMap.put(:a, 1)
        |> ReactiveMap.put_ref(:b, :a, fn a -> a + 1 end)
        |> ReactiveMap.put_ref(:c, :b, fn b -> b * 2 end)

      assert ReactiveMap.get(map, :c) == (1 + 1) * 2

      map = ReactiveMap.put(map, :a, 3)
      assert ReactiveMap.get(map, :c) == (3 + 1) * 2
    end
  end

  describe "get" do
    test "circular reference raises error" do
      map =
        ReactiveMap.new()
        |> ReactiveMap.put_ref(:b, :a)
        |> ReactiveMap.put_ref(:a, :b)

      assert_raise ErlangError, fn ->
        ReactiveMap.get(map, :a)
      end
    end
  end
end
