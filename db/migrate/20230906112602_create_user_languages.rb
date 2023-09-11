class CreateUserLanguages < ActiveRecord::Migration[7.0]
  def change
    create_table :user_languages do |t|
      t.references :user, foreign_key: true, null: false
      t.string :language, null: false

      t.timestamps
    end
  end
end
