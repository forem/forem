class CreateOnboardingChecklists < ActiveRecord::Migration[7.0]
  def change
    create_table :onboarding_checklists do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.jsonb :items, null: false, default: {}
      t.datetime :completed_at
      t.timestamps
    end
  end
end
