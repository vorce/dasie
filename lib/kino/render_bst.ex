defimpl Kino.Render, for: Dasie.BST do
  def to_livebook(bst) do
    lines = bst_mermaid_lines(bst, "S", "")

    markdown =
      Kino.Markdown.new("""
        ```mermaid
        graph TB
      #{lines}
        ```
      """)

    Kino.Render.to_livebook(markdown)
  end

  defp bst_mermaid_lines(
         %Dasie.BST{left: %Dasie.BST{} = left, right: %Dasie.BST{} = right, data: val},
         label,
         acc
       ) do
    left_label = label <> "L"
    right_label = label <> "R"

    line =
      "\t#{label}((#{val}))-->#{left_label}((#{left.data}))\n" <>
        "\t#{label}-->#{right_label}((#{right.data}))\n"

    line <>
      bst_mermaid_lines(left, left_label, acc) <>
      bst_mermaid_lines(right, right_label, acc)
  end

  defp bst_mermaid_lines(%Dasie.BST{left: nil, right: nil}, _, acc), do: acc

  defp bst_mermaid_lines(
         %Dasie.BST{left: %Dasie.BST{} = left, right: nil, data: val},
         label,
         acc
       ) do
    left_label = label <> "L"
    line = "\t#{label}((#{val}))-->#{left_label}((#{left.data}))\n"
    line <> bst_mermaid_lines(left, left_label, acc)
  end

  defp bst_mermaid_lines(
         %Dasie.BST{left: nil, right: %Dasie.BST{} = right, data: val},
         label,
         acc
       ) do
    right_label = label <> "R"
    line = "\t#{label}((#{val}))-->#{right_label}((#{right.data}))\n"
    line <> bst_mermaid_lines(right, right_label, acc)
  end
end
