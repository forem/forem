module Fog
  module AWS
    class IAM
      class Mock
        def self.default_policies
          Fog::JSON.decode(File.read(File.expand_path("../default_policies.json", __FILE__)))
        end

        def self.default_policy_versions
          Fog::JSON.decode(File.read(File.expand_path("../default_policy_versions.json", __FILE__)))
        end
      end
    end
  end
end
