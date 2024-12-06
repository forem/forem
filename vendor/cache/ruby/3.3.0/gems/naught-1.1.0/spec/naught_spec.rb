require 'spec_helper'

describe 'null object impersonating another type' do
  class Point
    attr_reader :x, :y
  end

  subject(:null) { impersonation_class.new }
  let(:impersonation_class) do
    Naught.build do |b|
      b.impersonate Point
    end
  end

  it 'matches the impersonated type' do
    expect(null).to be_a Point
  end

  it 'responds to methods from the impersonated type' do
    expect(null.x).to be_nil
    expect(null.y).to be_nil
  end

  it 'does not respond to unknown methods' do
    expect { null.foo }.to raise_error(NoMethodError)
  end
end

describe 'traceable null object' do
  subject(:trace_null) do
    null_object_and_line.first
  end
  let(:null_object_and_line) do
    obj, line = trace_null_class.new, __LINE__ # rubocop:disable ParallelAssignment
    [obj, line]
  end
  let(:instantiation_line) { null_object_and_line.last }
  let(:trace_null_class) do
    Naught.build(&:traceable)
  end

  it 'remembers the file it was instantiated from' do
    expect(trace_null.__file__).to eq(__FILE__)
  end

  it 'remembers the line it was instantiated from' do
    expect(trace_null.__line__).to eq(instantiation_line)
  end

  def make_null
    trace_null_class.get(:caller => caller(1))
  end

  it 'can accept custom backtrace info' do
    obj, line = make_null, __LINE__ # rubocop:disable ParallelAssignment
    expect(obj.__line__).to eq(line)
  end
end

describe 'customized null object' do
  subject(:custom_null) { custom_null_class.new }
  let(:custom_null_class) do
    Naught.build do |b|
      b.define_explicit_conversions
      def to_path
        '/dev/null'
      end

      def to_s
        'NOTHING TO SEE HERE'
      end
    end
  end

  it 'responds to custom-defined methods' do
    expect(custom_null.to_path).to eq('/dev/null')
  end

  it 'allows generated methods to be overridden' do
    expect(custom_null.to_s).to eq('NOTHING TO SEE HERE')
  end
end
TestNull = Naught.build

describe 'a named null object class' do
  it 'has named ancestor modules' do
    expect(TestNull.ancestors[0..2].collect(&:name)).to eq([
      'TestNull',
      'TestNull::Customizations',
      'TestNull::GeneratedMethods',
    ])
  end
end
