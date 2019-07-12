defmodule Dasie.BSTTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Dasie.BST

  describe "new/0" do
    test "return empty tree" do
      assert BST.new() == %BST{}
    end

    test "return root tree" do
      assert BST.new(0) == %BST{data: 0}
    end

    test "return tree with many elements" do
      assert BST.new([8, 3, 10, 1, 6, 14, 4, 7, 13]) ==
               %BST{
                 data: 8,
                 left: %BST{
                   data: 3,
                   left: %BST{data: 1, left: nil, right: nil},
                   right: %BST{
                     data: 6,
                     left: %BST{data: 4, left: nil, right: nil},
                     right: %BST{data: 7, left: nil, right: nil}
                   }
                 },
                 right: %BST{
                   data: 10,
                   left: nil,
                   right: %BST{data: 14, left: %BST{data: 13, left: nil, right: nil}, right: nil}
                 }
               }
    end
  end

  describe "insert/2" do
    test "add to empty tree" do
      tree = BST.new()
      assert BST.insert(tree, "root") == %BST{left: nil, right: nil, data: "root"}
    end

    test "add to left side of root tree" do
      tree = BST.new(100)
      assert BST.insert(tree, 50) == %BST{right: nil, data: 100, left: %BST{data: 50, left: nil, right: nil}}
    end

    test "add to left side of tree" do
      tree = BST.insert(BST.new(100), 50)
      assert BST.insert(tree, 25) == %BST{right: nil, data: 100, left: %BST{data: 50, left: %BST{data: 25}, right: nil}}
    end

    test "add to right side of root tree" do
      tree = BST.new(100)
      assert BST.insert(tree, 200) == %BST{left: nil, data: 100, right: %BST{data: 200, left: nil, right: nil}}
    end

    test "add to right side of tree" do
      tree = BST.insert(BST.new(100), 200)

      assert BST.insert(tree, 400) == %BST{
               left: nil,
               data: 100,
               right: %BST{data: 200, left: nil, right: %BST{data: 400, left: nil, right: nil}}
             }
    end

    test "insert same value as root" do
      root_value = -21466
      original_tree = BST.new(root_value)

      assert BST.insert(original_tree, root_value) == original_tree
    end

    property "every node in the right subtree is larger than the current node and every node on the left subtree is smaller than the current node" do
      check all tree <- bst_generator() do
        assert valid_bst?(tree)
      end
    end
  end

  describe "find/2" do
    test "finds existing element" do
      assert BST.find(BST.new([8, 3, 10, 1, 6, 14, 4, 7, 13]), 10) ==
               %BST{data: 10, left: nil, right: %BST{data: 14, left: %BST{data: 13, left: nil, right: nil}, right: nil}}
    end

    test "return nil if no such element" do
      assert BST.find(BST.new([8, 3, 10, 1, 6, 14, 4, 7, 13]), 12) == nil
    end
  end

  describe "delete/2" do
    test "removes element" do
      assert BST.delete(BST.new([8, 3, 10, 1, 6, 14, 4, 7, 13]), 6) ==
               %BST{
                 data: 8,
                 left: %BST{
                   data: 3,
                   left: %BST{data: 1, left: nil, right: nil},
                   right: %BST{data: 7, left: %BST{data: 4, left: nil, right: nil}, right: nil}
                 },
                 right: %BST{
                   data: 10,
                   left: nil,
                   right: %BST{data: 14, left: %BST{data: 13, left: nil, right: nil}, right: nil}
                 }
               }
    end
  end

  describe "collectable into" do
    test "BST" do
      list = [1, 2, 3]
      assert Enum.into(list, BST.new()) == BST.new(list)
    end
  end

  @min_value -1_000_000
  @max_value 1_000_000
  defp bst_generator() do
    gen all values <-
              StreamData.nonempty(StreamData.list_of(StreamData.integer(@min_value..@max_value), min_length: 100)) do
      [head | rest] = values

      Enum.reduce(rest, BST.new(head), fn value, acc ->
        BST.insert(acc, value)
      end)
    end
  end

  # Translated staright from https://en.wikipedia.org/wiki/Binary_search_tree#Verification
  defp valid_bst?(tree, min \\ @min_value, max \\ @max_value)
  defp valid_bst?(nil, _, _), do: true
  defp valid_bst?(%BST{data: data}, min, _max) when data < min, do: false
  defp valid_bst?(%BST{data: data}, _min, max) when data > max, do: false

  defp valid_bst?(%BST{left: left, right: right} = node, min, max) do
    valid_bst?(left, min, node.data - 1) && valid_bst?(right, node.data + 1, max)
  end
end
