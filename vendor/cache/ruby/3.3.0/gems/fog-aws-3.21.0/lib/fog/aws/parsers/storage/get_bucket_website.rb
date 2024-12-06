module Fog
  module Parsers
    module AWS
      module Storage

        # http://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
        class GetBucketWebsite < Fog::Parsers::Base
          def reset
            @response = { 'ErrorDocument' => {}, 'IndexDocument' => {}, 'RedirectAllRequestsTo' => {} }
          end

          def end_element(name)
            case name
            when 'Key'
              @response['ErrorDocument'][name] = value
            when 'Suffix'
              @response['IndexDocument'][name] = value
            when 'HostName'
              @response['RedirectAllRequestsTo'][name] = value
            end
          end
        end
      end
    end
  end
end
