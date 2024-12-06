module Shindo
  class Tests
    def succeeds(&block)
      test("succeeds") do
        !!instance_eval(&block)
      end
    end
  end
end
