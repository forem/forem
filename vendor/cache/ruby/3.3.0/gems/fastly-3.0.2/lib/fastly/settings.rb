# Settings Object
class Fastly
  # Represent arbitary key value settings for a given Version
  class Settings < Base
    attr_accessor :service_id, :version, :settings
    ##
    # :attr: service_id
    #
    # The id of the service this belongs to.
    #

    ##
    # :attr: version
    #
    # The number of the version this belongs to.
    #

    ##
    # :attr: service
    #
    # Return a hash containing key/value pairs of settings
    #

    # :nodoc:
    def self.get_path(service, number)
      "/service/#{service}/version/#{number}/settings"
    end

    # :nodoc:
    def self.put_path(obj)
      get_path(obj.service_id, obj.version)
    end

    # :nodoc:
    def self.list_path(_opts = {})
      nil
    end

    # :nodoc:
    def self.post_path
      fail "You can't POST to an setting"
    end

    # :nodoc:
    def self.delete_path
      fail "You can't DELETE to an setting"
    end

    # :nodoc:
    def delete!
      fail "You can't delete an invoice"
    end

    # :nodoc:
    def as_hash
      settings
    end
  end

  # Get the Settings object for the specified Version
  def get_settings(service, number)
    hash = client.get(Settings.get_path(service, number))
    return nil if hash.nil?

    hash['settings'] = Hash[['general.default_host', 'general.default_ttl'].collect { |var| [var, hash.delete(var)] }]
    Settings.new(hash, self)
  end

  # Update the Settings object for the specified Version
  def update_settings(opts = {})
    update(Settings, opts)
  end
end
