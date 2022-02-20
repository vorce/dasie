defmodule Dasie.ReactiveMap do
  @moduledoc """
  A hash table / map, that can have values that refers to other values in the table.

  What is this good for? Maybe a building block for some spreadsheet-like application.
  """

  # TODO: Implement Access protocol:
  # https://hexdocs.pm/elixir/1.13/Access.html#callbacks

  defmodule Ref do
    @moduledoc """
    Internal struct that represent a value in a `Dasie.ReactiveMap` that references another key.

    Don't use directly.
    """
    defstruct [:key, :read_fn]
  end

  # TODO: Delegate all expected functions to Map where possible.
  defdelegate new, to: Map
  defdelegate put(map, key, value), to: Map

  @doc """
  Puts a `key` into the map that always has the same value as `ref_key`'s value.
  """
  def put_ref(map, key, ref_key) do
    put_ref(map, key, ref_key, &ref_value_identity/1)
  end

  @doc """
  Puts a `key` into the map that has the value of `read_fn` applied to the value for `ref_key`
  """
  def put_ref(map, key, ref_key, read_fn) do
    Map.put(map, key, %__MODULE__.Ref{key: ref_key, read_fn: read_fn})
  end

  defp ref_value_identity(ref_value), do: ref_value

  @doc """
  Gets the value for a specific `key` in `map`.

  * If `key` is present in `map` then its value value is returned.
  * If `key` is present in `map` and is a reference to another key, the referenced key's value is retrieved and   used as input for the reference read_fun.
  * Otherwise, `default` is returned.

  If `default` is not provided, `nil` is used.
  """
  def get(map, key, default \\ nil) do
    do_get(map, key, default)
  end

  defp do_get(map, key, default, seen_keys \\ MapSet.new()) do
    if MapSet.member?(seen_keys, key) do
      :erlang.error({:circular_reference, key}, [map, key, default])
    else
      get_value(map, key, default, MapSet.put(seen_keys, key))
    end
  end

  defp get_value(map, key, default, seen_keys) do
    case map do
      %{^key => %__MODULE__.Ref{key: ref_key, read_fn: read_fn}} ->
        case do_get(map, ref_key, default, seen_keys) do
          fallback when fallback == default -> default
          val -> read_fn.(val)
        end

      %{^key => val} ->
        val

      %{} ->
        default

      other ->
        :erlang.error({:badmap, other}, [map, key, default])
    end
  end
end
