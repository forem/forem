module Fog
  module AWS
    class Glacier
      class Real
        # Get the output from a job
        #
        # ==== Parameters
        # * name<~String> Name of the vault
        # * job_id<~String> The id of the job
        # * options<~Hash>
        #   * Range<~Range> The range to retrieve
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        #   * response_block<~Proc> Proc to use for streaming the response
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-job-output-get.html
        #
        def get_job_output(vault_name, job_id, options={})
          account_id = options.delete('account_id') || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(vault_name)}/jobs/#{job_id}/output"
          headers = {}
          if range = options.delete('Range')
            headers['Range'] = "bytes=#{range.begin}-#{range.end}"
          end
          request(
            options.merge(
            :expects  => [200,206],
            :idempotent => true,
            :headers => headers,
            :method   => :get,
            :path     => path
          ))
        end
      end
    end
  end
end
