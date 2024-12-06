# frozen_string_literal: true

RubyNext::Core.patch Symbol, method: :end_with?, version: "2.7" do
  <<-RUBY
def end_with?(*prefixes)
  to_s.end_with?(*prefixes)
end
  RUBY
end
