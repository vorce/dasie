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
    test "returns false if element is not in the tree" do
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

      assert every_red_node_has_black_children?(result)
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

      assert every_red_node_has_black_children?(result)
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

      assert every_red_node_has_black_children?(result)
    end
  end

  describe "balance_left/1" do
    test "black(left: red) -> red(left: black)" do
      root = RedBlackTree.new(4)
      rbt = RedBlackTree.insert(root, 2)

      assert RedBlackTree.balance_left(rbt) == %RedBlackTree{
               color: :red,
               data: 4,
               left: %RedBlackTree{
                 color: :black,
                 data: 2
               }
             }
    end

    test "black(left: black, right: black) -> balanced: black(left: black, right: red)" do
      left = RedBlackTree.new(2)
      right = RedBlackTree.new(6)
      rbt = %{RedBlackTree.new(4) | left: left, right: right}

      assert RedBlackTree.balance_left(rbt) == %RedBlackTree{
               color: :black,
               data: 4,
               left: %RedBlackTree{
                 color: :black,
                 data: 2
               },
               right: %RedBlackTree{
                 color: :red,
                 data: 6
               }
             }
    end

    test "black(left: black, right: red) -> red(left: black, right: black)" do
      left = RedBlackTree.new(2)
      r_l = RedBlackTree.new(5)
      r_r = RedBlackTree.new(8)
      right = %{RedBlackTree.new(6) | color: :red, left: r_l, right: r_r}
      rbt = %{RedBlackTree.new(4) | left: left, right: right}

      assert RedBlackTree.balance_left(rbt) == %RedBlackTree{
               color: :red,
               data: 5,
               left: %RedBlackTree{
                 color: :black,
                 data: 4,
                 left: left
               },
               right: %RedBlackTree{
                 color: :black,
                 data: 6,
                 right: %RedBlackTree{color: :red, data: 8}
               }
             }
    end
  end

  describe "balance_right/1" do
    test "black(right: red) -> red(right: black)" do
      root = RedBlackTree.new(4)
      rbt = RedBlackTree.insert(root, 6)

      assert RedBlackTree.balance_right(rbt) == %RedBlackTree{
               color: :red,
               data: 4,
               right: %RedBlackTree{
                 color: :black,
                 data: 6
               }
             }
    end

    test "black(left: black, right: black) -> balanced: black(left: red, right: black)" do
      left = RedBlackTree.new(2)
      right = RedBlackTree.new(6)
      rbt = %{RedBlackTree.new(4) | left: left, right: right}

      assert RedBlackTree.balance_right(rbt) == %RedBlackTree{
               color: :black,
               data: 4,
               left: %RedBlackTree{
                 color: :red,
                 data: 2
               },
               right: %RedBlackTree{
                 color: :black,
                 data: 6
               }
             }
    end

    test "black(left: red, right: black) -> red(left: black, right: black)" do
      l_l = RedBlackTree.new(1)
      l_r = RedBlackTree.new(3)
      left = %{RedBlackTree.new(2) | color: :red, left: l_l, right: l_r}
      right = RedBlackTree.new(6)
      rbt = %{RedBlackTree.new(4) | left: left, right: right}

      assert RedBlackTree.balance_right(rbt) == %RedBlackTree{
               color: :red,
               data: 3,
               left: %RedBlackTree{
                 color: :black,
                 data: 2,
                 left: %RedBlackTree{color: :red, data: 1}
               },
               right: %RedBlackTree{
                 color: :black,
                 data: 4,
                 right: right
               }
             }
    end
  end

  describe "delete_left/2" do
    test "red root" do
      left = RedBlackTree.new(2)
      right = RedBlackTree.new(6)
      rbt = %{RedBlackTree.new(4) | color: :red, left: left, right: right}

      assert RedBlackTree.delete_left(2, rbt, &RedBlackTree.default_compare_function/2) ==
               %RedBlackTree{
                 color: :red,
                 data: 4,
                 right: %RedBlackTree{color: :black, data: 6}
               }
    end

    test "black root" do
      left = %{RedBlackTree.new(2) | color: :red}
      right = %{RedBlackTree.new(6) | color: :red}
      rbt = %{RedBlackTree.new(4) | left: left, right: right}

      assert RedBlackTree.delete_left(2, rbt, &RedBlackTree.default_compare_function/2) ==
               %RedBlackTree{
                 color: :black,
                 data: 4,
                 right: %RedBlackTree{
                   color: :red,
                   data: 6
                 }
               }
    end
  end

  describe "delete_right/2" do
    test "red root" do
      left = RedBlackTree.new(2)
      right = RedBlackTree.new(6)
      rbt = %RedBlackTree{RedBlackTree.new(4) | color: :red, left: left, right: right}

      assert RedBlackTree.delete_right(6, rbt, &RedBlackTree.default_compare_function/2) ==
               %RedBlackTree{
                 color: :red,
                 data: 4,
                 left: %RedBlackTree{color: :black, data: 2}
               }
    end

    test "black root" do
      left = %{RedBlackTree.new(2) | color: :red}
      right = %{RedBlackTree.new(6) | color: :red}
      rbt = %{RedBlackTree.new(4) | left: left, right: right}

      assert RedBlackTree.delete_right(6, rbt, &RedBlackTree.default_compare_function/2) ==
               %RedBlackTree{
                 color: :black,
                 data: 4,
                 left: %RedBlackTree{
                   color: :red,
                   data: 2
                 }
               }
    end
  end

  describe "fuse/2" do
    test "black red roots" do
      left = %RedBlackTree{
        RedBlackTree.new(2)
        | right: %RedBlackTree{RedBlackTree.new(3) | color: :red}
      }

      right = %{
        RedBlackTree.new(6)
        | color: :red,
          left: RedBlackTree.new(5),
          right: RedBlackTree.new(7)
      }

      assert RedBlackTree.fuse(left, right) == %RedBlackTree{
               color: :red,
               data: 6,
               left: %RedBlackTree{
                 color: :red,
                 data: 3,
                 left: %RedBlackTree{
                   color: :black,
                   data: 2
                 },
                 right: %RedBlackTree{
                   color: :black,
                   data: 5
                 }
               },
               right: %RedBlackTree{
                 color: :black,
                 data: 7
               }
             }
    end

    test "red black roots" do
      left = %RedBlackTree{
        RedBlackTree.new(2)
        | color: :red,
          left: RedBlackTree.new(1),
          right: RedBlackTree.new(3)
      }

      right = %RedBlackTree{
        RedBlackTree.new(6)
        | left: %RedBlackTree{RedBlackTree.new(5) | color: :red}
      }

      assert RedBlackTree.fuse(left, right) == %RedBlackTree{
               color: :red,
               data: 2,
               left: %RedBlackTree{
                 color: :black,
                 data: 1
               },
               right: %RedBlackTree{
                 color: :red,
                 data: 5,
                 left: %RedBlackTree{
                   color: :black,
                   data: 3
                 },
                 right: %RedBlackTree{
                   color: :black,
                   data: 6
                 }
               }
             }
    end

    test "black black roots" do
      left = %RedBlackTree{
        RedBlackTree.new(2)
        | right: %RedBlackTree{RedBlackTree.new(3) | color: :red}
      }

      right = %RedBlackTree{
        RedBlackTree.new(7)
        | left: RedBlackTree.new(6)
      }

      assert RedBlackTree.fuse(left, right) == %RedBlackTree{
               color: :red,
               data: 3,
               left: %RedBlackTree{
                 color: :black,
                 data: 2
               },
               right: %RedBlackTree{
                 color: :black,
                 data: 7,
                 left: %RedBlackTree{
                   color: :black,
                   data: 6
                 }
               }
             }
    end

    test "red red roots" do
      left = %RedBlackTree{
        RedBlackTree.new(2)
        | color: :red,
          right: RedBlackTree.new(3)
      }

      right = %RedBlackTree{
        RedBlackTree.new(7)
        | color: :red,
          left: %RedBlackTree{RedBlackTree.new(6) | color: :red}
      }

      assert RedBlackTree.fuse(left, right) == %RedBlackTree{
               color: :red,
               data: 6,
               left: %RedBlackTree{
                 color: :red,
                 data: 2,
                 right: %RedBlackTree{
                   color: :black,
                   data: 3
                 }
               },
               right: %RedBlackTree{
                 color: :red,
                 data: 7
               }
             }
    end
  end

  describe "delete/2" do
    test "remove from left" do
      root = RedBlackTree.new(4)
      rbt = RedBlackTree.insert(root, 2)
      assert RedBlackTree.delete(rbt, 2) == root
    end

    test "remove from right" do
      root = RedBlackTree.new(4)
      rbt = RedBlackTree.insert(root, 6)

      assert RedBlackTree.delete(rbt, 6) == root
    end
  end

  test "bigger example" do
    rbt =
      RedBlackTree.new(4)
      |> RedBlackTree.insert(6)
      |> RedBlackTree.insert(24)
      |> RedBlackTree.insert(150)
      |> RedBlackTree.insert(2)
      |> RedBlackTree.insert(13)
      |> RedBlackTree.insert(3)
      |> RedBlackTree.insert(1)
      |> RedBlackTree.insert(200)
      |> RedBlackTree.insert(99)
      |> RedBlackTree.insert(12)

    assert every_red_node_has_black_children?(rbt)
    assert all_paths_have_same_black_nodes?(rbt)

    rbt2 =
      rbt
      |> RedBlackTree.delete(13)

    assert every_red_node_has_black_children?(rbt2)
    assert all_paths_have_same_black_nodes?(rbt2)

    rbt3 =
      rbt2
      |> RedBlackTree.delete(150)
      |> RedBlackTree.delete(24)

    assert every_red_node_has_black_children?(rbt3)
    assert all_paths_have_same_black_nodes?(rbt3)
  end

  # TODO Write some property based tests!

  defp balanced_rbt() do
    bx = %RedBlackTree{RedBlackTree.new(7) | color: :black}
    bz = %RedBlackTree{RedBlackTree.new(9) | color: :black}
    %RedBlackTree{RedBlackTree.new(8) | color: :red, left: bx, right: bz}
  end

  def every_red_node_has_black_children?(%RedBlackTree{
        color: :red,
        right: %RedBlackTree{color: :red}
      }) do
    false
  end

  def every_red_node_has_black_children?(%RedBlackTree{
        color: :red,
        left: %RedBlackTree{color: :red}
      }) do
    false
  end

  def every_red_node_has_black_children?(%RedBlackTree{color: :black} = node) do
    every_red_node_has_black_children?(node.left) &&
      every_red_node_has_black_children?(node.right)
  end

  def every_red_node_has_black_children?(_) do
    true
  end

  def all_paths_have_same_black_nodes?(%RedBlackTree{} = tree) do
    counts =
      count_black_nodes_to_leaf(tree, 0)
      |> List.flatten()

    first = List.first(counts)
    all_equal? = Enum.all?(counts, fn count -> count == first end)

    unless all_equal?,
      do:
        IO.inspect(
          tree,
          label:
            "Tree violates invariant: Every path from the root to a leaf contains the same number of black nodes"
        )

    all_equal?
  end

  def count_black_nodes_to_leaf(%RedBlackTree{} = tree, acc) do
    counter =
      case tree.color do
        :black ->
          1

        :red ->
          0
      end

    [
      count_black_nodes_to_leaf(tree.left, acc + counter),
      count_black_nodes_to_leaf(tree.right, acc + counter)
    ]
  end

  def count_black_nodes_to_leaf(nil, acc) do
    acc
  end
end
