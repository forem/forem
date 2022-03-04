class HtmlVariantTrial < ApplicationRecord
  belongs_to :html_variant
  belongs_to :article, optional: true
end
