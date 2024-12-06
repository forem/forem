# frozen_string_literal: true

RubyNext::Core.patch Enumerable, method: :filter, version: "2.6" do
  <<-RUBY
alias filter select
  RUBY
end

# Refine Array seprately, 'cause refining modules is vulnerable to prepend:
# - https://bugs.ruby-lang.org/issues/13446
#
# Also, Array also have `filter!`
RubyNext::Core.patch Array, method: :filter!, version: "2.6" do
  <<-RUBY
alias filter select
alias filter! select!
  RUBY
end

RubyNext::Core.patch Hash, method: :filter!, version: "2.6" do
  <<-RUBY
alias filter select
alias filter! select!
  RUBY
end
