# frozen_string_literal: true

# Special patch to define the error constant in generated files
RubyNext::Core.patch Object,
  name: "NoMatchingPatternError",
  method: nil,
  refineable: [],
  version: "2.7",
  # avoid defining the constant twice, 'causae it's already included in core
  # we only use the contents in `ruby-next core_ext`.
  supported: true,
  location: [__FILE__, __LINE__ + 2] do
  <<-RUBY
class NoMatchingPatternError < StandardError
end
  RUBY
end
