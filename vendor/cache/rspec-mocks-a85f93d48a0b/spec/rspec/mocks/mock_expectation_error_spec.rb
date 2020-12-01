module RSpec
  module Mocks
    RSpec.describe 'MockExpectationError' do

      class Foo
        def self.foo
          bar
        rescue StandardError
        end
      end

      it 'is not caught by StandardError rescue blocks' do
        expect(Foo).not_to receive(:bar)

        expect_fast_failure_from(Foo) do
          Foo.foo
        end
      end
    end
  end
end
