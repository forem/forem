module Fog
  module AWS
    class ELB
      class BackendServerDescription < Fog::Model
        attribute :policy_names,      :aliases => 'PolicyNames'
        attribute :instance_port,     :aliases => 'InstancePort'
      end
    end
  end
end
