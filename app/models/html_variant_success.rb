class HtmlVariantSuccess < ApplicationRecord
  validates :html_variant_id, presence: true
  belongs_to :html_variant
  belongs_to :article, optional: true
end
