class RemoveActiveFromProfileField < ActiveRecord::Migration[6.0]
  def change
    def change
      safety_assured { remove_column :profile_fields, :active }
    end
  end
end
