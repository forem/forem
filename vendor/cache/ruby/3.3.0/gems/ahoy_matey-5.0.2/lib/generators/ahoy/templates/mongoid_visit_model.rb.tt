class Ahoy::Visit
  include Mongoid::Document

  # associations
  has_many :events, class_name: "Ahoy::Event"
  belongs_to :user, index: true, optional: true

  # required
  field :visit_token, type: String
  field :visitor_token, type: String

  # the rest are recommended but optional
  # simply remove the columns you don't want

  # standard
  field :ip, type: String
  field :user_agent, type: String
  field :referrer, type: String
  field :referring_domain, type: String
  field :landing_page, type: String

  # technology
  field :browser, type: String
  field :os, type: String
  field :device_type, type: String

  # location
  field :country, type: String
  field :region, type: String
  field :city, type: String
  field :latitude, type: Float
  field :longitude, type: Float

  # utm parameters
  field :utm_source, type: String
  field :utm_medium, type: String
  field :utm_term, type: String
  field :utm_content, type: String
  field :utm_campaign, type: String

  # native apps
  field :app_version, type: String
  field :os_version, type: String
  field :platform, type: String

  field :started_at, type: Time

  index({visit_token: 1}, {unique: true})
  index({visitor_token: 1, started_at: 1})
end
