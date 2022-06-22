# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

# API Versioning MIME Types - Read more:
# - https://jsonapi.org/#mime-types
# - https://www.iana.org/assignments/media-types/application/vnd.api+json
Mime::Type.register "application/vnd.forem.api-v0+json", :api_v0
Mime::Type.register "application/vnd.forem.api-v1+json", :api_v1
