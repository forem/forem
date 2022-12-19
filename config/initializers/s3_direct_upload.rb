# @forem/systems: We only can load this if video flow is entirely configured in AWS.
# Which is something we're currently punting on to rethink.
# As far as we know this only works and is supported on dev.to and not other forems.

S3DirectUpload.config do |c|
  if Rails.env.test?
    ENV["AWS_S3_VIDEO_ID"] = "available"
    ENV["AWS_S3_VIDEO_KEY"] = "available"
    ENV["AWS_S3_INPUT_BUCKET"] = "available"
  end
  c.access_key_id = ENV.fetch("AWS_S3_VIDEO_ID", nil) # your access key id
  c.secret_access_key = ENV.fetch("AWS_S3_VIDEO_KEY", nil) # your secret access key
  c.bucket = ENV.fetch("AWS_S3_INPUT_BUCKET", nil) # your bucket name
  c.region = nil # region prefix. _Required_ for non-default AWS region, eg. "eu-west-1"
  c.url = nil # S3 API endpoint (optional), eg. "https://#{c.bucket}.s3.amazonaws.com"
end
