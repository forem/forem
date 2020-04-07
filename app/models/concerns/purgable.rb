# Copied from the deprecate fastly-rails gem
# https://github.com/fastly/fastly-rails/blob/master/lib/fastly-rails/active_record/surrogate_key.rb
#
# This concern handles purge and purge_all calls to purge the edge cache (Fastly)
module Purgable
  extend ActiveSupport::Concern

  module ClassMethods
    def purge_all
      return unless Rails.env.production?

      service.purge_by_key(table_key)
    end

    def soft_purge_all
      return unless Rails.env.production?

      service.purge_by_key(table_key, true)
    end

    def table_key
      table_name
    end

    def fastly_service_identifier
      return unless Rails.env.production?

      service.service_id
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
    return unless Rails.env.production?

    service.purge_by_key(record_key)
  end

  def soft_purge
    return unless Rails.env.production?

    service.purge_by_key(record_key, true)
  end

  def purge_all
    self.class.purge_all
  end

  def soft_purge_all
    self.class.soft_purge_all
  end

  def fastly_service_identifier
    self.class.fastly_service_identifier
  end

  private

  def fastly
    return unless Rails.env.production?

    Fastly.new(api_key: ApplicationConfig["FASTLY_API_KEY"])
  end

  def service
    return unless Rails.env.production?

    Fastly::Service.new({ id: ApplicationConfig["FASTLY_SERVICE_ID"] }, fastly)
  end
end
