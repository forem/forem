class RequestRedirect < ApplicationRecord
  validates :original_url, presence: true, uniqueness: { scope: :request_domain }
  validates :destination_url, presence: true
  validates :request_domain, presence: true
end
