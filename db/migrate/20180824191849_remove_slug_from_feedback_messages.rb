class RemoveSlugFromFeedbackMessages < ActiveRecord::Migration[5.1]
  def change
    remove_column :feedback_messages, :slug
  end
end
