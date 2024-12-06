# encoding: utf-8

require 'spec_helper'

describe Memoizable, '.included' do
  subject { object.class_eval { include Memoizable } }

  let(:object)     { Class.new }
  let(:superclass) { Module    }

  it_behaves_like 'it calls super', :included

  it 'extends the descendant with module methods' do
    subject
    extended_modules = class << object; included_modules end
    expect(extended_modules).to include(Memoizable::ModuleMethods)
  end
end
