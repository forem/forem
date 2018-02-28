class CreateFeedbackMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :feedback_messages do |t|
      t.text :message
      t.string :feedback_type
      t.string :category_selection
      t.integer :user_id
    end
  end
end
