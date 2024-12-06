class Fastly
  # Acces Control List configuration
  class ACL < BelongsToServiceAndVersion
    attr_accessor :id, :service_id, :name

    ##
    # :attr: service_id
    #
    # The id of the service this belongs to.

    ##
    # :attr: version
    #
    # The number of the version this belongs to.

    ##
    # :attr: name
    #
    # The name for the ACL.

    ##
    # List ACL entries that belong to the ACL
    def list_entries
      fetcher.list_acl_entries(:service_id => service_id, :acl_id => id)
    end

    ##
    # Create an ACL entry and add it to the ACL
    #
    def create_entry(opts = {})
      fetcher.create_acl_entry(
        service_id: service_id,
        acl_id: id,
        ip: opts[:ip],
        negated: opts[:negated],
        subnet: opts[:subnet],
        comment: opts[:comment]
      )
    end

    ##
    # Retrieve an ACL entry
    #
    def get_entry(entry_id)
      fetcher.get_acl_entry(service_id, id, entry_id)
    end

    ##
    # Update an ACL entry
    #
    def update_entry(entry)
      fetcher.update_acl_entry(entry)
    end

    ##
    # Delete an ACL entry
    #
    def delete_entry(entry)
      fetcher.delete_acl_entry(entry)
    end
  end
end
