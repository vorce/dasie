defmodule Dasie.Maybe do
  @moduledoc """
  Represent something empty/missing or not. Also known as Optional in some languages.

  This is a pretty contrived thing, but wanted to see how it would look :)
  Another take would be to use a single or zero element list.
  """
  defstruct value: nil

  @type t :: %__MODULE__{
          value: any
        }

  @spec of(value :: any) :: __MODULE__.t()
  def of(value), do: %__MODULE__{value: value}

  @spec present?(any) :: boolean
  def present?(%__MODULE__{value: nil}), do: false
  def present?(nil), do: false
  def present?(_), do: true

  @doc """
  If a value is present in this Maybe, returns `{:ok, value}`, otherwise returns `{:error, :no_value}`.
  """
  @spec get(maybe :: __MODULE__.t()) :: {:ok, any} | {:error, :no_value}
  def get(%__MODULE__{value: nil}), do: {:error, :no_value}
  def get(%__MODULE__{value: val}), do: {:ok, val}
end
