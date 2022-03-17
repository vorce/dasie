defmodule TrieTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Dasie.Trie

  describe "new" do
    test "empty trie" do
      assert Trie.new() == %Trie{}
    end
  end

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

    # http://www.mathcs.emory.edu/~cheung/Courses/323/Syllabus/Text/trie01.html
    property "number of leaf nodes == number of words" do
      check all(words <- word_list_generator(list: [min_length: 10], string: [min_length: 3])) do
        trie =
          Enum.reduce(words, Trie.new(), fn word, acc ->
            Trie.insert(acc, word)
          end)

        assert total_leaf_nodes(trie) == length(words)
      end
    end

    property "height of the trie == length of the longest string" do
      check all(words <- word_list_generator(list: [min_length: 10], string: [min_length: 3])) do
        trie =
          Enum.reduce(words, Trie.new(), fn word, acc ->
            Trie.insert(acc, word)
          end)

        longest_string = Enum.max_by(words, fn word -> String.length(word) end)

        assert height(trie) == String.length(longest_string)
      end
    end
  end

  describe "valid_words/2" do
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

  describe "child/2" do
    test "returns matching child" do
      child =
        Trie.new()
        |> Trie.insert("hello")
        |> Trie.insert("hey")
        |> Trie.child("h")
        |> Trie.child("e")

      assert child.data == "e"
      assert child.count == 2
      refute child.terminates?
    end

    test "returns nil for unknown child" do
      child =
        Trie.new()
        |> Trie.insert("hello")
        |> Trie.child("x")

      assert child == nil
    end
  end

  describe "insert_all/2" do
    test "equivalent to many insert" do
      trie = Trie.new()
      assert trie |> Trie.insert("hi") |> Trie.insert("hey") == trie |> Trie.insert_all(["hi", "hey"])
    end
  end

  describe "collectable into" do
    test "Trie" do
      list = ["cake", "cookie", "donut", "cool"]
      assert Enum.into(list, Trie.new()) == Trie.new() |> Trie.insert_all(list)
    end
  end

  def word_list_generator(opts \\ []) do
    string_options = Keyword.get(opts, :string, [])
    list_options = Keyword.get(opts, :list, [])

    :alphanumeric
    |> StreamData.string(string_options)
    |> StreamData.uniq_list_of(list_options)
    |> StreamData.nonempty()
  end

  def total_leaf_nodes(trie, acc \\ 0)
  def total_leaf_nodes(nil, acc), do: acc
  def total_leaf_nodes(%Trie{terminates?: true, children: []}, acc), do: acc + 1

  def total_leaf_nodes(%Trie{terminates?: true, children: children}, acc) do
    children
    |> Enum.map(&total_leaf_nodes(&1, acc + 1))
    |> Enum.sum()
  end

  def total_leaf_nodes(%Trie{terminates?: false, children: children}, acc) do
    children
    |> Enum.map(&total_leaf_nodes(&1, acc))
    |> Enum.sum()
  end

  def height(trie, acc \\ 0)
  def height(nil, acc), do: acc
  def height(%Trie{children: []}, acc), do: acc

  def height(%Trie{children: children}, acc) do
    children
    |> Enum.map(&height(&1, acc + 1))
    |> Enum.max()
  end
end
