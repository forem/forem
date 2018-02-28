json.array!(@blocks) do |block|
  json.extract! block, :id
  json.url block_url(block, format: :json)
end
