class AddCheckedCodeOfConductToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :checked_code_of_conduct, :boolean, default: false, acceptance: { message: "accept code of conduct" }
  end
end
