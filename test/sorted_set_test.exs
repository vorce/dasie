defmodule Dasie.SortedSetTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Dasie.SortedSet
  alias Dasie.RedBlackTree

  property "member? returns true after insert into empty set" do
    check all(
            key <-
              StreamData.one_of([
                StreamData.integer(),
                StreamData.binary(),
                StreamData.atom(:alphanumeric)
              ]),
            score <- StreamData.integer()
          ) do
      set = SortedSet.new(key, score)
      assert SortedSet.member?(set, key)
    end
  end

  property "range finds key after insert into empty set" do
    check all(
            key <-
              StreamData.one_of([
                StreamData.integer(),
                StreamData.binary(),
                StreamData.atom(:alphanumeric)
              ]),
            score <- StreamData.integer()
          ) do
      set = SortedSet.new(key, score)
      assert SortedSet.range(set, score..score) == [{key, score}]
    end
  end

  property "member? returns true after insert into non-empty set" do
    check all(
            key <-
              StreamData.one_of([
                StreamData.integer(),
                StreamData.binary(),
                StreamData.atom(:alphanumeric)
              ]),
            score <- StreamData.integer(),
            set <- sorted_set_generator()
          ) do
      set = SortedSet.insert(set, key, score)
      assert SortedSet.member?(set, key)
    end
  end

  property "range finds key after insert into non-empty set" do
    check all(
            key <-
              StreamData.one_of([
                StreamData.integer(),
                StreamData.binary(),
                StreamData.atom(:alphanumeric)
              ]),
            score <- StreamData.integer(),
            set <- sorted_set_generator()
          ) do
      set = SortedSet.insert(set, key, score)
      assert set |> SortedSet.range(score..score) |> Enum.member?({key, score})
    end
  end

  describe "new" do
    test "single element" do
      myscore = 12
      mykey = "mykey"

      assert SortedSet.new(mykey, myscore) == %SortedSet{
               keys: %{"mykey" => 12},
               scores: %RedBlackTree{
                 color: :black,
                 data: {12, "mykey"}
               }
             }
    end

    test "many elements" do
      assert SortedSet.new([{"key1", 10}, {"key2", 5}, {"key2", 4}]) == %SortedSet{
               keys: %{"key1" => 10, "key2" => 4},
               scores: %RedBlackTree{
                 color: :black,
                 data: {10, "key1"},
                 left: %RedBlackTree{color: :red, data: {4, "key2"}}
               }
             }
    end
  end

  describe "insert" do
    test "single element" do
      set =
        SortedSet.new("hello", 10)
        |> SortedSet.insert("hej", 100)

      assert set == %SortedSet{
               keys: %{"hej" => 100, "hello" => 10},
               scores: %RedBlackTree{
                 color: :black,
                 data: {10, "hello"},
                 right: %RedBlackTree{
                   color: :red,
                   data: {100, "hej"}
                 }
               }
             }
    end

    test "many elements" do
      set =
        SortedSet.new("hello", 10)
        |> SortedSet.insert([{"hi", 100}, {"hej", 100}, {"hey", 50}, {"hi", 50}])

      assert set == %SortedSet{
               keys: %{"hej" => 100, "hello" => 10, "hey" => 50, "hi" => 50},
               scores: %RedBlackTree{
                 color: :black,
                 data: {50, "hey"},
                 left: %RedBlackTree{
                   color: :black,
                   data: {10, "hello"}
                 },
                 right: %Dasie.RedBlackTree{
                   color: :black,
                   data: {100, "hej"},
                   left: %Dasie.RedBlackTree{color: :red, data: {50, "hi"}}
                 }
               }
             }
    end

    test "updates existing element" do
      assert SortedSet.new("hello", 10)
             |> SortedSet.insert([{"hello", 100}])
             |> SortedSet.to_list() == [{"hello", 100}]
    end
  end

  describe "to_list" do
    test "returns a list of key, score tuples" do
      assert SortedSet.new([{"key1", 10}, {"key2", 5}, {"key3", 100}])
             |> SortedSet.to_list() == [{"key1", 10}, {"key2", 5}, {"key3", 100}]
    end
  end

  describe "range" do
    test "returns elements with scores in range" do
      set = SortedSet.new([{"key1", 10}, {"key2", 5}, {"key3", 100}, {"key4", 25}])

      assert SortedSet.range(set, 10..30) == [{"key1", 10}, {"key4", 25}]
    end

    test "includes key with score equal to first and last" do
      key = <<17>>
      score = 1

      set =
        "otherkey"
        |> SortedSet.new(2)
        |> SortedSet.insert(key, score)

      assert set |> SortedSet.range(1..1) == [{key, score}]
    end
  end

  describe "delete" do
    test "removes key in set" do
      set =
        SortedSet.new([{"key1", 400}, {"key2", 401}, {"key3", 200}, {"key4", 402}])
        |> SortedSet.delete("key1")

      assert SortedSet.to_list(set) == [{"key2", 401}, {"key3", 200}, {"key4", 402}]
    end
  end

  describe "member?" do
    test "returns true if key exists" do
      set = SortedSet.new([{"key1", 400}, {"key2", 401}, {"key3", 200}, {"key4", 402}])
      assert SortedSet.member?(set, "key3")
    end

    test "returns false if key doesn't exists" do
      set = SortedSet.new([{"key1", 400}, {"key2", 401}, {"key3", 200}, {"key4", 402}])
      refute SortedSet.member?(set, "key5")
    end
  end

  describe "collectable into" do
    test "SortedSet" do
      list = [{"cake", 5}, {"cookie", 8}, {"donut", 9}, {"cool", 1}]
      assert Enum.into(list, SortedSet.new()) == SortedSet.new(list)
    end
  end

  def sorted_set_generator() do
    gen all(
          key_values <-
            StreamData.nonempty(
              StreamData.list_of(
                StreamData.tuple({
                  StreamData.one_of([StreamData.integer(), StreamData.atom(:alphanumeric), StreamData.binary()]),
                  StreamData.integer()
                })
              )
            )
        ) do
      SortedSet.new(key_values)
    end
  end
end
