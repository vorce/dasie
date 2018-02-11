defmodule DasieTest do
  use ExUnit.Case
  doctest Dasie

  test "greets the world" do
    assert Dasie.hello() == :world
  end
end
