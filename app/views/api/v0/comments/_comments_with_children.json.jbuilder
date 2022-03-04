json.array! comments.keys do |root_comment|
  # ancestry organizes root comments and their descendants in a hash structure
  json.partial! "comment_with_children", comment: root_comment, children: comments[root_comment]
end
