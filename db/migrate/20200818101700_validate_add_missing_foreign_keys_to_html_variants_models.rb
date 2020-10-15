class ValidateAddMissingForeignKeysToHtmlVariantsModels < ActiveRecord::Migration[6.0]
  def change
    validate_foreign_key :html_variant_successes, :html_variants
    validate_foreign_key :html_variant_successes, :articles
    validate_foreign_key :html_variant_trials, :html_variants
    validate_foreign_key :html_variant_trials, :articles
  end
end
