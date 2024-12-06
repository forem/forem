# frozen_string_literal: true

RSpec::Matchers.define :be_parsed_result_with do |front_matter, content|
  match do |result|
    result.front_matter == front_matter &&
      result.content == content
  end
end
