class CreateSurveys < ActiveRecord::Migration[7.0]
  def change
    create_table :surveys do |t|
      t.string :title, null: false
      t.boolean :active, default: true
      t.boolean :display_title, default: true
      t.timestamps
    end
  end
end
