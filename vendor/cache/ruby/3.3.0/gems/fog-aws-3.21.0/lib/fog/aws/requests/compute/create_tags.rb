module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Adds tags to resources
        #
        # ==== Parameters
        # * resources<~String> - One or more resources to tag
        # * tags<~String> - hash of key value tag pairs to assign
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateTags.html]
        def create_tags(resources, tags)
          resources = [*resources]
          for key, value in tags
            if value.nil?
              tags[key] = ''
            end
          end
          params = {}
          params.merge!(Fog::AWS.indexed_param('ResourceId', resources))
          params.merge!(Fog::AWS.indexed_param('Tag.%d.Key', tags.keys))
          params.merge!(Fog::AWS.indexed_param('Tag.%d.Value', tags.values))
          request({
            'Action'    => 'CreateTags',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::Basic.new
          }.merge!(params))
        end
      end

      class Mock
        def create_tags(resources, tags)
          resources = [*resources]
          tagged = tagged_resources(resources)

          tags.each do |key, value|
            self.data[:tags][key] ||= {}
            self.data[:tags][key][value] ||= []
            self.data[:tags][key][value] |= tagged

            tagged.each do |resource|
              self.data[:tag_sets][resource['resourceId']][key] = value
            end
          end

          response = Excon::Response.new
          response.status = 200
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'return'    => true
          }
          response
        end
      end
    end
  end
end
