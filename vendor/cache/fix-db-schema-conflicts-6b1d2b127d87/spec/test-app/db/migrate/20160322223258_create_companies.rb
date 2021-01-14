class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name
      t.string :addr1
      t.string :addr2
      t.string :city
      t.string :state
      t.string :zip
      t.string :phone

      t.timestamps null: false
    end

    add_index :companies, :name
    add_index :companies, :city
    add_index :companies, :state
  end
end
