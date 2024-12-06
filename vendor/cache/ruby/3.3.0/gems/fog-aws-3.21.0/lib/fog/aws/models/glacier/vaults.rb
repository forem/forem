require 'fog/aws/models/glacier/vault'

module Fog
  module AWS
    class Glacier
      class Vaults < Fog::Collection
        model Fog::AWS::Glacier::Vault

        def all
          data = service.list_vaults.body['VaultList']
          load(data)
        end

        def get(key)
          data = service.describe_vault(key).body
          new(data)
        rescue Excon::Errors::NotFound
          nil
        end
      end
    end
  end
end
