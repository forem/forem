module Cucumber
  # Cucumber 1 and 2
  # https://github.com/cucumber/cucumber-ruby/blob/v2.99.0/lib/cucumber/rb_support/rb_dsl.rb
  module RbSupport
    class RbDsl
      class << self
        def register_rb_hook(phase, tag_names, proc)
          proc.call
        end
      end
    end
  end

  # Cucumber 3
  # https://github.com/cucumber/cucumber-ruby/blob/v3.0.0/lib/cucumber/glue/dsl.rb
  module Glue
    class Dsl
      class << self
        def register_rb_hook(phase, tag_names, proc)
          proc.call
        end
      end
    end
  end
end
