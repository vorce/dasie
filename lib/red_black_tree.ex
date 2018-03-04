defmodule Dasie.RedBlackTree do
  @moduledoc """
  Invariant 1. Every red node have two black children.
  Invariant 2. Every path from the root to a leaf contains the same number of black nodes.

  Delete is still not implemented
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

  @doc "Not implemented yet"
  def delete(_tree, _element), do: raise("Not implemented")
end
