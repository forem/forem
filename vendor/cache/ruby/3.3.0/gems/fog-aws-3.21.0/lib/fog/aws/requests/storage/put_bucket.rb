module Fog
  module AWS
    class Storage
      class Real
        # Create an S3 bucket
        #
        # @param bucket_name [String] name of bucket to create
        # @option options [Hash] config arguments for bucket.  Defaults to {}.
        # @option options LocationConstraint [Symbol] sets the location for the bucket
        # @option options x-amz-acl [String] Permissions, must be in ['private', 'public-read', 'public-read-write', 'authenticated-read']
        #
        # @return [Excon::Response] response:
        #   * status [Integer] 200
        #
        # @see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
        #
        def put_bucket(bucket_name, options = {})
          if location_constraint = options.delete('LocationConstraint')
            data =
<<-DATA
  <CreateBucketConfiguration>
    <LocationConstraint>#{location_constraint}</LocationConstraint>
  </CreateBucketConfiguration>
DATA
          else
            data = nil
          end
          request({
            :expects    => 200,
            :body       => data,
            :headers    => options,
            :idempotent => true,
            :bucket_name => bucket_name,
            :method     => 'PUT'
          })
        end
      end

      class Mock # :nodoc:all
        def put_bucket(bucket_name, options = {})
          acl = options['x-amz-acl'] || 'private'
          if !['private', 'public-read', 'public-read-write', 'authenticated-read'].include?(acl)
            raise Excon::Errors::BadRequest.new('invalid x-amz-acl')
          else
            self.data[:acls][:bucket][bucket_name] = self.class.acls(acl)
          end

          response = Excon::Response.new
          response.status = 200
          bucket = {
            :objects        => {},
            'Name'          => bucket_name,
            'CreationDate'  => Time.now,
            'Owner'         => { 'DisplayName' => 'owner', 'ID' => 'some_id'},
            'Payer'         => 'BucketOwner'
          }
          if options['LocationConstraint']
            bucket['LocationConstraint'] = options['LocationConstraint']
          else
            bucket['LocationConstraint'] = nil
          end
          if !self.data[:buckets][bucket_name]
            self.data[:buckets][bucket_name] = bucket
          elsif self.region != 'us-east-1'
            response.status = 409
            Fog::Logger.warning "Your region '#{self.region}' does not match the default region 'us-east-1'"
            raise(Excon::Errors.status_error({:expects => 201}, response))
          end
          response
        end
      end
    end
  end
end
