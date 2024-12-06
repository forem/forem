# frozen_string_literal: true

RubyNext::Core.patch Object,
  name: "FrozenError",
  method: nil,
  refineable: [],
  version: "2.5",
  # avoid defining the constant twice, 'causae it's already included in core
  # we only use the contents in `ruby-next core_ext`.
  supported: true,
  location: [__FILE__, __LINE__ + 2] do
  <<-RUBY
FrozenError ||= RuntimeError
  RUBY
end
