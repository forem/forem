# frozen_string_literal: true

module Stripe
  class APIResource < StripeObject
    include Stripe::APIOperations::Request

    # A flag that can be set a behavior that will cause this resource to be
    # encoded and sent up along with an update of its parent resource. This is
    # usually not desirable because resources are updated individually on their
    # own endpoints, but there are certain cases, replacing a customer's source
    # for example, where this is allowed.
    attr_accessor :save_with_parent

    def self.class_name
      name.split("::")[-1]
    end

    def self.resource_url
      if self == APIResource
        raise NotImplementedError,
              "APIResource is an abstract class. You should perform actions " \
              "on its subclasses (Charge, Customer, etc.)"
      end
      # Namespaces are separated in object names with periods (.) and in URLs
      # with forward slashes (/), so replace the former with the latter.
      "/v1/#{self::OBJECT_NAME.downcase.tr('.', '/')}s"
    end

    # A metaprogramming call that specifies that a field of a resource can be
    # its own type of API resource (say a nested card under an account for
    # example), and if that resource is set, it should be transmitted to the
    # API on a create or update. Doing so is not the default behavior because
    # API resources should normally be persisted on their own RESTful
    # endpoints.
    def self.save_nested_resource(name)
      define_method(:"#{name}=") do |value|
        super(value)

        # The parent setter will perform certain useful operations like
        # converting to an APIResource if appropriate. Refresh our argument
        # value to whatever it mutated to.
        value = send(name)

        # Note that the value may be subresource, but could also be a scalar
        # (like a tokenized card's ID for example), so we check the type before
        # setting #save_with_parent here.
        value.save_with_parent = true if value.is_a?(APIResource)

        value
      end
    end

    # Adds a custom method to a resource class. This is used to add support for
    # non-CRUDL API requests, e.g. capturing charges. custom_method takes the
    # following parameters:
    # - name: the name of the custom method to create (as a symbol)
    # - http_verb: the HTTP verb for the API request (:get, :post, or :delete)
    # - http_path: the path to append to the resource's URL. If not provided,
    #              the name is used as the path
    #
    # For example, this call:
    #     custom_method :capture, http_verb: post
    # adds a `capture` class method to the resource class that, when called,
    # will send a POST request to `/v1/<object_name>/capture`.
    def self.custom_method(name, http_verb:, http_path: nil)
      Util.custom_method self, self, name, http_verb, http_path
    end

    def resource_url
      unless (id = self["id"])
        raise InvalidRequestError.new(
          "Could not determine which URL to request: #{self.class} instance " \
          "has invalid ID: #{id.inspect}",
          "id"
        )
      end
      "#{self.class.resource_url}/#{CGI.escape(id)}"
    end

    def refresh
      resp, opts = execute_resource_request(:get, resource_url,
                                            @retrieve_params)
      initialize_from(resp.data, opts)
    end

    def self.retrieve(id, opts = {})
      opts = Util.normalize_opts(opts)
      instance = new(id, opts)
      instance.refresh
      instance
    end

    def request_stripe_object(method:, path:, params:, opts: {})
      resp, opts = execute_resource_request(method, path, params, opts)

      # If we're getting back this thing, update; otherwise, instantiate.
      if Util.object_name_matches_class?(resp.data[:object], self.class)
        initialize_from(resp.data, opts)
      else
        Util.convert_to_stripe_object(resp.data, opts)
      end
    end

    protected def request_stream(method:, path:, params:, opts: {},
                                 &read_body_chunk_block)
      resp, = execute_resource_request_stream(
        method, path, params, opts, &read_body_chunk_block
      )
      resp
    end
  end
end
