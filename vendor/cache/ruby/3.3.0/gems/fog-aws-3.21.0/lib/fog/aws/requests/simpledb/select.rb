module Fog
  module AWS
    class SimpleDB
      class Real
        require 'fog/aws/parsers/simpledb/select'

        # Select item data from SimpleDB
        #
        # ==== Parameters
        # * select_expression<~String> - Expression to query domain with.
        # * options<~Hash>:
        #   * ConsistentRead<~Boolean> - When set to true, ensures most recent data is returned. Defaults to false.
        #   * NextToken<~String> - Offset token to start list, defaults to nil.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'BoxUsage'<~Float>
        #     * 'RequestId'<~String>
        #     * 'Items'<~Hash> - list of attribute name/values for the items formatted as
        #       { 'item_name' => { 'attribute_name' => ['attribute_value'] }}
        #     * 'NextToken'<~String> - offset to start with if there are are more domains to list
        def select(select_expression, options = {})
          if options.is_a?(String)
            Fog::Logger.deprecation("get_attributes with string next_token param is deprecated, use 'AttributeName' => attributes) instead [light_black](#{caller.first})[/]")
            options = {'NextToken' => options}
          end
          options['NextToken'] ||= nil
          request(
            'Action'            => 'Select',
            'ConsistentRead'    => !!options['ConsistentRead'],
            'NextToken'         => options['NextToken'],
            'SelectExpression'  => select_expression,
            :idempotent         => true,
            :parser             => Fog::Parsers::AWS::SimpleDB::Select.new(@nil_string)
          )
        end
      end
    end
  end
end
