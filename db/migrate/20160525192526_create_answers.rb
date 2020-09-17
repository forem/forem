class CreateAnswers < ActiveRecord::Migration[4.2]
  def change
    create_table :answers do |t|
      t.integer  :question_id
      t.integer  :user_id
      t.string :slug
      t.text  :body_markdown
      t.text :body_html
      t.text :body_plain_text
      t.integer :score
      t.timestamps null: false
    end
  end
end
