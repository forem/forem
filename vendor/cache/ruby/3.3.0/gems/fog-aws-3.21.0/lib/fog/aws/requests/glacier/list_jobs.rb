module Fog
  module AWS
    class Glacier
      class Real
        #  lists in-progress and recently jobs for the specified vault
        #
        # ==== Parameters
        # * name<~String> Name of the vault
        # * options<~Hash>
        #   * completed<~Boolean>Specifies the state of the jobs to return. You can specify true or false
        #   * statuscode<~String> Filter returned jobs by status (InProgress, Succeeded, or Failed)
        #   * limit<~Integer> - The maximum number of items returned in the response. (default 1000)
        #   * marker<~String> - marker used for pagination
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        # ==== See Also
        #http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-jobs-get.html
        #
        def list_jobs(vault_name, options={})
          account_id = options.delete('account_id') || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(vault_name)}/jobs"

          request(
            :expects  => 200,
            :idempotent => true,
            :headers => {},
            :method   => :get,
            :path     => path,
            :query => options
          )
        end
      end
    end
  end
end
