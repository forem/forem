# Copied from the deprecated fastly-rails gem
# https://github.com/fastly/fastly-rails/blob/master/lib/fastly-rails/active_record/surrogate_key.rb
#
# This concern handles purge and purge_all calls to purge Fastly's edge cache.
# If Fastly has not been configured, these methods will short circuit and not be invoked.
module Purgeable
  extend ActiveSupport::Concern

  module ClassMethods
    def purge_all
      return if Rails.env.development?

      EdgeCache::PurgeByKey.call(table_key)
    end

    def soft_purge_all
      return if Rails.env.development?

      EdgeCache::PurgeByKey.call(table_key, soft: true)
    end

    def table_key
      table_name
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

    EdgeCache::PurgeByKey.call(record_key)
  end

  def soft_purge
    return if Rails.env.development?

    EdgeCache::PurgeByKey.call(record_key, soft: true)
  end

  def purge_all
    self.class.purge_all
  end

  def soft_purge_all
    self.class.soft_purge_all
  end
end
