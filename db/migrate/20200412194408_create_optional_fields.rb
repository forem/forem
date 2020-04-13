class CreateOptionalFields < ActiveRecord::Migration[5.2]
  def change
    create_table :optional_fields do |t|
      t.string :field
      t.string :value
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
