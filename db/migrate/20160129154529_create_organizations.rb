class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string  :name
      t.text    :summary
      t.string  :profile_image
      t.string  :url
      t.string  :twitter_username
      t.string  :jobs_url
      t.string  :jobs_email
      t.string  :address
      t.string  :city
      t.string  :state
      t.string  :zip_code
      t.string  :country
      t.timestamps null: false
    end
  end
end
