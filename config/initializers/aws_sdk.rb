::AwsLambda = Aws::Lambda::Client.new(
  region: ENV["AWS_DEFAULT_REGION"],
  access_key_id: ENV["AWS_SDK_KEY"],
  secret_access_key: ENV["AWS_SDK_SECRET"]
)