class CreateEndorsements < ActiveRecord::Migration[5.2]
  def change
    create_table :endorsements do |t|
      t.references :user, foreign_key: true
      t.references :classified_listing, foreign_key: true
      t.text :message
      t.boolean :approved
      t.boolean :edited
      t.boolean :deleted

      t.timestamps
    end
  end
end
