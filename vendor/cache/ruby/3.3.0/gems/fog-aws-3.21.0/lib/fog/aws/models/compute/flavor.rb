module Fog
  module AWS
    class Compute
      class Flavor < Fog::Model
        identity :id

        attribute :bits
        attribute :cores
        attribute :disk
        attribute :name
        attribute :ram
        attribute :ebs_optimized_available
        attribute :instance_store_volumes
      end
    end
  end
end
