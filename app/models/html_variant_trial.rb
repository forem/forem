class HtmlVariantTrial < ApplicationRecord
  belongs_to :html_variant
  belongs_to :article, optional: true

  validates :html_variant_id, presence: true
end
