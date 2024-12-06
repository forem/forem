# frozen_string_literal: true

RubyNext::Core.patch MatchData, method: :match, version: "3.1" do
  <<-RUBY
def match(index_or_name)
  self[index_or_name]
end
  RUBY
end
