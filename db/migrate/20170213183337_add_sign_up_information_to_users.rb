class AddSignUpInformationToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :signup_cta_variant, :string
    add_column :users, :signup_refer_code, :string
    add_column :users, :signup_referring_site, :string
  end
end
