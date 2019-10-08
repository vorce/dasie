defmodule Dasie.MaybeTest do
  use ExUnit.Case

  alias Dasie.Maybe

  describe "present?/1" do
    test "maybe with value" do
      thing = Maybe.of(:something)
      assert Maybe.present?(thing)
    end

    test "maybe with no value" do
      thing = Maybe.of(nil)
      refute Maybe.present?(thing)
    end

    test "raw nil" do
      refute Maybe.present?(nil)
    end

    test "raw value" do
      assert Maybe.present?(1)
    end
  end

  describe "get/1" do
    test "maybe with value" do
      thing = Maybe.of(:something)
      assert Maybe.get(thing) == {:ok, thing.value}
    end

    test "maybe with no value" do
      thing = Maybe.of(nil)
      assert Maybe.get(thing) == {:error, :no_value}
    end
  end
end
