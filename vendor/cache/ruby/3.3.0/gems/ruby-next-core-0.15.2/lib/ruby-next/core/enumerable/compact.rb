# frozen_string_literal: true

RubyNext::Core.patch Enumerable, method: :compact, version: "3.1" do
  <<-RUBY
def compact
  reduce([]) do |acc, val|
    acc << val unless val.nil?
    acc
  end
end
  RUBY
end

RubyNext::Core.patch Enumerator::Lazy, method: :compact, version: "3.1" do
  <<-RUBY
def compact
  Enumerator::Lazy.new(self) do |yielder, value|
    yielder << value unless value.nil?
  end
end
  RUBY
end
