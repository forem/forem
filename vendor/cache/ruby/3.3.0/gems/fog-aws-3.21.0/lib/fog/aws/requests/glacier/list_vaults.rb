module Fog
  module AWS
    class Glacier
      class Real
        # This operation lists all vaults owned by the calling user’s account.
        #
        # ==== Parameters
        # * options<~Hash>
        #   * limit<~Integer> - The maximum number of items returned in the response. (default 1000)
        #   * marker<~String> - marker used for pagination
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vaults-get.html
        #
        def list_vaults(options={})
          account_id = options.delete('account_id') || '-'
          path = "/#{account_id}/vaults"
          request(
            :expects  => 200,
            :idempotent => true,
            :headers => {},
            :method   => 'GET',
            :path     => path,
            :query => options
          )
        end
      end
    end
  end
end
