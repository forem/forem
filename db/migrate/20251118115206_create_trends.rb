class CreateTrends < ActiveRecord::Migration[7.0]
  def change
    create_table :trends do |t|
      t.references :subforem, null: false, foreign_key: true
      t.string :short_title, null: false
      t.text :public_description, null: false
      t.text :full_content_description, null: false
      t.datetime :expiry_date, null: false
      t.timestamps
    end

    add_index :trends, :subforem_id unless index_exists?(:trends, :subforem_id)
    add_index :trends, :expiry_date unless index_exists?(:trends, :expiry_date)
  end
end

