module Fog
  module AWS
    class RDS
      class Real
        # removes tags from a database instance
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_RemoveTagsFromResource.html
        # ==== Parameters
        # * rds_id <~String> - name of the RDS instance whose tags are to be retrieved
        # * keys <~Array> A list of String keys for the tags to remove
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def remove_tags_from_resource(rds_id, keys)
          resource_name = "arn:aws:rds:#{@region}:#{owner_id}:db:#{rds_id}"
          %w[us-gov-west-1 us-gov-east-1].include?(@region) ? resource_name.insert(7, '-us-gov') : resource_name
          request(
            { 'Action' => 'RemoveTagsFromResource',
              'ResourceName' => resource_name,
              :parser => Fog::Parsers::AWS::RDS::Base.new }.merge(Fog::AWS.indexed_param('TagKeys.member.%d', keys))
          )
        end
      end

      class Mock
        def remove_tags_from_resource(rds_id, keys)
          response = Excon::Response.new
          if server = data[:servers][rds_id]
            keys.each { |key| data[:tags][rds_id].delete key }
            response.status = 200
            response.body = {
              'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
            }
            response
          else
            raise Fog::AWS::RDS::NotFound, "DBInstance #{rds_id} not found"
          end
        end
      end
    end
  end
end
