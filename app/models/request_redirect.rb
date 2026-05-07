class RequestRedirect < ApplicationRecord
  before_validation :normalize_request_domain

  validates :original_url, presence: true, uniqueness: { scope: :request_domain }, format: { with: /\A\//, message: "must start with /" }
  validates :destination_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid HTTP/HTTPS URL" }
  validates :request_domain, presence: true

  private

  def normalize_request_domain
    self.request_domain = request_domain.to_s.strip.downcase if request_domain.present?
  end
end
