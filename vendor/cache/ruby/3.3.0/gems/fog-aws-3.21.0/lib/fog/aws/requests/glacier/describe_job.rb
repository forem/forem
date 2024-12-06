module Fog
  module AWS
    class Glacier
      class Real
        # Complete an upload
        #
        # ==== Parameters
        # * name<~String> Name of the vault
        # * job_id<~String> The id of the job
        # * options<~Hash>
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-describe-job-get.html
        #
        def describe_job(vault_name, job_id, options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(vault_name)}/jobs/#{job_id}"

          request(
            :expects  => 200,
            :idempotent => true,
            :headers => {},
            :method   => :get,
            :path     => path
          )
        end
      end
    end
  end
end
