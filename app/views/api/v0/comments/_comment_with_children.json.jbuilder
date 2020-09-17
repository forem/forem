json.partial! "comment", comment: comment

# recursively render the comment subtree
json.children do
  json.partial! "comments_with_children", comments: children
end
