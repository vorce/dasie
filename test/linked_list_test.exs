defmodule Dasie.LinkedListTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Dasie.LinkedList

  describe "new/0" do
    test "returns an empty linked list" do
      assert LinkedList.new() == %LinkedList{empty: true}
    end
  end

  describe "new/1" do
    test "returns a linked list with a single element" do
      data = "hello"
      assert LinkedList.new(data) == %LinkedList{data: data}
    end

    test "returns a linked list with a collection of elements" do
      elements = ["one", "two", "three"]

      assert LinkedList.new(elements) == %LinkedList{
               data: "one",
               next: %LinkedList{data: "two", next: %LinkedList{data: "three", next: nil}}
             }
    end
  end

  describe "add/2" do
    test "appends to the end of a one element list" do
      list = LinkedList.new("first")
      assert LinkedList.add(list, "second") == %LinkedList{data: "first", next: %LinkedList{data: "second", next: nil}}
    end

    test "appends to the end of a two element list" do
      list = LinkedList.new(["first", "second"])

      assert LinkedList.add(list, "third") == %LinkedList{
               data: "first",
               next: %LinkedList{data: "second", next: %LinkedList{data: "third", next: nil}}
             }
    end
  end

  describe "first/1" do
    test "returns the first element of the list" do
      list = LinkedList.new(["first", "second", "third"])
      assert LinkedList.first(list) == "first"
    end
  end

  describe "last/1" do
    test "returns last element of list" do
      list = LinkedList.new(["first", "second", "last"])
      assert LinkedList.last(list) == "last"
    end
  end

  describe "reverse/1" do
    test "returns the reversed list" do
      list = LinkedList.new(["first", "second", "third", "fourth"])

      assert LinkedList.reverse(list) == %LinkedList{
               data: "fourth",
               next: %LinkedList{
                 data: "third",
                 next: %LinkedList{data: "second", next: %LinkedList{data: "first", next: nil}}
               }
             }
    end

    property "reverse twice is the same as the original" do
      check all(items <- StreamData.list_of(StreamData.binary())) do
        list = LinkedList.new(items)
        assert list |> LinkedList.reverse() |> LinkedList.reverse() == list
      end
    end
  end

  describe "delete/2" do
    test "removes an element" do
      list = LinkedList.new(["first", "second", "third"])

      assert LinkedList.delete(list, "second") == %LinkedList{
               data: "first",
               next: %LinkedList{data: "third", next: nil}
             }
    end

    property "a deleted element is no longer present" do
      check all(items <- StreamData.nonempty(StreamData.uniq_list_of(StreamData.integer()))) do
        delete_element = Enum.random(items)

        list =
          items
          |> LinkedList.new()
          |> LinkedList.delete(delete_element)

        refute list |> LinkedList.values() |> Enum.member?(delete_element)
      end
    end
  end

  describe "collectable into" do
    test "LinkedList" do
      list = [1, 2, 3]
      assert Enum.into(list, LinkedList.new()) == LinkedList.new(list)
    end
  end
end
