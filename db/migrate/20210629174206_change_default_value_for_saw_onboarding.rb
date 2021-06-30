class ChangeDefaultValueForSawOnboarding < ActiveRecord::Migration[6.1]
  def change
    change_column_default :users, :saw_onboarding, from: true, to: false
  end
end
