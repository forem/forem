json.partial! "comment", comment: @comment

# recursively render the comment subtree
json.children do
  json.partial! "comments_trees", trees: @comment_tree
end
