# Copied from the deprecated fastly-rails gem
# https://github.com/fastly/fastly-rails/blob/master/lib/fastly-rails/active_record/surrogate_key.rb
#
# This concern handles purge and purge_all calls to purge Fastly or Cloudflare edge cache.
# If neither CDN has been configured, these methods will short circuit and not be invoked.
module Purgeable
  extend ActiveSupport::Concern

  module ClassMethods
    def purge_all
      if fastly
        service.purge_by_key(table_key)
      elsif cloudflare_configured?
        EdgeCache::PurgeByKey.call(table_key)
      end
    end

    def soft_purge_all
      if fastly
        service.purge_by_key(table_key, true)
      elsif cloudflare_configured?
        EdgeCache::PurgeByKey.call(table_key, soft: true)
      end
    end

    def table_key
      table_name
    end

    def fastly
      return false if Rails.env.development?
      return false if ApplicationConfig["FASTLY_API_KEY"].blank? || ApplicationConfig["FASTLY_SERVICE_ID"].blank?

      Fastly.new(api_key: ApplicationConfig["FASTLY_API_KEY"])
    end

    def cloudflare_configured?
      return false if Rails.env.development?

      ApplicationConfig["CLOUDFLARE_API_TOKEN"].present? && ApplicationConfig["CLOUDFLARE_ZONE_ID"].present?
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
    if fastly
      service.purge_by_key(record_key)
    elsif self.class.cloudflare_configured?
      EdgeCache::PurgeByKey.call(record_key)
    end
  end

  def soft_purge
    if fastly
      service.purge_by_key(record_key, true)
    elsif self.class.cloudflare_configured?
      EdgeCache::PurgeByKey.call(record_key, soft: true)
    end
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
