require 'fog/aws/models/sns/topic'

module Fog
  module AWS
    class SNS
      class Topics < Fog::Collection
        model Fog::AWS::SNS::Topic

        def all
          data = service.list_topics.body["Topics"].map { |t| {"id" => t} } #This is an array, but it needs to be an array of hashes for #load

          load(data)
        end

        def get(id)
          if data = service.get_topic_attributes(id).body["Attributes"]
            new(data)
          end
        end
      end
    end
  end
end
