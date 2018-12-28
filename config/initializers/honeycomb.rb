require "libhoney"

key = ApplicationConfig["HONEYCOMB_API_KEY"]
dataset = "dev.to-#{Rails.env}"

$libhoney = if Rails.env.development? || Rails.env.test?
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
  conf.client = $libhoney
end
