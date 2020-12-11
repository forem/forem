require 'rspec/support/comparable_version'

module RSpec::Support
  RSpec.describe ComparableVersion do
    describe '#<=>' do
      [
        ['1.2.3',        '1.2.3',        0],
        ['1.2.4',        '1.2.3',        1],
        ['1.3.0',        '1.2.3',        1],
        ['1.2.3',        '1.2.4',       -1],
        ['1.2.3',        '1.3.0',       -1],
        ['1.2.10',       '1.2.3',        1],
        ['1.2.3',        '1.2.10',      -1],
        ['1.2.3.0',      '1.2.3',        0],
        ['1.2.3',        '1.2.3.0',      0],
        ['1.2.3.1',      '1.2.3',        1],
        ['1.2.3.1',      '1.2.3.0',      1],
        ['1.2.3',        '1.2.3.1',     -1],
        ['1.2.3.0',      '1.2.3.1',     -1],
        ['1.2.3.rc1',    '1.2.3',       -1],
        ['1.2.3.rc1',    '1.2.3.rc2',   -1],
        ['1.2.3.rc2',    '1.2.3.rc10',  -1],
        ['1.2.3.alpha2', '1.2.3.beta1', -1],
        ['1.2.3',        '1.2.3.rc1',    1],
        ['1.2.3.rc2',    '1.2.3.rc1',    1],
        ['1.2.3.rc10',   '1.2.3.rc2',    1],
        ['1.2.3.beta1',  '1.2.3.alpha2', 1]
      ].each do |subject_string, other_string, expected|
        context "with #{subject_string.inspect} and #{other_string.inspect}" do
          subject do
            ComparableVersion.new(subject_string) <=> ComparableVersion.new(other_string)
          end

          it { is_expected.to eq(expected) }
        end
      end
    end
  end
end
