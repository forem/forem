class CreateJobListings < ActiveRecord::Migration
  def change
    create_table :job_listings do |t|
      t.integer :organization_id
      t.string  :name
      t.text    :body_html
      t.string  :category
      t.string  :url
      t.string  :email
      t.string  :city
      t.string  :state
      t.string  :country
      t.timestamps null: false
    end
  end
end
