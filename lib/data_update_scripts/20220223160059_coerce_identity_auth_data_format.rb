module DataUpdateScripts
  class CoerceIdentityAuthDataFormat
    def run
      Identity.with_statement_timeout(5.minutes) do
        Identity.where("auth_data_dump ~ '^---\n'").find_each do |identity|
          auth_hash = OmniAuth::AuthHash.new(**identity.auth_data_dump)
          identity.update_columns(auth_data_dump: auth_hash)
        end
      end
    end
  end
end
