require 'fog/aws/models/elb/listener'
module Fog
  module AWS
    class ELB
      class Listeners < Fog::Collection
        model Fog::AWS::ELB::Listener

        attr_accessor :data, :load_balancer

        def all
          load(munged_data)
        end

        def get(lb_port)
          all.find { |listener| listener.lb_port == lb_port }
        end

        private

        # Munge an array of ListenerDescription hashes like:
        # {'Listener' => listener, 'PolicyNames' => []}
        # to an array of listeners with a PolicyNames key
        def munged_data
          data.map { |description| description['Listener'].merge('PolicyNames' => description['PolicyNames']) }
        end
      end
    end
  end
end
