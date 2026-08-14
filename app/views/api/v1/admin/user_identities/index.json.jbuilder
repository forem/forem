json.identities(@identities) do |identity|
  json.partial!("api/v1/admin/user_identities/identity", identity: identity)
end
