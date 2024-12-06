# encoding: utf-8

shared_examples_for 'a command method' do
  it 'returns self' do
    should equal(object)
  end
end
