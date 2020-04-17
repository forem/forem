# Copied from the deprecated fastly-rails gem
# https://github.com/fastly/fastly-rails/blob/master/lib/fastly-rails/active_record/surrogate_key.rb
#
# This concern handles purge and purge_all calls to purge the edge cache (Fastly)
module Purgeable
  extend ActiveSupport::Concern

  module ClassMethods
    def purge_all
      return if Rails.env.development?

      service.purge_by_key(table_key)
    end

    def soft_purge_all
      return if Rails.env.development?

      service.purge_by_key(table_key, true)
    end

    def table_key
      table_name
    end

    def fastly
      return if Rails.env.development?

      Fastly.new(api_key: ApplicationConfig["FASTLY_API_KEY"])
    end

    def service
      return if Rails.env.development?

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
    return if Rails.env.development?

    service.purge_by_key(record_key)
  end

  def soft_purge
    return if Rails.env.development?

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
end
