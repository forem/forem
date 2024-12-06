# encoding: utf-8

require 'spec_helper'

describe Memoizable::ModuleMethods, '#included' do
  subject { descendant.instance_exec(object) { |mod| include mod } }

  let(:object)     { Module.new.extend(described_class) }
  let(:descendant) { Class.new                          }
  let(:superclass) { Module                             }

  before do
    # Prevent Module.included from being called through inheritance
    allow(Memoizable).to receive(:included)
  end

  it_behaves_like 'it calls super', :included

  it 'includes Memoizable into the descendant' do
    subject
    expect(descendant.included_modules).to include(Memoizable)
  end
end
