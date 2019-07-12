defmodule Dasie.LinkedList do
  @moduledoc """
  Linked list
  """

  defstruct data: nil,
            next: nil,
            empty: false

  @type t :: %__MODULE__{
          data: any,
          next: t | nil,
          empty: boolean
        }

  @doc "Create a new empty linked list"
  @spec new() :: __MODULE__.t()
  def new(), do: %__MODULE__{empty: true}

  @doc "Create a new linked list with some elements"
  @spec new(elements :: list(any)) :: __MODULE__.t()
  def new([element]) do
    new(element)
  end

  def new([h | tail]) do
    add(new(h), tail)
  end

  @spec new(elements :: any) :: __MODULE__.t()
  def new(data) do
    %__MODULE__{data: data}
  end

  @doc "Adds an element to the end of the list"
  @spec add(list :: __MODULE__.t(), elements :: list(any)) :: __MODULE__.t()
  def add(%__MODULE__{} = list, elements) when is_list(elements) do
    Enum.reduce(elements, list, fn element, acc ->
      add(acc, element)
    end)
  end

  @spec add(list :: __MODULE__.t(), data :: any) :: __MODULE__.t()
  def add(%__MODULE__{empty: true} = list, data) do
    %__MODULE__{list | data: data, empty: false}
  end

  def add(%__MODULE__{next: nil} = list, data) do
    %__MODULE__{list | next: new(data)}
  end

  def add(%__MODULE__{} = list, data) do
    %__MODULE__{list | next: add(list.next, data)}
  end

  @doc "Returns the first element in the list"
  @spec first(list :: __MODULE__.t()) :: any
  def first(%__MODULE__{data: data}), do: data

  def last(%__MODULE__{next: nil, data: data}), do: data

  def last(%__MODULE__{next: next}) do
    last(next)
  end

  @doc "Reverses the linked list"
  @spec reverse(list :: __MODULE__.t()) :: __MODULE__.t()
  def reverse(list) do
    list
    |> values()
    |> Enum.reverse()
    |> new()
  end

  @doc "Returns the items in the list"
  @spec values(list :: __MODULE__.t()) :: list(any)
  def values(%__MODULE__{next: nil, data: data}), do: [data]

  def values(%__MODULE__{next: next, data: data}) do
    [data | values(next)]
  end

  @doc "Deletes an element from the list"
  @spec delete(list :: __MODULE__.t(), element :: any) :: __MODULE__.t()
  def delete(%__MODULE__{next: nil, data: data}, element) when data == element do
    new()
  end

  def delete(%__MODULE__{next: next, data: data}, element) when data == element do
    next
  end

  def delete(%__MODULE__{next: next, data: data} = list, element) when data != element do
    %__MODULE__{list | next: delete(next, element)}
  end

  defimpl Collectable, for: Dasie.LinkedList do
    def into(original) do
      collector_fun = fn
        linked_list, {:cont, elem} -> Dasie.LinkedList.add(linked_list, elem)
        linked_list, :done -> linked_list
        _linked_list, :halt -> :ok
      end

      {original, collector_fun}
    end
  end
end
