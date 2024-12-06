require 'test_helper'

# Fastly Util class tests
class Fastly
  class FooBar; end
  class FooBarBaz; end
  describe Util do
    describe '.class_to_path' do
      let(:klass)        { Fastly::FooBar }
      let(:klass_with_s) { Fastly::FooBarBaz }

      it 'should convert a class name to an underscored path' do
        assert_equal 'foo_bar', Util.class_to_path(klass)
      end

      it 'should append an s if second argument is true' do
        assert_equal 'foo_bar_bazs', Util.class_to_path(klass_with_s, true)
      end
    end
  end
end
