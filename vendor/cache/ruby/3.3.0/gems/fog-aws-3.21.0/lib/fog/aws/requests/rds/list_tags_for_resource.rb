module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/tag_list_parser'

        # returns a Hash of tags for a database instance
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_ListTagsForResource.html
        # ==== Parameters
        # * rds_id <~String> - name of the RDS instance whose tags are to be retrieved
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:

        def list_tags_for_resource(rds_id)
          resource_name = "arn:aws:rds:#{@region}:#{owner_id}:db:#{rds_id}"
          %w[us-gov-west-1 us-gov-east-1].include?(@region) ? resource_name.insert(7, '-us-gov') : resource_name
          request(
            'Action' => 'ListTagsForResource',
            'ResourceName' => resource_name,
            :parser => Fog::Parsers::AWS::RDS::TagListParser.new
          )
        end
      end

      class Mock
        def list_tags_for_resource(rds_id)
          response = Excon::Response.new
          if server = data[:servers][rds_id]
            response.status = 200
            response.body = {
              'ListTagsForResourceResult' =>
                { 'TagList' => data[:tags][rds_id] }
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
