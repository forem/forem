# frozen_string_literal: true

RubyNext::Core.patch Integer.singleton_class, method: :try_convert, singleton: Integer, version: "3.1" do
  <<-'RUBY'
def try_convert(val)
  return val if val.is_a?(Integer)

  if val.respond_to?(:to_int)
    val.to_int.tap do |res|
      next if res.is_a?(Integer) || res.nil?
      raise TypeError, "Can't convert #{res.class} to Integer"
    end
  end
end
  RUBY
end
