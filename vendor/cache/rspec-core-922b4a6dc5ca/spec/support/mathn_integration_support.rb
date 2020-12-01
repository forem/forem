require 'rspec/support/spec/in_sub_process'

module MathnIntegrationSupport
  include RSpec::Support::InSubProcess

  if RUBY_VERSION.to_f >= 2.2
    def with_mathn_loaded
      skip "lib/mathn.rb is deprecated in Ruby 2.2"
    end
  elsif RUBY_VERSION.to_f < 1.9
    def with_mathn_loaded
      in_sub_process do
        expect { require 'mathn' }.to output.to_stderr
        yield
      end
    end
  else
    def with_mathn_loaded
      in_sub_process do
        require 'mathn'
        yield
      end
    end
  end
end
