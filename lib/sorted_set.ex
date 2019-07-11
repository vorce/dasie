defmodule Dasie.SortedSet do
  @moduledoc """
  A sorted set is a non-repeating collection of keys. Every key
  is also associated with a score. While keys are unique, scores may be repeated.
  This way you can get a range of keys based on their score in an efficient way.

  Like the Redis implementation
  we keep two "views" of the data at all times. One optimized for
  key access (using a hash map), and one for scores (using a red black tree).

  Reference:
  - https://redis.io/topics/data-types#sorted-sets
  - https://github.com/antirez/redis/blob/unstable/src/t_zset.c
  """

  alias Dasie.RedBlackTree

  defstruct scores: nil,
            keys: nil

  @type t :: %__MODULE__{
          scores: map,
          keys: Dasie.RedBlackTree.t()
        }

  @doc "Create a new sorted set with key and score."
  @spec new(key :: any, score :: integer) :: __MODULE__.t()
  def new(key, score) do
    %__MODULE__{
      scores: RedBlackTree.new({score, key}),
      keys: %{key => score}
    }
  end

  @doc "Create a new sorted set with a list of `{keys, score}`"
  @spec new(list({any, integer})) :: __MODULE__.t()
  def new([first | rest]) do
    {key1, score1} = first

    keys =
      Enum.reduce(rest, %{key1 => score1}, fn {key, score}, acc ->
        Map.put(acc, key, score)
      end)

    scores =
      Enum.reduce(rest, RedBlackTree.new({score1, key1}), fn {key, score}, acc ->
        if Map.get(keys, key) == score do
          RedBlackTree.insert(acc, {score, key})
        else
          acc
        end
      end)

    %__MODULE__{keys: keys, scores: scores}
  end

  @doc "Insert a new key, score into the sorted set"
  @spec insert(set :: __MODULE__.t(), key :: any, score :: integer) :: __MODULE__.t()
  def insert(%__MODULE__{} = set, key, score) do
    existing_score = Map.get(set.keys, key)

    scores =
      if existing_score == nil do
        RedBlackTree.insert(set.scores, {score, key})
      else
        update(set.scores, {existing_score, key}, {score, key})
      end

    %__MODULE__{keys: Map.put(set.keys, key, score), scores: scores}
  end

  @doc "Insert a list of {key, score} tuples into the sorted set"
  @spec insert(set :: __MODULE__.t(), list({any, integer})) :: __MODULE__.t()
  def insert(%__MODULE__{} = set, elements) when is_list(elements) do
    keys =
      Enum.reduce(elements, set.keys, fn {key, score}, acc ->
        Map.put(acc, key, score)
      end)

    scores =
      Enum.reduce(elements, set.scores, fn element, acc ->
        insertion(set.keys, keys, element, acc)
      end)

    %__MODULE__{keys: keys, scores: scores}
  end

  defp insertion(old_keys, new_keys, {key, score}, acc) do
    existing_score = Map.get(old_keys, key)
    new_score = Map.get(new_keys, key)

    cond do
      score != new_score ->
        acc

      existing_score == nil ->
        RedBlackTree.insert(acc, {score, key})

      existing_score == score ->
        acc

      true ->
        update(acc, {existing_score, key}, {score, key})
    end
  end

  defp update(%RedBlackTree{} = scores, existing, updated) do
    deleted = RedBlackTree.delete(scores, existing)

    if deleted == nil do
      RedBlackTree.new(updated)
    else
      RedBlackTree.insert(deleted, updated)
    end
  end

  @doc "Return a list of keys and their scores in the set"
  @spec to_list(set :: __MODULE__.t()) :: list({any, integer})
  def to_list(%__MODULE__{keys: keys}) do
    keys
    |> Map.to_list()
    |> Enum.sort()
  end

  @doc "Returns a list of keys, with scores that are within the range (inclusive)"
  def range(%__MODULE__{scores: scores}, first..last) do
    range(scores, first, last, [])
    |> Enum.sort()
    |> Enum.map(&external_format/1)
  end

  @spec range(set :: __MODULE__.t() | nil, first :: integer, last :: integer, acc :: list) :: list({any, integer})
  def range(nil, _, _, acc), do: acc

  def range(
        %RedBlackTree{data: {score, _key} = element, left: nil, right: nil},
        first,
        last,
        acc
      )
      when score >= first and score <= last do
    [element | acc]
  end

  def range(%RedBlackTree{data: {score, _key} = element, left: nil} = rbt, first, last, acc)
      when score >= first and score <= last do
    [element | range(rbt.right, first, last, acc)]
  end

  def range(%RedBlackTree{data: {score, _key} = element, right: nil} = rbt, first, last, acc)
      when score >= first and score <= last do
    [element | range(rbt.left, first, last, acc)]
  end

  def range(%RedBlackTree{data: {score, _key} = element} = rbt, first, last, acc)
      when score >= first and score <= last do
    [element] ++ range(rbt.left, first, last, acc) ++ range(rbt.right, first, last, acc)
  end

  def range(%RedBlackTree{left: nil} = rbt, first, last, acc) do
    range(rbt.right, first, last, acc)
  end

  def range(%RedBlackTree{right: nil} = rbt, first, last, acc) do
    range(rbt.left, first, last, acc)
  end

  def range(%RedBlackTree{} = rbt, first, last, acc) do
    range(rbt.left, first, last, acc) ++ range(rbt.right, first, last, acc)
  end

  @doc "Deletes a key from the set"
  @spec delete(set :: __MODULE__.t(), key :: any) :: __MODULE__.t()
  def delete(%__MODULE__{} = set, key) do
    existing_score = Map.get(set.keys, key)

    if existing_score == nil do
      set
    else
      %__MODULE__{
        keys: Map.delete(set.keys, key),
        scores: RedBlackTree.delete(set.scores, {existing_score, key})
      }
    end
  end

  @doc "Checks if key exists in the set"
  @spec member?(set :: __MODULE__.t(), key :: any) :: boolean
  def member?(%__MODULE__{} = set, key) do
    Map.has_key?(set.keys, key)
  end

  defp external_format({score, key}), do: {key, score}
end
