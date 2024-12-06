# frozen_string_literal: true

RubyNext::Core.patch Struct, method: :deconstruct, version: "2.7" do
  <<-RUBY
alias deconstruct to_a
  RUBY
end
