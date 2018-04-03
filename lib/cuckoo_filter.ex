defmodule Dasie.CuckooFilter do
  @moduledoc """
  A cuckoo filter is like a bloom filter but better ;)

  References:
  - https://brilliant.org/wiki/cuckoo-filter/
  - https://bdupras.github.io/filter-tutorial/
  - https://www.cs.cmu.edu/%7Edga/papers/cuckoo-conext2014.pdf
  - https://github.com/bdupras/guava-probably/blob/master/src/main/java/com/duprasville/guava/probably/CuckooFilter.java
  """

  @default_fingerprint_length 7

  defstruct buckets: %{}

  def insert(%__MODULE__{}, item) when is_binary(item) do
    hash = :erlang.md5(item)
    # fingerprint = fingerprint(hash)
    # bucket_1 = hash(item)
    # bucket_2 = bucket_1 xor hash(fingerprint)
  end

  @doc """
  > the cuckoo filter uses a small f-bit fingerprint to represent the data. The value of f is decided on the ideal false positive probability the programmer wants.
  > f = 7, however, was the optimal property for the cuckoo filter.
  ...
  > Once the fingerprint was 7 bits long, the load factor of the cuckoo filter mirrored that of a cuckoo hash table that used two perfectly random hash functions.
  """
  def fingerprint(hash, size \\ @default_fingerprint_length) do

  end
end
