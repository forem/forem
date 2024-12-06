require 'fog/aws/models/elb/backend_server_description'
module Fog
  module AWS
    class ELB
      class BackendServerDescriptions < Fog::Collection
        model Fog::AWS::ELB::BackendServerDescription

        attr_accessor :data, :load_balancer

        def all
          load(data)
        end

        def get(instance_port)
          all.find { |e| e.instance_port == instance_port }
        end
      end
    end
  end
end
