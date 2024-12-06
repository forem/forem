require 'spec_helper'

RSpec.describe SmartProperties, 'acceptance checking' do
  context "when used to build a class that has a property called :visible which uses an array of valid values for acceptance checking" do
    subject(:klass) { DummyClass.new { property :visible, accepts: [true, false] } }

    context "an instance of this class" do
      subject(:instance) { klass.new }

      it "should allow to set true as value for visible" do
        expect { instance.visible = true }.to_not raise_error
        expect { instance[:visible] = true }.to_not raise_error
      end

      it "should allow to set false as value for visible" do
        expect { instance.visible = false }.to_not raise_error
        expect { instance[:visible] = false }.to_not raise_error
      end

      it "should not allow to set :maybe as value for visible" do
        exception = SmartProperties::InvalidValueError
        message =  /Dummy does not accept \:maybe as value for the property visible/
        further_expectations = lambda do |error|
          expect(error.to_hash[:visible]).to eq('does not accept :maybe as value')
        end

        expect { klass.new visible: :maybe }.to raise_error(exception, message, &further_expectations)
        expect { klass.new { |i| i.visible = :maybe } }.to raise_error(exception, message, &further_expectations)

        expect { instance.visible = :maybe }.to raise_error(exception, message, &further_expectations)
        expect { instance[:visible] = :maybe }.to raise_error(exception, message, &further_expectations)
      end

      it 'should give the user a list of what it accepts on InvalidValueError' do
        exception = SmartProperties::InvalidValueError
        message = /Only accepts\: \[true, false\]/

        expect { klass.new visible: :maybe }.to raise_error(exception, message)
      end
    end
  end

  context "when used to build a class that has a property called :title that accepts either a String or a Symbol" do
    subject(:klass) { DummyClass.new { property :title, accepts: [String, Symbol] } }

    context "an instance of this class" do
      subject(:instance) { klass.new }

      it "should accept a String as title" do
        expect { subject.title = "Test" }.to_not raise_error
        expect { subject[:title] = "Test" }.to_not raise_error
      end

      it "should accept a Symbol as title" do
        expect { subject.title = :test }.to_not raise_error
        expect { subject[:title] = :test }.to_not raise_error
      end

      it 'should not accept an instance of any other type' do
        exception = SmartProperties::InvalidValueError
        message = /Dummy does not accept 13 as value for the property title/
        further_expectations = lambda do |error|
          expect(error.to_hash[:title]).to match(/does not accept 13 as value/)
        end

        expect { klass.new title: 13 }.to raise_error(exception, message, &further_expectations)
        expect { klass.new { |i| i.title = 13 } }.to raise_error(exception, message, &further_expectations)

        expect { instance.title = 13 }.to raise_error(exception, message, &further_expectations)
        expect { instance[:title] = 13 }.to raise_error(exception, message, &further_expectations)
      end

      it 'should give the user a list of what it accepts on InvalidValueError' do
        exception = SmartProperties::InvalidValueError
        message = /Only accepts\: \[String, Symbol\]/

        expect { klass.new title: 13 }.to raise_error(exception, message)
      end
    end
  end

  context 'when used to build a class that has a property called :license_plate which uses a lambda statement for acceptance checking' do
    subject(:klass) do
      DummyClass.new do
        property :license_plate, accepts: lambda { |v| license_plate_pattern.match(v) }

        def license_plate_pattern
          /\w{1,2} \w{1,2} \d{1,4}/
        end
      end
    end

    context 'an instance of this class' do
      subject(:instance) { klass.new }

      it 'should not a accept "invalid" as value for license_plate' do
        exception = SmartProperties::InvalidValueError
        message = /Dummy does not accept "invalid" as value for the property license_plate/
        further_expectations = lambda do |error|
          expect(error.to_hash[:license_plate]).to match(/does not accept "invalid" as value/)
        end

        expect { klass.new license_plate: "invalid" }.to raise_error(exception, message, &further_expectations)
        expect { klass.new { |i| i.license_plate = "invalid" } }.to raise_error(exception, message, &further_expectations)

        expect { instance.license_plate = "invalid" }.to raise_error(exception, message, &further_expectations)
        expect { instance[:license_plate] = "invalid" }.to raise_error(exception, message, &further_expectations)
      end

      it 'should give the user the location of the proc determining what it accepts on InvalidValueError' do
        exception = SmartProperties::InvalidValueError
        message = /spec\/acceptance_checking_spec\.rb at line 85/

        expect { klass.new license_plate: 'slurp' }.to raise_error(exception, message)
      end

      it 'should accept "NE RD 1337" as license plate' do
        expect { klass.new.license_plate = "NE RD 1337" }.to_not raise_error
        expect { klass.new { |i| i.license_plate = "NE RD 1337" } }.to_not raise_error

        expect { instance.license_plate = "NE RD 1337" }.to_not raise_error
        expect { instance[:license_plate] = "NE RD 1337" }.to_not raise_error
      end
    end
  end
end
