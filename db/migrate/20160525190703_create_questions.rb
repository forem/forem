class CreateQuestions < ActiveRecord::Migration[4.2]
  def change
    create_table :questions do |t|
      t.string  :main_text
      t.text  :sub_text
      t.string :slug
      t.boolean :published, default: false
      t.datetime :published_at
      t.boolean :featured, default: false
      t.integer :featured_number
      t.timestamps null: false
    end
  end
end
