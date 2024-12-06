# frozen_string_literal: true

RubyNext::Core.patch Symbol, method: :start_with?, version: "2.7" do
  <<-RUBY
def start_with?(*prefixes)
  to_s.start_with?(*prefixes)
end
  RUBY
end
