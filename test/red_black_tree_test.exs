defmodule Dasie.RedBlackTreeTest do
  use ExUnit.Case

  alias Dasie.RedBlackTree

  describe "root" do
    test "is black" do
      rbt = RedBlackTree.new()
      assert rbt.color == :black
    end
  end

  describe "blacken/1" do
    test "turns a red node into a black one" do
      node = %RedBlackTree{RedBlackTree.new(3) | color: :red}
      assert RedBlackTree.blacken(node) == %RedBlackTree{node | color: :black}
    end

    test "does not change an already black node" do
      node = %RedBlackTree{RedBlackTree.new(3) | color: :black}
      assert RedBlackTree.blacken(node) == node
    end
  end

  describe "member?/2" do
    test "returns false if element does is not in the tree" do
      node = %RedBlackTree{RedBlackTree.new(3) | color: :red}
      root = %RedBlackTree{RedBlackTree.new(2) | right: node}

      refute RedBlackTree.member?(root, 4)
    end

    test "returns true if element is in the tree" do
      node = %RedBlackTree{RedBlackTree.new(3) | color: :red}
      root = %RedBlackTree{RedBlackTree.new(2) | right: node}

      assert RedBlackTree.member?(root, 3)
    end
  end

  describe "balance/1" do
    test "black(left: red(left: red)) -> red(left(black), right(black))" do
      x = %RedBlackTree{RedBlackTree.new(7) | color: :red}
      y = %RedBlackTree{RedBlackTree.new(8) | left: x, color: :red}
      z = %RedBlackTree{RedBlackTree.new(9) | left: y, color: :black}

      assert RedBlackTree.balance(z) == balanced_rbt()
    end

    test "black(left: red(right: red)) -> red(left(black), right(black))" do
      y = %RedBlackTree{RedBlackTree.new(8) | color: :red}
      x = %RedBlackTree{RedBlackTree.new(7) | right: y, color: :red}
      z = %RedBlackTree{RedBlackTree.new(9) | left: x, color: :black}

      assert RedBlackTree.balance(z) == balanced_rbt()
    end

    test "black(right: red(left: red)) -> red(left(black), right(black))" do
      y = %RedBlackTree{RedBlackTree.new(8) | color: :red}
      z = %RedBlackTree{RedBlackTree.new(9) | left: y, color: :red}
      x = %RedBlackTree{RedBlackTree.new(7) | right: z, color: :black}

      assert RedBlackTree.balance(x) == balanced_rbt()
    end

    test "black(right: red(right: red)) -> red(left(black), right(black))" do
      z = %RedBlackTree{RedBlackTree.new(9) | color: :red}
      y = %RedBlackTree{RedBlackTree.new(8) | right: z, color: :red}
      x = %RedBlackTree{RedBlackTree.new(7) | right: y, color: :black}

      assert RedBlackTree.balance(x) == balanced_rbt()
    end

    test "does not change already balanced tree" do
      assert RedBlackTree.balance(balanced_rbt()) == balanced_rbt()
    end

    test "ignores other case" do
      x = %RedBlackTree{RedBlackTree.new(7) | color: :red}
      z = %RedBlackTree{RedBlackTree.new(9) | color: :black, left: x}

      assert RedBlackTree.balance(z) == z
    end
  end

  describe "insert/2" do
    test "handles smaller element" do
      root = RedBlackTree.new(4)

      result = RedBlackTree.insert(root, 2)

      assert RedBlackTree.member?(result, 2)

      assert result == %RedBlackTree{
               root
               | left: %RedBlackTree{
                   color: :red,
                   data: 2,
                   left: nil,
                   right: nil
                 }
             }
    end

    test "handles larger element" do
      root = RedBlackTree.new(4)

      result = RedBlackTree.insert(root, 6)

      assert RedBlackTree.member?(result, 6)

      assert result == %RedBlackTree{
               root
               | right: %RedBlackTree{
                   color: :red,
                   data: 6,
                   left: nil,
                   right: nil
                 }
             }
    end

    test "handles equal element" do
      root = RedBlackTree.new(4)

      result = RedBlackTree.insert(root, 4)

      assert RedBlackTree.member?(result, 4)
      assert result == root
    end

    test "handles insertion deeply" do
      bx = %RedBlackTree{RedBlackTree.new(11) | color: :black}
      bz = %RedBlackTree{RedBlackTree.new(13) | color: :black}
      right_sub = %RedBlackTree{RedBlackTree.new(12) | color: :red, left: bx, right: bz}
      left_sub = balanced_rbt()
      tree = %RedBlackTree{RedBlackTree.new(10) | left: left_sub, right: right_sub}

      result = RedBlackTree.insert(tree, 8.5)

      assert RedBlackTree.member?(result, 8.5)

      assert result == %RedBlackTree{
               color: :black,
               data: 10,
               left: %RedBlackTree{
                 color: :red,
                 data: 8,
                 left: %RedBlackTree{
                   color: :black,
                   data: 7
                 },
                 right: %RedBlackTree{
                   color: :black,
                   data: 9,
                   left: %RedBlackTree{
                     color: :red,
                     data: 8.5
                   }
                 }
               },
               right: %RedBlackTree{
                 color: :red,
                 data: 12,
                 left: %RedBlackTree{
                   color: :black,
                   data: 11
                 },
                 right: %RedBlackTree{
                   color: :black,
                   data: 13
                 }
               }
             }
    end
  end

  defp balanced_rbt() do
    bx = %RedBlackTree{RedBlackTree.new(7) | color: :black}
    bz = %RedBlackTree{RedBlackTree.new(9) | color: :black}
    %RedBlackTree{RedBlackTree.new(8) | color: :red, left: bx, right: bz}
  end

  # TODO: Implement invariant checking methods!
end
