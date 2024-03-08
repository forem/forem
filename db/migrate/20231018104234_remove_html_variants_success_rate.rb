class RemoveHtmlVariantsSuccessRate < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :html_variants, :success_rate
    end
  end
end
