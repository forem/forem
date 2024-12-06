module Fog
  module AWS
    class Glacier
      class Real
        # This operation initates a multipart upload of an archive to a vault
        #
        # ==== Parameters
        # * name<~String> The vault name
        # * job_specification<~Hash> A specification of the job
        #    * Type<~String> The job type. Mandatory. Values: archive-retrieval, inventory-retrieval
        #    * Description<~String> The job description
        #    * ArchiveId<~String> The id of the archive to retrieve (only for Type==archive-retrieval)
        #    * Format<~String> The format to return (only for inventory retrieval). Values: CSV, JSON
        #    * SNSTopic<String> ARN of a topic to publish to when the job is complete
        # * options<~Hash>
        #   * account_id<~String> - The AWS account id. Defaults to the account owning the credentials making the request
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-initiate-job-post.html
        #
        def initiate_job(name, job_specification, options={})
          account_id = options['account_id'] || '-'
          path = "/#{account_id}/vaults/#{Fog::AWS.escape(name)}/jobs"

          request({
            :expects  => 202,
            :headers => {},
            :method   => 'POST',
            :path     => path,
            :body     => Fog::JSON.encode(job_specification)
          })
        end
      end
    end
  end
end
