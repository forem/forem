require 'flipper/typecast'

RSpec.describe Flipper::Typecast do
  {
    nil => false,
    '' => false,
    0 => false,
    1 => true,
    '0' => false,
    '1' => true,
    true => true,
    false => false,
    'true' => true,
    'false' => false,
  }.each do |value, expected|
    context "#to_boolean for #{value.inspect}" do
      it "returns #{expected}" do
        expect(described_class.to_boolean(value)).to be(expected)
      end
    end
  end

  {
    nil => 0,
    '' => 0,
    0 => 0,
    1 => 1,
    '1' => 1,
    '99' => 99,
  }.each do |value, expected|
    context "#to_integer for #{value.inspect}" do
      it "returns #{expected}" do
        expect(described_class.to_integer(value)).to be(expected)
      end
    end
  end

  {
    nil => 0.0,
    '' => 0.0,
    0 => 0.0,
    1 => 1.0,
    1.1 => 1.1,
    '0.01' => 0.01,
    '1' => 1.0,
    '99' => 99.0,
  }.each do |value, expected|
    context "#to_float for #{value.inspect}" do
      it "returns #{expected}" do
        expect(described_class.to_float(value)).to be(expected)
      end
    end
  end

  {
    nil => 0,
    '' => 0,
    0 => 0,
    0.0 => 0.0,
    1 => 1,
    1.1 => 1.1,
    '0.01' => 0.01,
    '1' => 1,
    '1.1' => 1.1,
    '99' => 99,
    '99.9' => 99.9,
  }.each do |value, expected|
    context "#to_percentage for #{value.inspect}" do
      it "returns #{expected}" do
        expect(described_class.to_percentage(value)).to be(expected)
      end
    end
  end

  {
    nil => Set.new,
    '' => Set.new,
    Set.new([1, 2]) => Set.new([1, 2]),
    [1, 2] => Set.new([1, 2]),
  }.each do |value, expected|
    context "#to_set for #{value.inspect}" do
      it "returns #{expected}" do
        expect(described_class.to_set(value)).to eq(expected)
      end
    end
  end

  it 'raises argument error for integer value that cannot be converted to an integer' do
    expect do
      described_class.to_integer(['asdf'])
    end.to raise_error(ArgumentError, %(["asdf"] cannot be converted to an integer))
  end

  it 'raises argument error for float value that cannot be converted to an float' do
    expect do
      described_class.to_float(['asdf'])
    end.to raise_error(ArgumentError, %(["asdf"] cannot be converted to a float))
  end

  it 'raises argument error for bad integer percentage' do
    expect do
      described_class.to_percentage(['asdf'])
    end.to raise_error(ArgumentError, %(["asdf"] cannot be converted to an integer))
  end

  it 'raises argument error for bad float percentage' do
    expect do
      described_class.to_percentage(['asdf.0'])
    end.to raise_error(ArgumentError, %(["asdf.0"] cannot be converted to a float))
  end

  it 'raises argument error for set value that cannot be converted to a set' do
    expect do
      described_class.to_set('asdf')
    end.to raise_error(ArgumentError, %("asdf" cannot be converted to a set))
  end
end
