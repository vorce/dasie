defmodule TrieTest do
  use ExUnit.Case

  alias Dasie.Trie

  describe "insert/2" do
    test "insert word" do
      assert Trie.insert(Trie.new(), "foo") == %Trie{
               data: nil,
               terminates?: false,
               children: [
                 %Trie{
                   children: [
                     %Trie{
                       children: [%Trie{children: [], data: "o", terminates?: true}],
                       data: "o",
                       terminates?: false
                     }
                   ],
                   data: "f",
                   terminates?: false
                 }
               ]
             }
    end

    test "insert words" do
      result =
        Trie.new()
        |> Trie.insert("hi")
        |> Trie.insert("hey")

      assert result == %Trie{
               children: [
                 %Trie{
                   children: [
                     %Trie{
                       children: [
                         %Trie{children: [], data: "y", terminates?: true}
                       ],
                       data: "e",
                       terminates?: false
                     },
                     %Trie{children: [], data: "i", terminates?: true}
                   ],
                   data: "h",
                   terminates?: false,
                   count: 2
                 }
               ],
               data: nil,
               terminates?: false,
               count: 1
             }
    end

    test "increases counter for shared nodes" do
      result =
        Trie.new()
        |> Trie.insert("hello")
        |> Trie.insert("hey")

      assert result == %Trie{
               count: 1,
               data: nil,
               terminates?: false,
               children: [
                 %Trie{
                   children: [
                     %Trie{
                       children: [
                         %Trie{children: [], count: 1, data: "y", terminates?: true},
                         %Trie{
                           children: [
                             %Trie{
                               children: [
                                 %Trie{children: [], count: 1, data: "o", terminates?: true}
                               ],
                               count: 1,
                               data: "l",
                               terminates?: false
                             }
                           ],
                           count: 1,
                           data: "l",
                           terminates?: false
                         }
                       ],
                       count: 2,
                       data: "e",
                       terminates?: false
                     }
                   ],
                   count: 2,
                   data: "h",
                   terminates?: false
                 }
               ]
             }
    end
  end

  describe "all_suffixes/2" do
    test "returns all suffixes for the prefix" do
      trie =
        Trie.new()
        |> Trie.insert("hello")
        |> Trie.insert("howdy")
        |> Trie.insert("hollah")
        |> Trie.insert("hey")
        |> Trie.insert("hi")

      assert Trie.valid_words(trie, "he") |> Enum.sort() == ["llo", "y"] |> Enum.sort()
    end
  end

  describe "member?/2" do
    test "returns true if element is in trie" do
      trie =
        Trie.new()
        |> Trie.insert("hello")
        |> Trie.insert("howdy")

      assert Trie.member?(trie, "how")
    end

    test "returns false if element is not in trie" do
      trie =
        Trie.new()
        |> Trie.insert("hello")
        |> Trie.insert("howdy")

      refute Trie.member?(trie, "hey")
    end
  end

  describe "delete/2" do
    test "removes nodes with count 1" do
      trie =
        Trie.new()
        |> Trie.insert("hello")
        |> Trie.insert("hey")

      assert Trie.delete(trie, "hello") == Trie.new() |> Trie.insert("hey")
    end

    test "decreases count of shared nodes" do
      trie =
        Trie.new()
        |> Trie.insert("hello")
        |> Trie.insert("hey")

      assert List.first(trie.children).count == 2

      updated_trie = Trie.delete(trie, "hello")

      assert List.first(updated_trie.children).count == 1
    end
  end
end
