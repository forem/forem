class CreateCompliments < ActiveRecord::Migration[6.0]
  def change
    create_table :compliments do |t|
      t.string :text
      t.timestamps
    end
  end
end
