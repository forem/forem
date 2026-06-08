class AddPageDelegationToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :page_id, :bigint
    add_column :events, :delegate_to_page, :boolean, default: false, null: false
  end
end
