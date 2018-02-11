defmodule Dasie.Trie do
  @moduledoc """
  Trie / prefix tree.

  This is still a bit unfinished.
  """
  defstruct children: [],
            data: nil,
            terminates?: false

  def new() do
    %__MODULE__{}
  end

  def insert(%__MODULE__{} = trie, word) when is_binary(word) do
    insert(trie, String.graphemes(word))
  end

  def insert(%__MODULE__{} = trie, []), do: trie

  def insert(%__MODULE__{} = trie, [last_letter]) do
    case child(trie, last_letter) do
      nil ->
        node = %__MODULE__{data: last_letter, terminates?: true}
        %__MODULE__{trie | children: [node|trie.children]}
      _node ->
        %__MODULE__{trie | terminates?: true}
    end
  end
  def insert(%__MODULE__{} = trie, [letter|rest]) do
    case child(trie, letter) do
      nil ->
        node = %__MODULE__{data: letter}
        child = insert(node, rest)
        %__MODULE__{trie | children: [child|trie.children]}
      node ->
        child = insert(node, rest)
        new_children = Enum.reject(trie.children, fn c -> c.data == node.data end)
        %__MODULE__{trie | children: [child|new_children]}
    end
  end

  def valid_words(%__MODULE__{} = trie, prefix) when is_binary(prefix) do
    valid_words(trie, String.graphemes(prefix), [])
  end

  def valid_words(%__MODULE__{}, [], acc) do
    acc
  end
  def valid_words(%__MODULE__{} = trie, [last_letter], acc) do
    case child(trie, last_letter) do
      nil ->
        acc
      node ->
        all_suffixes(node.children)
    end
  end
  def valid_words(%__MODULE__{} = trie, [letter|rest], acc) do
    case child(trie, letter) do
      nil ->
        acc
      node ->
        valid_words(node, rest, acc)
    end
  end

  def all_suffixes([]), do: []
  def all_suffixes(children) do
    children
    |> Enum.map(fn child ->
      Enum.join([child.data|all_suffixes(child.children)])
    end)
  end

  def child(node, letter) do
    Enum.find(node.children, fn child ->
      child.data == letter
    end)
  end
end
