class AddManualSettingToLinkedDomains < ActiveRecord::Migration[7.0]
  def change
    add_column :linked_domains, :manual_setting, :integer, default: 0, null: false
  end
end
