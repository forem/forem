# Copied from the deprecated fastly-rails gem
# https://github.com/fastly/fastly-rails/blob/master/lib/fastly-rails/active_record/surrogate_key.rb
#
# This concern handles purge and purge_all calls to purge the edge cache (Fastly)
module Purgeable
  extend ActiveSupport::Concern

  module ClassMethods
    def purge_all
      return if no_fastly?

      service.purge_by_key(table_key)
    end

    def soft_purge_all
      return if no_fastly?

      service.purge_by_key(table_key, true)
    end

    def table_key
      table_name
    end

    def fastly
      return if no_fastly?

      Fastly.new(api_key: ApplicationConfig["FASTLY_API_KEY"])
    end

    def service
      return if no_fastly?

      Fastly::Service.new({ id: ApplicationConfig["FASTLY_SERVICE_ID"] }, fastly)
    end
  end

  # Instance methods
  def record_key
    "#{table_key}/#{id}"
  end

  def table_key
    self.class.table_key
  end

  def purge
    return if no_fastly?

    service.purge_by_key(record_key)
  end

  def soft_purge
    return if no_fastly?

    service.purge_by_key(record_key, true)
  end

  def purge_all
    self.class.purge_all
  end

  def soft_purge_all
    self.class.soft_purge_all
  end

  def fastly
    self.class.fastly
  end

  def service
    self.class.service
  end

  private

  def no_fastly?
    Rails.env.development? || ENV["FASTLY_API_KEY"].blank? || ENV["FASTLY_API_KEY"] == "foobarbaz"
  end
end
