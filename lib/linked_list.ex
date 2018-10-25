defmodule Dasie.LinkedList do
  @moduledoc """
  Linked list
  """

  defstruct data: nil,
            next: nil

  @doc "Create a new linked list"
  def new(data \\ nil)

  def new([element]) do
    new(element)
  end

  def new([h | tail]) do
    add(new(h), tail)
  end

  def new(data) do
    %__MODULE__{data: data}
  end

  @doc "Adds an element to the end of the list"
  def add(%__MODULE__{} = list, elements) when is_list(elements) do
    Enum.reduce(elements, list, fn element, acc ->
      add(acc, element)
    end)
  end

  def add(%__MODULE__{next: nil} = list, data) do
    %__MODULE__{list | next: new(data)}
  end

  def add(%__MODULE__{} = list, data) do
    %__MODULE__{list | next: add(list.next, data)}
  end

  @doc "Returns the first element in the list"
  def first(%__MODULE__{data: data}), do: data

  def last(%__MODULE__{next: nil, data: data}), do: data

  def last(%__MODULE__{next: next}) do
    last(next)
  end

  @doc "Reverses the linked list"
  def reverse(list) do
    list
    |> values()
    |> Enum.reverse()
    |> new()
  end

  @doc "Returns the items in the list"
  def values(%__MODULE__{next: nil, data: data}), do: [data]

  def values(%__MODULE__{next: next, data: data}) do
    [data] ++ values(next)
  end

  @doc "Deletes an element from the list"
  def delete(%__MODULE__{next: nil, data: data}, element) when data == element do
    new()
  end

  def delete(%__MODULE__{next: next, data: data}, element) when data == element do
    next
  end

  def delete(%__MODULE__{next: next, data: data} = list, element) when data != element do
    %__MODULE__{list | next: delete(next, element)}
  end
end
