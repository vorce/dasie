defmodule Dasie.RedBlackTree do
  @moduledoc """
  Invariant 1. Every red node have two black children.
  Invariant 2. Every path from the root to a leaf contains the same number of black nodes.
  Invariant 3. The root and leaves of the tree are black.

  References:

  - http://www.cs.ox.ac.uk/ralf.hinze/WG2.8/32/slides/red-black-pearl.pdf
  - https://functional.works-hub.com/learn/Persistent-Red-Black-Trees-in-Haskell
  """

  defstruct data: nil,
            left: nil,
            right: nil,
            color: :black

  @doc "Create a new red-black tree"
  def new(data \\ nil) do
    %__MODULE__{data: data}
  end

  @doc "Turns a node's color into :black"
  def blacken(%__MODULE__{color: :red} = node), do: %__MODULE__{node | color: :black}
  def blacken(%__MODULE__{color: :black} = node), do: node
  def blacken(nil), do: nil

  @doc "Checks if an element is in the tree or not"
  def member?(node, element, compare_fn \\ &default_compare_function/2)

  def member?(%__MODULE__{} = node, element, compare_fn) do
    case compare_fn.(element, node.data) do
      1 -> member?(node.right, element, compare_fn)
      0 -> true
      -1 -> member?(node.left, element, compare_fn)
    end
  end

  def member?(%__MODULE__{left: nil, right: nil}, _element, _compare_fn), do: false
  def member?(nil, _element, _compare_fn), do: false

  @doc "balance a sub-tree to keep invariant 1"
  # black(left: red(left: red)) -> red(left(black), right(black))
  def balance(
        %__MODULE__{
          color: :black,
          left: %__MODULE__{color: :red, left: %__MODULE__{color: :red} = x} = y
        } = z
      ) do
    %__MODULE__{y | left: blacken(x), right: blacken(%__MODULE__{z | left: y.right})}
  end

  # black(left: red(right: red)) -> red(left(black), right(black))
  def balance(
        %__MODULE__{
          color: :black,
          left: %__MODULE__{color: :red, right: %__MODULE__{color: :red} = y} = x
        } = z
      ) do
    %__MODULE__{
      y
      | left: blacken(%__MODULE__{x | right: y.left}),
        right: blacken(%__MODULE__{z | left: y.right})
    }
  end

  # black(right: red(left: red)) -> red(left(black), right(black))
  def balance(
        %__MODULE__{
          color: :black,
          right: %__MODULE__{color: :red, left: %__MODULE__{color: :red} = y} = z
        } = x
      ) do
    %__MODULE__{
      y
      | left: blacken(%__MODULE__{x | right: y.left}),
        right: blacken(%__MODULE__{z | left: y.right})
    }
  end

  # black(right: red(right: red)) -> red(left(black), right(black))
  def balance(
        %__MODULE__{
          color: :black,
          right: %__MODULE__{color: :red, right: %__MODULE__{color: :red} = z} = y
        } = x
      ) do
    %__MODULE__{
      y
      | left: blacken(%__MODULE__{x | right: y.left}),
        right: blacken(z)
    }
  end

  def balance(node), do: node

  @doc "Insert an element into the tree"
  def insert(tree, element, compare_fn \\ &default_compare_function/2) do
    element |> do_insert(tree, compare_fn) |> blacken()
  end

  defp do_insert(element, nil, _compare_fn) do
    %__MODULE__{new(element) | color: :red}
  end

  defp do_insert(element, %__MODULE__{data: data} = node, compare_fn) do
    case compare_fn.(element, data) do
      1 ->
        balance(%__MODULE__{node | right: do_insert(element, node.right, compare_fn)})

      0 ->
        %__MODULE__{node | data: element}

      -1 ->
        balance(%__MODULE__{node | left: do_insert(element, node.left, compare_fn)})
    end
  end

  def default_compare_function(data1, data2) do
    cond do
      data1 > data2 -> 1
      data1 == data2 -> 0
      data1 < data2 -> -1
    end
  end

  @doc "Deletes an element in the tree"
  def delete(tree, element, compare_fn \\ &default_compare_function/2) do
    element |> do_delete(tree, compare_fn) |> blacken()
  end

  defp do_delete(element, %__MODULE__{data: data} = node, compare_fn) do
    case compare_fn.(element, data) do
      1 ->
        delete_right(element, node, compare_fn)

      0 ->
        fuse(node.left, node.right)

      -1 ->
        delete_left(element, node, compare_fn)
    end
  end

  def delete_left(element, %__MODULE__{color: :red} = node, compare_fn) do
    %__MODULE__{node | left: do_delete(element, node.left, compare_fn)}
  end

  def delete_left(element, %__MODULE__{color: :black} = node, compare_fn) do
    balance_left(%__MODULE__{node | left: do_delete(element, node.left, compare_fn)})
  end

  def delete_right(element, %__MODULE__{color: :red} = node, compare_fn) do
    %__MODULE__{node | right: do_delete(element, node.right, compare_fn)}
  end

  def delete_right(element, %__MODULE__{color: :black} = node, compare_fn) do
    balance_right(%__MODULE__{node | right: do_delete(element, node.right, compare_fn)})
  end

  def fuse(nil, right) do
    right
  end

  def fuse(left, nil) do
    left
  end

  def fuse(%__MODULE__{color: :black} = left, %__MODULE__{color: :red} = right) do
    %__MODULE__{right | left: fuse(left, right.left)}
  end

  def fuse(%__MODULE__{color: :red} = left, %__MODULE__{color: :black} = right) do
    %__MODULE__{left | right: fuse(left.right, right)}
  end

  def fuse(
        %__MODULE__{color: :red} = left,
        %__MODULE__{color: :red} = right
      ) do
    fused = fuse(left.right, right.left)

    case fused do
      %__MODULE__{color: :red} = red ->
        %__MODULE__{
          red
          | left: %__MODULE__{left | right: red.left},
            right: %__MODULE__{right | left: red.right}
        }

      %__MODULE__{color: :black} = black ->
        %__MODULE__{left | right: %__MODULE__{right | left: black}}
    end
  end

  # This is probably the case i'm the least confident is doing the right thing
  # at all times... maybe we can even get rid of it?
  def fuse(
        %__MODULE__{color: :black, right: nil} = left,
        %__MODULE__{color: :black, left: nil} = right
      ) do
    balance_right(%__MODULE__{right | left: left})
  end

  def fuse(
        %__MODULE__{color: :black} = left,
        %__MODULE__{color: :black} = right
      ) do
    fused = fuse(left.right, right.left)

    case fused do
      %__MODULE__{color: :red} = red ->
        %__MODULE__{
          red
          | left: %__MODULE__{left | right: red.left},
            right: %__MODULE__{right | left: red.right}
        }

      %__MODULE__{color: :black} = black ->
        balance_left(%__MODULE__{left | right: %__MODULE__{right | left: black}})
    end
  end

  def balance_left(%__MODULE__{color: :black, left: %__MODULE__{color: :red} = x} = y) do
    %__MODULE__{y | color: :red, left: %__MODULE__{x | color: :black}}
  end

  def balance_left(
        %__MODULE__{
          color: :black,
          right: %__MODULE__{color: :black} = z
        } = y
      ) do
    balance(%__MODULE__{y | right: %__MODULE__{z | color: :red}})
  end

  def balance_left(
        %__MODULE__{
          color: :black,
          right:
            %__MODULE__{
              color: :red,
              left: %__MODULE__{color: :black} = u,
              right: %__MODULE__{color: :black}
            } = z
        } = y
      ) do
    %__MODULE__{
      u
      | color: :red,
        left: %__MODULE__{y | right: u.left},
        right:
          balance(%__MODULE__{
            z
            | color: :black,
              left: u.right,
              right: %__MODULE__{z.right | color: :red}
          })
    }
  end

  def balance_left(node), do: node

  def balance_right(%__MODULE__{color: :black, right: %__MODULE__{color: :red} = x} = y) do
    %__MODULE__{y | color: :red, right: %__MODULE__{x | color: :black}}
  end

  def balance_right(
        %__MODULE__{
          color: :black,
          left: %__MODULE__{color: :black} = z
        } = y
      ) do
    balance(%__MODULE__{y | left: %__MODULE__{z | color: :red}})
  end

  def balance_right(
        %__MODULE__{
          color: :black,
          left:
            %__MODULE__{
              color: :red,
              left: %__MODULE__{color: :black},
              right: %__MODULE__{color: :black} = u
            } = z
        } = y
      ) do
    %__MODULE__{
      u
      | color: :red,
        left:
          balance(%__MODULE__{
            z
            | color: :black,
              left: %__MODULE__{z.left | color: :red},
              right: u.left
          }),
        right: %__MODULE__{y | left: u.right}
    }
  end

  def balance_right(node), do: node
end
