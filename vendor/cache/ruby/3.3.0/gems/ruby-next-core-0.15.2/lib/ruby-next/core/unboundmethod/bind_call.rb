# frozen_string_literal: true

RubyNext::Core.patch UnboundMethod, method: :bind_call, version: "2.7" do
  <<-RUBY
def bind_call(receiver, *args, &block)
  bind(receiver).call(*args, &block)
end
  RUBY
end
