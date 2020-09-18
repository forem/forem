class RemovePathRedirects < ActiveRecord::Migration[6.0]
  def change
    drop_table :path_redirects
  end
end
