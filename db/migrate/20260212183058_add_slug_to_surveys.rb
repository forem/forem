class AddSlugToSurveys < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :surveys, :slug, :string
    add_index :surveys, :slug, unique: true, algorithm: :concurrently
    add_column :surveys, :old_slug, :string
    add_index :surveys, :old_slug, algorithm: :concurrently
    add_column :surveys, :old_old_slug, :string
    add_index :surveys, :old_old_slug, algorithm: :concurrently
  end
end
