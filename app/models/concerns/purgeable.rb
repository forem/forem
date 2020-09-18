# Copied from the deprecated fastly-rails gem
# https://github.com/fastly/fastly-rails/blob/master/lib/fastly-rails/active_record/surrogate_key.rb
#
# This concern handles purge and purge_all calls to purge Fastly's edge cache.
# If Fastly has not been configured, these methods will short circuit and not be invoked.
module Purgeable
  extend ActiveSupport::Concern

  module ClassMethods
    def purge_all
      return unless fastly

      service.purge_by_key(table_key)
    end

    def soft_purge_all
      return unless fastly

      service.purge_by_key(table_key, true)
    end

    def table_key
      table_name
    end

    def fastly
      return false if Rails.env.development?
      return false if ApplicationConfig["FASTLY_API_KEY"].blank? || ApplicationConfig["FASTLY_SERVICE_ID"].blank?

      Fastly.new(api_key: ApplicationConfig["FASTLY_API_KEY"])
    end

    def service
      return unless fastly

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
    return unless fastly

    service.purge_by_key(record_key)
  end

  def soft_purge
    return unless fastly

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
