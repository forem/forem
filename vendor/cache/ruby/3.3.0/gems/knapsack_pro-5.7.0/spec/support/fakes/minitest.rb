# https://github.com/seattlerb/minitest/blob/master/lib/minitest/test.rb
module Minitest
  class Test
    def before_setup; end
    def after_teardown; end
  end

  class Runnable
    def self.reset; end
  end

  # https://github.com/seattlerb/minitest/blob/master/lib/minitest.rb
  def self.after_run(&block)
    block.call
  end

  def self.run(args); end
end
