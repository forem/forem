class AddPageDelegationToEvents < ActiveRecord::Migration[7.0]
  def up
    add_column :events, :page_id, :bigint
    add_foreign_key :events, :pages, column: :page_id, on_delete: :restrict, validate: false
    add_column :events, :delegate_to_page, :boolean, default: false, null: false
  end

  def down
    safety_assured do
      remove_foreign_key :events, :pages, column: :page_id
      remove_column :events, :page_id, :bigint
      remove_column :events, :delegate_to_page, :boolean, default: false, null: false
    end
  end
end
