json.array! trees.keys do |root_comment|
  json.partial! "comment", comment: root_comment

  # recursively render the comment subtree
  json.children do
    json.partial! "comments_trees", trees: trees[root_comment]
  end
end
