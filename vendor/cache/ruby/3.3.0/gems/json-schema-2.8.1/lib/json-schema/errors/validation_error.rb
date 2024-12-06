module JSON
  class Schema
    class ValidationError < StandardError
      INDENT = "    "
      attr_accessor :fragments, :schema, :failed_attribute, :sub_errors, :message

      def initialize(message, fragments, failed_attribute, schema)
        @fragments = fragments.clone
        @schema = schema
        @sub_errors = {}
        @failed_attribute = failed_attribute
        @message = message
        super(message_with_schema)
      end

      def to_string(subschema_level = 0)
        if @sub_errors.empty?
          subschema_level == 0 ? message_with_schema : message
        else
          messages = ["#{message}. The schema specific errors were:\n"]
          @sub_errors.each do |subschema, errors|
            messages.push "- #{subschema}:"
            messages.concat Array(errors).map { |e| "#{INDENT}- #{e.to_string(subschema_level + 1)}" }
          end
          messages.map { |m| (INDENT * subschema_level) + m }.join("\n")
        end
      end

      def to_hash
        base = {:schema => @schema.uri, :fragment => ::JSON::Schema::Attribute.build_fragment(fragments), :message => message_with_schema, :failed_attribute => @failed_attribute.to_s.split(":").last.split("Attribute").first}
        if !@sub_errors.empty?
          base[:errors] = @sub_errors.inject({}) do |hsh, (subschema, errors)|
            subschema_sym = subschema.downcase.gsub(/\W+/, '_').to_sym
            hsh[subschema_sym] = Array(errors).map{|e| e.to_hash}
            hsh
          end
        end
        base
      end

      def message_with_schema
        "#{message} in schema #{schema.uri}"
      end
    end
  end
end
