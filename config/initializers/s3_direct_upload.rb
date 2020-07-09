S3DirectUpload.config do |c|
  c.access_key_id = ApplicationConfig["AWS_S3_VIDEO_ID"] # your access key id
  c.secret_access_key = ApplicationConfig["AWS_S3_VIDEO_KEY"] # your secret access key
  c.bucket = ApplicationConfig["AWS_S3_INPUT_BUCKET"] # your bucket name
  c.region = nil # region prefix. _Required_ for non-default AWS region, eg. "eu-west-1"
  c.url = nil # S3 API endpoint (optional), eg. "https://#{c.bucket}.s3.amazonaws.com"
end
