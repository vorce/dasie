defmodule Dasie.TrieTest do
  use ExUnit.Case

  describe "insert/2" do
    test "insert word" do
      assert Dasie.Trie.insert(Dasie.Trie.new(), "foo") == %Dasie.Trie{
        data: nil, terminates?: false,
        children: [
          %Dasie.Trie{children: [
            %Dasie.Trie{children: [
              %Dasie.Trie{children: [], data: "o", terminates?: true}],
            data: "o",
            terminates?: false}],
          data: "f",
          terminates?: false}]}
    end

    test "insert words" do
      result = Dasie.Trie.new()
      |> Dasie.Trie.insert("hi")
      |> Dasie.Trie.insert("hey")

      assert result == %Dasie.Trie{
              children: [
                %Dasie.Trie{
                  children: [
                    %Dasie.Trie{
                      children: [
                        %Dasie.Trie{children: [], data: "y", terminates?: true}
                      ],
                      data: "e",
                      terminates?: false
                    },
                    %Dasie.Trie{children: [], data: "i", terminates?: true}
                  ],
                  data: "h",
                  terminates?: false
                }
              ],
              data: nil,
              terminates?: false
            }
    end
  end

  describe "all_suffixes/2" do
    test "checks" do
      trie = Dasie.Trie.new()
      |> Dasie.Trie.insert("hello")
      |> Dasie.Trie.insert("howdy")
      |> Dasie.Trie.insert("hollah")
      |> Dasie.Trie.insert("hey")
      |> Dasie.Trie.insert("hi")

      assert Dasie.Trie.valid_words(trie, "he") |> Enum.sort() == ["llo", "y"] |> Enum.sort()
    end
  end
end
