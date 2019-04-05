require "libhoney"

module Honeycomb
  class << self
    attr_accessor :client
  end
end

key = ApplicationConfig["HONEYCOMB_API_KEY"]
dataset = "dev.to-#{Rails.env}"

Honeycomb.client = if Rails.env.development? || Rails.env.test?
                     Libhoney::NullClient.new
                   else
                     Libhoney::Client.new(
                       writekey: key,
                       dataset: dataset,
                       user_agent_addition: HoneycombRails::USER_AGENT_SUFFIX,
                     )
                   end

HoneycombRails.configure do |conf|
  conf.writekey = key
  conf.dataset = dataset
  conf.db_dataset = "dev.to-db-#{Rails.env}"
  conf.client = Honeycomb.client
end
