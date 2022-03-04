class ChangeDefaultValueForEditorVersion < ActiveRecord::Migration[6.1]
  def change
    change_column_default :users, :editor_version, from: "v1", to: "v2"
  end
end
