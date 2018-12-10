defmodule Dasie.CuckooFilter do
  @moduledoc """
  A cuckoo filter is like a bloom filter but better ;)

  References:
  - https://brilliant.org/wiki/cuckoo-filter/
  - https://bdupras.github.io/filter-tutorial/
  - https://www.cs.cmu.edu/%7Edga/papers/cuckoo-conext2014.pdf
  - https://github.com/bdupras/guava-probably/blob/master/src/main/java/com/duprasville/guava/probably/CuckooFilter.java
  """
  use Bitwise

  defmodule Bucket do
    @moduledoc """
    A bucket can have multiple entries
    """
    defstruct id: nil,
              entries: MapSet.new()
  end

  @default_fingerprint_length 16
  # number of relocations allowed before giving up on an item. If we reach this this hash table is considered too full.
  @max_displacements 500

  # A basic cuckoo hash table consists of an array of buckets
  # TODO what are sensible defaults?!
  defstruct buckets: %{},
            load: 0,
            fingerprint_size: @default_fingerprint_length,
            bucket_size: 4,
            bucket_count: 10,
            max_keys: 100_000

  def new(opts \\ []) do
    max_keys = opts[:max_keys] || 100_000
    bucket_size = opts[:bucket_size] || 4

    cuckoo = %__MODULE__{max_keys: max_keys, bucket_size: bucket_size}
    keys_per_bucket_size = cuckoo.max_keys / cuckoo.bucket_size
    log2 = :math.log(keys_per_bucket_size) / :math.log(2)
    bucket_count = :math.pow(2, Float.ceil(log2)) |> trunc()
    %__MODULE__{cuckoo | bucket_count: bucket_count}
  end

  def insert(%__MODULE__{} = cuckoo, item), do: insert(cuckoo, item, 0)

  defp insert(%__MODULE__{}, _item, relocation_round) when relocation_round >= @max_displacements, do: {:error, :full}

  defp insert(%__MODULE__{} = cuckoo, item, relocation_round) do
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
        IO.puts("No space in either bucket #{inspect([bucket_1, bucket_2])}, relocating...")

        cuckoo
        |> relocate(bucket_1, bucket_2)
        |> insert(item, relocation_round + 1)
    end
  end

  def member?(%__MODULE__{} = cuckoo, item) do
    fingerprint = fingerprint(item, cuckoo.fingerprint_size)
    bucket_1 = item |> hash() |> rem(cuckoo.bucket_count)
    bucket_2 = bucket_1 |> bxor(hash(fingerprint)) |> rem(cuckoo.bucket_count)

    cuckoo.buckets
    |> Map.take([bucket_1, bucket_2])
    |> Enum.map(fn {_k, bucket} -> MapSet.member?(bucket.entries, fingerprint) end)
    |> Enum.any?(&(&1 == true))
  end

  def delete(%__MODULE__{} = cuckoo, item) do
    fingerprint = fingerprint(item, cuckoo.fingerprint_size)
    bucket_1 = item |> hash() |> rem(cuckoo.bucket_count)
    bucket_2 = bucket_1 |> bxor(hash(fingerprint)) |> rem(cuckoo.bucket_count)

    modified =
      cuckoo.buckets
      |> Map.take([bucket_1, bucket_2])
      |> Enum.into(%{}, fn {k, bucket} -> {k, %Bucket{bucket | entries: MapSet.delete(bucket.entries, fingerprint)}} end)

    %__MODULE__{cuckoo | buckets: Map.merge(cuckoo.buckets, modified)}
  end

  defp hash(item) do
    :erlang.phash2(item)
  end

  defp has_space?(%__MODULE__{} = cuckoo, bucket_id) do
    bucket = Map.get(cuckoo.buckets, bucket_id, %Bucket{id: bucket_id})
    MapSet.size(bucket.entries) < cuckoo.bucket_size
  end

  defp add_entry(%__MODULE__{} = cuckoo, bucket_id, fingerprint) do
    bucket = Map.get(cuckoo.buckets, bucket_id, %Bucket{id: bucket_id})
    new_bucket = %Bucket{bucket | entries: MapSet.put(bucket.entries, fingerprint)}
    %__MODULE__{cuckoo | buckets: Map.put(cuckoo.buckets, bucket_id, new_bucket), load: cuckoo.load + 1}
  end

  defp relocate(%__MODULE__{} = cuckoo, bucket_1, bucket_2) do
    cuckoo
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
end
