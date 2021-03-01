class AddMissingForeignKeysToHtmlVariantsModels < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :html_variant_successes, :html_variants, column: :html_variant_id, on_delete: :cascade, validate: false
    add_foreign_key :html_variant_successes, :articles, column: :article_id, on_delete: :nullify, validate: false

    add_foreign_key :html_variant_trials, :html_variants, column: :html_variant_id, on_delete: :cascade, validate: false
    add_foreign_key :html_variant_trials, :articles, column: :article_id, on_delete: :nullify, validate: false
  end
end
