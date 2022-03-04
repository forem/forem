module WithinBlockIsExpected
  def within_block_is_expected
    expect { subject }
  end
end

RSpec.configure do |config|
  config.include WithinBlockIsExpected
end
