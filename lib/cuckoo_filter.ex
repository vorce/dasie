defmodule Dasie.CuckooFilter do
  @moduledoc """
  A cuckoo filter is like a bloom filter but better ;)

  TODO: This one I am still a bit unsure of, as in how correct and usable
  the current implementation is.

  References:
  - https://brilliant.org/wiki/cuckoo-filter/
  - https://bdupras.github.io/filter-tutorial/
  - https://www.cs.cmu.edu/%7Edga/papers/cuckoo-conext2014.pdf
  - https://github.com/bdupras/guava-probably/blob/master/src/main/java/com/duprasville/guava/probably/CuckooFilter.java
  """
  use Bitwise
  alias Dasie.CuckooFilter

  defmodule Bucket do
    @moduledoc """
    A bucket can have multiple entries
    """
    defstruct id: nil,
              entries: MapSet.new()
  end

  @default_fingerprint_length 16
  # number of relocations allowed before giving up on an item. If we reach this the hash table is considered too full.
  @max_displacements 500

  # A basic cuckoo hash table consists of an array of buckets
  # TODO what are sensible defaults?!
  defstruct buckets: %{},
            # number of entries in the filter
            load: 0,
            fingerprint_size: @default_fingerprint_length,
            bucket_size: 4,
            bucket_count: 10,
            max_keys: 100_000

  @type t :: %__MODULE__{
          buckets: map,
          load: integer,
          fingerprint_size: integer,
          bucket_size: integer,
          bucket_count: integer,
          max_keys: integer
        }

  @spec new(opts :: Keyword.t()) :: CuckooFilter.t()
  def new(opts \\ []) do
    max_keys = opts[:max_keys] || 100_000
    bucket_size = opts[:bucket_size] || 4

    cuckoo = %__MODULE__{max_keys: max_keys, bucket_size: bucket_size}
    keys_per_bucket_size = cuckoo.max_keys / cuckoo.bucket_size
    log2 = :math.log(keys_per_bucket_size) / :math.log(2)
    bucket_count = :math.pow(2, Float.ceil(log2)) |> trunc()
    %CuckooFilter{cuckoo | bucket_count: bucket_count}
  end

  @spec insert(cuckoo :: CuckooFilter.t(), item :: any) :: CuckooFilter.t() | {:error, :full}
  def insert(%CuckooFilter{} = cuckoo, item) do
    # each item x has two candidate buckets determined by hash functions h1(x) and h2(x)
    fingerprint = fingerprint(item, cuckoo.fingerprint_size)
    bucket_1 = item |> hash() |> rem(cuckoo.bucket_count)
    # = bucket_1 xor hash(fingerprint)
    bucket_2 = bucket_1 |> bxor(hash(fingerprint)) |> rem(cuckoo.bucket_count)

    cond do
      has_space?(cuckoo, bucket_1) ->
        add_entry(cuckoo, bucket_1, fingerprint)

      has_space?(cuckoo, bucket_2) ->
        add_entry(cuckoo, bucket_2, fingerprint)

      true ->
        # IO.puts("No space in either bucket #{inspect([bucket_1, bucket_2])}, relocating...")

        [bucket_1, bucket_2]
        |> Enum.random()
        |> relocate(cuckoo, fingerprint)
    end
  end

  @spec insert_all(cuckoo :: CuckooFilter.t(), items :: list(any)) :: CuckooFilter.t() | {:error, :full}
  def insert_all(%CuckooFilter{} = cuckoo, items) when is_list(items) do
    Enum.reduce(items, cuckoo, fn item, acc ->
      insert(acc, item)
    end)
  end

  @spec member?(cuckoo :: CuckooFilter.t(), item :: any) :: true | false
  def member?(%CuckooFilter{} = cuckoo, item) do
    fingerprint = fingerprint(item, cuckoo.fingerprint_size)
    bucket_1 = item |> hash() |> rem(cuckoo.bucket_count)
    bucket_2 = bucket_1 |> bxor(hash(fingerprint)) |> rem(cuckoo.bucket_count)

    cuckoo.buckets
    |> Map.take([bucket_1, bucket_2])
    |> Enum.map(fn {_k, bucket} -> MapSet.member?(bucket.entries, fingerprint) end)
    |> Enum.any?(&(&1 == true))
  end

  @spec delete(cuckoo :: CuckooFilter.t(), item :: any) :: CuckooFilter.t()
  def delete(%CuckooFilter{} = cuckoo, item) do
    fingerprint = fingerprint(item, cuckoo.fingerprint_size)
    bucket_1 = item |> hash() |> rem(cuckoo.bucket_count)
    bucket_2 = bucket_1 |> bxor(hash(fingerprint)) |> rem(cuckoo.bucket_count)

    modified =
      cuckoo.buckets
      |> Map.take([bucket_1, bucket_2])
      |> Enum.into(%{}, fn {k, bucket} -> {k, %Bucket{bucket | entries: MapSet.delete(bucket.entries, fingerprint)}} end)

    %CuckooFilter{cuckoo | buckets: Map.merge(cuckoo.buckets, modified)}
  end

  defp hash(item) do
    :erlang.phash2(item)
  end

  defp has_space?(%CuckooFilter{} = cuckoo, bucket_id) do
    bucket = Map.get(cuckoo.buckets, bucket_id, %Bucket{id: bucket_id})
    MapSet.size(bucket.entries) < cuckoo.bucket_size
  end

  defp add_entry(%CuckooFilter{} = cuckoo, bucket_id, fingerprint) do
    bucket = Map.get(cuckoo.buckets, bucket_id, %Bucket{id: bucket_id})
    new_bucket = %Bucket{bucket | entries: MapSet.put(bucket.entries, fingerprint)}
    %CuckooFilter{cuckoo | buckets: Map.put(cuckoo.buckets, bucket_id, new_bucket), load: cuckoo.load + 1}
  end

  defp relocate(bucket_id, cuckoo, fingerprint, relocation_round \\ 0)

  defp relocate(_bucket_id, %CuckooFilter{} = _cuckoo, _fingerprint, round) when round >= @max_displacements do
    {:error, :full}
  end

  defp relocate(bucket_id, %CuckooFilter{} = cuckoo, fingerprint, relocation_round) do
    bucket = Map.get(cuckoo.buckets, bucket_id)
    random_entry = bucket.entries |> MapSet.to_list() |> Enum.random()
    entries = bucket.entries |> MapSet.delete(random_entry) |> MapSet.put(fingerprint)
    bucket = %Bucket{bucket | entries: entries}
    cuckoo = %CuckooFilter{cuckoo | buckets: Map.put(cuckoo.buckets, bucket_id, bucket)}
    bucket_i = bucket.id |> bxor(hash(random_entry)) |> rem(cuckoo.bucket_count)

    if has_space?(cuckoo, bucket_i) do
      add_entry(cuckoo, bucket_i, random_entry)
    else
      relocate(bucket_i, cuckoo, random_entry, relocation_round + 1)
    end
  end

  @doc """
  > the cuckoo filter uses a small f-bit fingerprint to represent the data. The value of f is decided on the ideal false positive probability the programmer wants.
  > f = 7, however, was the optimal property for the cuckoo filter.
  ...
  > Once the fingerprint was 7 bits long, the load factor of the cuckoo filter mirrored that of a cuckoo hash table that used two perfectly random hash functions.
  """
  def fingerprint(item, size \\ @default_fingerprint_length) do
    :erlang.phash2(item) &&& (1 <<< size) - 1
  end

  defimpl Collectable, for: Dasie.CuckooFilter do
    def into(original) do
      collector_fun = fn
        filter, {:cont, elem} -> Dasie.CuckooFilter.insert(filter, elem)
        filter, :done -> filter
        _filter, :halt -> :ok
      end

      {original, collector_fun}
    end
  end
end
