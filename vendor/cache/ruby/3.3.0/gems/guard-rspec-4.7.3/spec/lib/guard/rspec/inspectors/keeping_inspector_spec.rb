require "guard/compat/test/helper"

require "lib/guard/rspec/inspectors/shared_examples"

require "guard/rspec/inspectors/keeping_inspector"

klass = Guard::RSpec::Inspectors::KeepingInspector

RSpec.describe klass do
  include_examples "inspector", klass

  # Use real paths because BaseInspector#_clean will be used to clean them
  let(:other_paths) do
    [
      "spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb",
      "spec/lib/guard/rspec/runner_spec.rb"
    ]
  end
  let(:other_failed_locations) do
    [
      "./spec/lib/guard/rspec/runner_spec.rb:12",
      "./spec/lib/guard/rspec/runner_spec.rb:100",
      "./spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb:12"
    ]
  end

  it "remembers failed paths and returns them along with new paths" do
    allow(File).to receive(:directory?).
      with("spec/lib/guard/rspec/inspectors/base_inspector_spec.rb").
      and_return(false)

    allow(File).to receive(:directory?).
      with("spec/lib/guard/rspec/runner_spec.rb").
      and_return(false)

    allow(File).to receive(:directory?).
      with("spec/lib/guard/rspec/deprecator_spec.rb").
      and_return(false)

    allow(File).to receive(:directory?).
      with("spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb").
      and_return(false)

    allow(Dir).to receive(:[]).with("spec/**{,/*/**}/*[_.]spec.rb").
      and_return(paths + other_paths)

    allow(Dir).to receive(:[]).with("myspec/**{,/*/**}/*[_.]spec.rb").
      and_return([])

    allow(Dir).to receive(:[]).with("myspec/**{,/*/**}/*.feature").
      and_return([])

    allow(Dir).to receive(:[]).with("spec/**{,/*/**}/*.feature").
      and_return([])

    expect(inspector.paths(paths)).to eq(paths)
    inspector.failed(failed_locations)

    # Line numbers in failed_locations needs to be omitted because of
    # https://github.com/rspec/rspec-core/issues/952
    expect(inspector.paths(other_paths)).to match_array(
      [
        "spec/lib/guard/rspec/deprecator_spec.rb",
        "spec/lib/guard/rspec/runner_spec.rb",
        "spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb"
      ]
    )
    inspector.failed(other_failed_locations)

    # Now it returns other failed locations
    expect(
      inspector.paths(
        %w(spec/lib/guard/rspec/inspectors/base_inspector_spec.rb)
      )
    ).to match_array(
      [
        "spec/lib/guard/rspec/runner_spec.rb",
        "spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb",
        "spec/lib/guard/rspec/inspectors/base_inspector_spec.rb"
      ]
    )
    inspector.failed(other_failed_locations)

    expect(
      inspector.paths(%w(spec/lib/guard/rspec/runner_spec.rb))
    ).to match_array(
      [
        "spec/lib/guard/rspec/runner_spec.rb",
        "spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb"
      ]
    )

    inspector.failed([])

    # Now there is no failed locations
    expect(inspector.paths(paths)).to match_array(paths)
  end

  describe "#reload" do
    it "force to forget about failed locations" do
      allow(File).to receive(:directory?).
        with("spec/lib/guard/rspec/inspectors/base_inspector_spec.rb").
        and_return(false)

      allow(File).to receive(:directory?).
        with("spec/lib/guard/rspec/runner_spec.rb").
        and_return(false)

      allow(File).to receive(:directory?).
        with("spec/lib/guard/rspec/deprecator_spec.rb").
        and_return(false)

      allow(File).to receive(:directory?).
        with("spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb").
        and_return(false)

      allow(Dir).to receive(:[]).with("spec/**{,/*/**}/*[_.]spec.rb").
        and_return(paths + other_paths)

      allow(Dir).to receive(:[]).with("myspec/**{,/*/**}/*[_.]spec.rb").
        and_return([])

      allow(Dir).to receive(:[]).with("myspec/**{,/*/**}/*.feature").
        and_return([])

      allow(Dir).to receive(:[]).with("spec/**{,/*/**}/*.feature").
        and_return([])

      expect(inspector.paths(paths)).to eq(paths)
      inspector.failed(failed_locations)

      inspector.reload
      expect(inspector.paths(other_paths)).to match_array(other_paths)
    end
  end
end

#
#  FIXME uncomment when RSpec #952 will be resolved
#
#  This is correct spec for KeepingInspector class,
#  bit it doesn't work because of bug with RSpec
#  https://github.com/rspec/rspec-core/issues/952
#
# describe klass do
#  include_examples 'inspector', klass
#
#  # Use real paths because BaseInspector#_clean will be used to clean them
#  let(:other_paths) { [
#    'spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb',
#    'spec/lib/guard/rspec/runner_spec.rb'
#  ] }
#  let(:other_failed_locations) { [
#    './spec/lib/guard/rspec/runner_spec.rb:12',
#    './spec/lib/guard/rspec/runner_spec.rb:100',
#    './spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb:12'
#  ] }
#
#  it 'remembers failed paths and returns them along with new paths' do
#    expect(inspector.paths(paths)).to eq(paths)
#    inspector.failed(failed_locations)
#
#    # other_paths and failed_locations contain the same spec (runner_spec.rb)
#    # so #paths should return that spec only once (omit location)
#    expect(inspector.paths(other_paths)).to match_array(
#      other_paths +
#      %w[./spec/lib/guard/rspec/deprecator_spec.rb:55]
#    )
#    inspector.failed(other_failed_locations)
#
#    # Now it returns other failed locations
#    expect(inspector.paths(%w[spec/lib/guard/rspec/deprecator_spec.rb])).to
#    match_array(
#      other_failed_locations +
#      %w[spec/lib/guard/rspec/deprecator_spec.rb]
#    )
#    inspector.failed(other_failed_locations)
#
#    # It returns runner_spec.rb without locations in that spec
#    expect(inspector.paths(%w[spec/lib/guard/rspec/runner_spec.rb])).
#    to match_array([
#      './spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb:12',
#      'spec/lib/guard/rspec/runner_spec.rb'
#    ])
#    inspector.failed([])
#
#    # Now there is no failed locations
#    expect(inspector.paths(paths)).to match_array(paths)
#  end
#
#  describe '#reload' do
#    it 'force to forget about failed locations' do
#      expect(inspector.paths(paths)).to eq(paths)
#      inspector.failed(failed_locations)
#
#      inspector.reload
#      expect(inspector.paths(other_paths)).to match_array(other_paths)
#    end
#  end
# end
