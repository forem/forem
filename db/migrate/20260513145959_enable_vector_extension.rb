class EnableVectorExtension < ActiveRecord::Migration[7.0]
  def up
    enable_extension "vector"
  end

  def down
    # Extensions are typically left enabled on rollback to prevent breaking other dependencies
  end
end
