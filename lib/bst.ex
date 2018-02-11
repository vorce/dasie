defmodule Dasie.BST do
  @moduledoc """
  Binary Search Tree
  """

  defstruct data: nil,
            left: nil,
            right: nil

  def new(data \\ nil)
  def new([h|tail]) do
    Enum.reduce(tail, new(h), fn elem, acc ->
      insert(acc, elem)
    end)
  end
  def new(data) do
    %__MODULE__{data: data}
  end

  def insert(%__MODULE__{data: nil, left: nil, right: nil} = tree, data) do
    %__MODULE__{data: data}
  end
  def insert(%__MODULE__{data: data, left: nil} = tree, new_data) when new_data < data do
    %__MODULE__{tree | left: new(new_data)}
  end
  def insert(%__MODULE__{data: data, left: left} = tree, new_data) when new_data < data do
    %__MODULE__{tree | left: insert(left, new_data)}
  end
  def insert(%__MODULE__{data: data, right: nil} = tree, new_data) when new_data > data do
    %__MODULE__{tree | right: new(new_data)}
  end
  def insert(%__MODULE__{data: data, right: right} = tree, new_data) when new_data > data do
    %__MODULE__{tree | right: insert(right, new_data)}
  end

  def find(%__MODULE__{data: data, left: nil, right: nil}, element) when data != element, do: nil
  def find(%__MODULE__{data: data} = tree, element) when data == element, do: tree
  def find(%__MODULE__{data: data, left: left}, element) when element < data do
    find(left, element)
  end
  def find(%__MODULE__{data: data, right: right}, element) when element > data do
    find(right, element)
  end

  def delete(%__MODULE__{data: data, left: nil, right: nil}, element) when data == element do
    nil
  end
  def delete(%__MODULE__{data: data, left: left, right: nil}, element) when data == element do
    left
  end
  def delete(%__MODULE__{data: data, left: nil, right: right}, element) when data == element do
    right
  end
  def delete(%__MODULE__{data: data, left: left, right: right} = tree, element) when data == element do
    successor = smallest(right)
    %__MODULE__{tree | data: successor.data, right: delete(right, successor.data)}
  end
  def delete(%__MODULE__{data: data, left: left} = tree, element) when element < data do
    %__MODULE__{tree | left: delete(left, element)}
  end
  def delete(%__MODULE__{data: data, right: right} = tree, element) when element > data do
    %__MODULE__{tree | right: delete(right, element)}
  end

  defp smallest(%__MODULE__{data: data, left: nil} = tree), do: tree
  defp smallest(%__MODULE__{left: left}), do: smallest(left)
end
