module Cloudinary::Cache
  class BreakpointsCache
    attr_accessor :adapter

    def set(public_id, options, value)
      upload_type, resource_type, transformation, format = options_to_parameters(options)
      @adapter.set(public_id, upload_type, resource_type, transformation, format, value)

    end

    def fetch(public_id, options)
      upload_type, resource_type, transformation, format = options_to_parameters(options)
      @adapter.set(public_id, upload_type, resource_type, transformation, format, &Proc.new)

    end

    def get(public_id, options)
      upload_type, resource_type, transformation, format = options_to_parameters(options)
      @adapter.get(public_id, upload_type, resource_type, transformation, format)
    end

    def options_to_parameters(options)
      options = Cloudinary::Utils.symbolize_keys options
      transformation = Cloudinary::Utils.generate_transformation_string(options)
      upload_type = options[:type] || 'upload'
      resource_type = options[:resource_type] || 'image'
      format = options[:format] || ""
      [upload_type, resource_type, transformation, format]
    end
  end
end