class Fastly
  # A representation of a User in Fastly
  class User < Base
    attr_accessor :id, :name, :login, :customer_id, :role, :password
    ##
    # :attr: id
    #
    # The id of this user
    #

    ##
    # :attr: name
    #
    # The name of this user
    #

    ##
    # :attr: customer_id
    #
    # The id of the customer this user belongs to
    #

    ##
    # :attr: role
    #
    # The role this user has (one of admin, owner, superuser, user, engineer, billing)

    # Get the Customer object this user belongs to
    def customer
      @customer ||= fetcher.get(Customer, customer_id)
    end

    # Whether or not this User is the owner of the Customer they belong to
    def owner?
      customer.owner_id == id
    end

    # :nodoc:
    PRIORITIES = {
      :admin      => 1,
      :owner      => 10,
      :superuser  => 10,
      :user       => 20,
      :engineer   => 30,
      :billing    => 30
    }

    # Does this User have sufficient permissions to perform the given role
    def can_do?(test_role)
      test_priority = PRIORITIES[test_role.to_sym] || 1000
      my_priority = PRIORITIES[role.to_sym] || 1000

      if test_priority == my_priority
        test_role.to_s == :owner ? owner? : test_role.to_sym == role.to_sym
      else
        my_priority < test_priority
      end
    end
  end
end
