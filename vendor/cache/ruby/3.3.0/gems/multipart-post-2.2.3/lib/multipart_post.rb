warn "Top level ::MultipartPost is deprecated, require 'multipart/post' and use `Multipart::Post` instead!"
require_relative 'multipart/post'
MultipartPost = Multipart::Post
