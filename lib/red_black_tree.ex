defmodule Dasie.RedBlackTree do
  @moduledoc """
  Invariant 1. Every red node have two black children.
  Invariant 2. Every path from the root to a leaf contains the same number of black nodes.
  Invariant 3. The root and leaves of the tree are black.

  Reference implementation: https://functional.works-hub.com/learn/Persistent-Red-Black-Trees-in-Haskell
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

  @doc "Checks if an element is in the tree or not"
  def member?(%__MODULE__{data: data}, element) when data == element, do: true
  def member?(%__MODULE__{left: nil, right: nil}, _element), do: false

  def member?(%__MODULE__{right: right, data: data}, element) when element > data,
    do: member?(right, element)

  def member?(%__MODULE__{left: left, data: data}, element) when element < data,
    do: member?(left, element)

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
  def insert(tree, element) do
    element |> do_insert(tree) |> blacken()
  end

  defp do_insert(element, nil) do
    %__MODULE__{new(element) | color: :red}
  end

  defp do_insert(element, %__MODULE__{data: data} = node) when element < data do
    balance(%__MODULE__{node | left: do_insert(element, node.left)})
  end

  defp do_insert(element, %__MODULE__{data: data} = node) when element > data do
    balance(%__MODULE__{node | right: do_insert(element, node.right)})
  end

  defp do_insert(element, %__MODULE__{data: data} = node) when element == data do
    node
  end

  @doc "Deletes an element in the tree"
  def delete(tree, element) do
    element |> do_delete(tree) |> blacken()
  end

  defp do_delete(element, %__MODULE__{data: data} = node) when element < data do
    delete_left(element, node)
  end

  defp do_delete(element, %__MODULE__{data: data} = node) when element > data do
    delete_right(element, node)
  end

  defp do_delete(element, %__MODULE__{data: data} = node) when element == data do
    fuse(node.left, node.right)
  end

  def delete_left(element, %__MODULE__{color: :red} = node) do
    %__MODULE__{node | left: do_delete(element, node.left)}
  end

  def delete_left(element, %__MODULE__{color: :black} = node) do
    balance_left(%__MODULE__{node | left: do_delete(element, node.left)})
  end

  def delete_right(element, %__MODULE__{color: :red} = node) do
    %__MODULE__{node | right: do_delete(element, node.right)}
  end

  def delete_right(element, %__MODULE__{color: :black} = node) do
    balance_right(%__MODULE__{node | right: do_delete(element, node.right)})
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
