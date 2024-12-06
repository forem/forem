module PgQuery
  # Patch the auto-generated generic node type with additional convenience functions
  class Node
    def inspect
      node ? format('<PgQuery::Node: %s: %s>', node, public_send(node).inspect) : '<PgQuery::Node>'
    end

    # Make it easier to initialize nodes from a given node child object
    def self.from(node_field_val)
      # This needs to match libpg_query naming for the Node message field names
      # (see "underscore" method in libpg_query's scripts/generate_protobuf_and_funcs.rb)
      node_field_name = node_field_val.class.name.split('::').last
      node_field_name.gsub!(/^([A-Z\d])([A-Z][a-z])/, '\1__\2')
      node_field_name.gsub!(/([A-Z\d]+[a-z]+)([A-Z][a-z])/, '\1_\2')
      node_field_name.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      node_field_name.tr!('-', '_')
      node_field_name.downcase!

      PgQuery::Node.new(node_field_name => node_field_val)
    end

    # Make it easier to initialize value nodes
    def self.from_string(sval)
      PgQuery::Node.new(string: PgQuery::String.new(sval: sval))
    end

    def self.from_integer(ival)
      PgQuery::Node.new(integer: PgQuery::Integer.new(ival: ival))
    end
  end
end
