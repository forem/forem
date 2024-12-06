class Fastly
  # A Customer account
  class Customer < Base
    attr_accessor :billing_contact_id, :id, :legal_contact_id, :name,
                  :owner_id, :security_contact_id, :technical_contact_id

    ##
    # :attr: billing_contact_id
    #
    # The id of the user to be contacted for billing issues.

    ##
    # :attr: id
    #
    # The id of this customer

    ##
    # :attr: legal_contact_id
    #
    # The id of the user to be contacted for legal issues.

    ##
    # :attr: name
    #
    # The name of this customer

    ##
    # :attr: owner_id
    #
    # The id of the user that owns this customer

    ##
    # :attr: security_contact_id
    #
    # The id of the user to be contacted for security issues.

    ##
    # :attr: technical_contact_id
    #
    # The id of the user to be contacted for technical issues.

    ##
    # The billing contact as a Fastly::User
    def billing_contact
      get_user billing_contact_id
    end

    ##
    # The legal contact as a Fastly::User
    def legal_contact
      get_user legal_contact_id
    end

    ##
    # The account owner as a Fastly::User
    def owner
      get_user owner_id
    end

    ##
    # The security contact as a Fastly::User
    def security_contact
      get_user security_contact_id
    end

    ##
    # The technical contact as a Fastly::User
    def technical_contact
      get_user technical_contact_id
    end

    private

    def get_user(id)
      id ? fetcher.get(User, id) : nil
    end
  end
end
