class AddPageToPageViews < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :page_views, :page, null: true, index: {algorithm: :concurrently}
  end
end
