# Service object
class Fastly
  # Represents something you want to serve - this can be, for example, a whole web site, a Wordpress site, or just your image servers
  class Service < Base
    attr_accessor :id, :customer_id, :name, :comment
    attr_writer :versions

    @versions = []

    ##
    # :attr: id
    #
    # The id of the service
    #

    ##
    # :attr: customer_id
    #
    # The id of the customer this belongs to
    #

    ##
    # :attr: name
    #
    # The name of this service
    #

    ##
    # :attr: comment
    #
    # a free form comment field

    ##
    #
    # Get a hash of stats from different data centers.
    #
    # Type is always :all (argument is ignored)
    def stats(_type = :all, opts = {})
      fetcher.client.get("#{Service.get_path(id)}/stats/summary", opts)
    end

    # Return a Invoice object representing the invoice for this service
    #
    # If a year and month are passed in returns the invoice for that whole month.
    #
    # Otherwise it returns the invoice for the current month so far.
    def invoice(year = nil, month = nil)
      opts = { service_id: id }

      unless year.nil? || month.nil?
        opts[:year]  = year
        opts[:month] = month
      end

      fetcher.get(Invoice, opts)
    end

    # Purge all assets from this service.
    #
    # See README.md for examples of purging
    def purge_all
      fetcher.client.post("#{Service.get_path(id)}/purge_all")
    end

    # Purge anything with the specific key from the given service.
    #
    # See README.md for examples of purging
    def purge_by_key(key, soft=false)
      require_api_key!
      fetcher.client.post("#{Service.get_path(id)}/purge/#{key}", soft ? { headers: { 'Fastly-Soft-Purge' => "1"} } : {})
    end

    # Get a sorted array of all the versions that this service has had.
    def versions
      @versions.map { |v| Version.new(v, fetcher) }.sort { |a, b| a.number.to_i <=> b.number.to_i }
    end

    # Get an individual Version object. By default returns the latest version
    def version(number = -1)
      versions[number]
    end

    # A deep hash of nested details
    def details(opts = {})
      fetcher.client.get("#{Service.get_path(id)}/details", opts)
    end

    # Get the Customer object for this Service
    def customer
      fetcher.get(Customer, customer_id)
    end
  end

  # Search all the services that the current customer has.
  #
  # In general you'll want to do
  #
  #   services = fastly.search_services(:name => name)
  #
  # or
  #
  #   service = fastly.search_services(:name => name, :version => number)
  def search_services(opts)
    hash = client.get("#{Service.post_path}/search", opts)
    hash.nil? ? nil : Service.new(hash, self)
  end
end
