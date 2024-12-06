require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "SAXMachine configure" do
  before do
    class A
      SAXMachine.configure(A) do |c|
        c.element :title
      end
    end

    class B < A
      SAXMachine.configure(B) do |c|
        c.element :b
      end
    end

    class C < B
      SAXMachine.configure(C) do |c|
        c.element :c
      end
    end

    xml = "<top><title>Test</title><b>Matched!</b><c>And Again</c></top>"
    @a = A.parse xml
    @b = B.parse xml
    @c = C.parse xml
  end

  after do
    Object.send(:remove_const, :A)
    Object.send(:remove_const, :B)
    Object.send(:remove_const, :C)
  end

  it { expect(@a).to be_a(A) }
  it { expect(@a).not_to be_a(B) }
  it { expect(@a).to be_a(SAXMachine) }
  it { expect(@a.title).to eq("Test") }
  it { expect(@b).to be_a(A) }
  it { expect(@b).to be_a(B) }
  it { expect(@b).to be_a(SAXMachine) }
  it { expect(@b.title).to eq("Test") }
  it { expect(@b.b).to eq("Matched!") }
  it { expect(@c).to be_a(A) }
  it { expect(@c).to be_a(B) }
  it { expect(@c).to be_a(C) }
  it { expect(@c).to be_a(SAXMachine) }
  it { expect(@c.title).to eq("Test") }
  it { expect(@c.b).to eq("Matched!") }
  it { expect(@c.c).to eq("And Again") }
end
