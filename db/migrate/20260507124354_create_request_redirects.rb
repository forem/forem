class CreateRequestRedirects < ActiveRecord::Migration[7.0]
  def change
    create_table :request_redirects do |t|
      t.string :original_url, null: false
      t.string :destination_url, null: false
      t.string :request_domain, null: false

      t.timestamps
    end

    add_index :request_redirects, [:request_domain, :original_url], unique: true
  end
end
