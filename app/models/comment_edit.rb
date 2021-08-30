class CommentEdit < ApplicationRecord
  belongs_to :comment
  belongs_to :editor, class_name: "User"

  def modifications
    super.deep_symbolize_keys
  end
end
