Doorkeeper.configure do
  # hash_token_secrets on its own won't work in test
  hash_token_secrets fallback: :plain
end
