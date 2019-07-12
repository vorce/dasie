defmodule Dasie.Trie do
  @moduledoc """
  Trie / prefix tree.
  https://en.wikipedia.org/wiki/Trie
  """

  defstruct children: [],
            data: nil,
            terminates?: false,
            count: 1

  @type t :: %__MODULE__{
    children: list(t),
    data: any,
    terminates?: boolean,
    count: integer
  }

  @doc "Creates a new trie"
  @spec new() :: __MODULE__.t()
  def new() do
    %__MODULE__{}
  end

  @doc "Insert a word into the trie"
  @spec insert(trie :: __MODULE__.t(), word :: binary | list(binary)) :: __MODULE__.t()
  def insert(%__MODULE__{} = trie, word) when is_binary(word) do
    insert(trie, String.codepoints(word))
  end

  def insert(%__MODULE__{} = trie, []), do: trie

  def insert(%__MODULE__{} = trie, [last_letter]) do
    case child(trie, last_letter) do
      nil ->
        node = %__MODULE__{data: last_letter, terminates?: true}
        %__MODULE__{trie | children: [node | trie.children]}

      _node ->
        %__MODULE__{trie | terminates?: true, count: trie.count + 1}
    end
  end

  def insert(%__MODULE__{} = trie, [letter | rest]) do
    case child(trie, letter) do
      nil ->
        node = %__MODULE__{data: letter}
        child = insert(node, rest)
        %__MODULE__{trie | children: [child | trie.children]}

      node ->
        child = insert(node, rest)
        new_children = Enum.reject(trie.children, fn c -> c.data == node.data end)
        %__MODULE__{trie | children: [%__MODULE__{child | count: child.count + 1} | new_children]}
    end
  end

  @doc """
  Insert many words into the trie
  """
  @spec insert_all(trie :: __MODULE__.t(), words :: list(binary)) :: __MODULE__.t()
  def insert_all(%__MODULE__{} = trie, words) when is_list(words) do
    Enum.reduce(words, trie, fn word, acc ->
      insert(acc, word)
    end)
  end

  @doc "Returns all suffixes in the trie that matches the prefix"
  @spec valid_words(trie :: __MODULE__.t(), prefix :: binary) :: list(binary)
  def valid_words(%__MODULE__{} = trie, prefix) when is_binary(prefix) do
    valid_words(trie, String.codepoints(prefix), [])
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

  def valid_words(%__MODULE__{} = trie, [letter | rest], acc) do
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
      Enum.join([child.data | all_suffixes(child.children)])
    end)
  end

  @doc "Returns true if the word is in the trie, false if not"
  @spec member?(trie :: __MODULE__.t(), word :: binary | list(binary)) :: boolean
  def member?(%__MODULE__{} = trie, word) when is_binary(word) do
    member?(trie, String.codepoints(word))
  end

  def member?(%__MODULE__{} = _trie, []), do: true

  def member?(%__MODULE__{} = trie, [letter | rest]) do
    case child(trie, letter) do
      nil ->
        false

      node ->
        member?(node, rest)
    end
  end

  @doc """
  Return a child of the node with the specified letter.
  Returns nil if there is no child that matches.
  """
  @spec child(node :: __MODULE__.t(), letter :: any) :: __MODULE__.t() | nil
  def child(node, letter) do
    Enum.find(node.children, fn child ->
      child.data == letter
    end)
  end

  @doc "Remove a word from the trie"
  @spec delete(node :: __MODULE__.t(), word :: binary | list(binary)) :: __MODULE__.t()
  def delete(%__MODULE__{} = trie, word) when is_binary(word) do
    if member?(trie, word) do
      delete(trie, String.codepoints(word))
    else
      trie
    end
  end

  def delete(%__MODULE__{} = trie, []), do: trie

  def delete(%__MODULE__{} = trie, [letter | rest]) do
    case child(trie, letter) do
      nil ->
        trie

      %__MODULE__{count: 1} = node ->
        %__MODULE__{trie | children: delete_node(trie.children, node)}

      %__MODULE__{} = node ->
        child = delete(node, rest)
        new_children = Enum.reject(trie.children, fn c -> c.data == node.data end)
        %__MODULE__{trie | children: [%__MODULE__{child | count: child.count - 1} | new_children]}
    end
  end

  defp delete_node(children, node) do
    Enum.reject(children, fn child -> child == node end)
  end

  defimpl Collectable, for: Dasie.Trie do
    def into(original) do
      collector_fun = fn
        trie, {:cont, elem} -> Dasie.Trie.insert(trie, elem)
        trie, :done -> trie
        _trie, :halt -> :ok
      end

      {original, collector_fun}
    end
  end
end
