require 'digest'

module Cloudinary
  module Cache

    class << self
      attr_accessor :storage

      def get(public_id, options)
        if block_given?
          storage.read(generate_cache_key(public_id, options)) {yield}
        else
          storage.read(generate_cache_key(public_id, options))
        end
      end

      def set(public_id, options, value)
        storage.write(generate_cache_key(public_id, options), value)
      end

      alias_method :fetch, :get

      def flush_all
        storage.clear
      end

      private

      def generate_cache_key(public_id, options)
        type = options[:type] || "upload"
        resource_type = options[:resource_type] || "image"
        transformation = Cloudinary::Utils.generate_transformation_string options.clone
        format = options[:format]
        Digest::SHA1.hexdigest [public_id, type, resource_type, transformation, format].reject(&:blank?).join('/')
      end
    end
  end
end