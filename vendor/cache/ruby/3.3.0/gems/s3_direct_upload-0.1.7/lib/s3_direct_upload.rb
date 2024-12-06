require 's3_direct_upload/version'
require 'jquery-fileupload-rails' if defined?(Rails)

require 'base64'
require 'openssl'
require 'digest/sha1'

require 's3_direct_upload/config_aws'
require 's3_direct_upload/form_helper'
require 's3_direct_upload/engine' if defined?(Rails)
require 's3_direct_upload/railtie' if defined?(Rails)

ActionView::Base.send(:include, S3DirectUpload::UploadHelper) if defined?(ActionView::Base)
