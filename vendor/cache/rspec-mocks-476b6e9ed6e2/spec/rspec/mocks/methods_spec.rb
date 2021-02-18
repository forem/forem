module RSpec
  module Mocks
    RSpec.describe "Methods added to every object" do
      include_context "with syntax", :expect

      def added_methods
        host = Class.new
        orig_instance_methods = host.instance_methods
        Syntax.enable_should(host)
        (host.instance_methods - orig_instance_methods).map(&:to_sym)
      end

      it 'limits the number of methods that get added to all objects' do
        # If really necessary, you can add to this list, but long term,
        # we are hoping to cut down on the number of methods added to all objects
        expect(added_methods).to match_array([
          :as_null_object, :null_object?,
          :received_message?, :should_not_receive, :should_receive,
          :stub, :stub_chain, :unstub
        ])
      end
    end
  end
end
