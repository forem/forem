# encoding: utf-8

shared_examples 'it calls super' do |method|
  around do |example|
    # Restore original method after each example
    original = "original_#{method}"
    superclass.class_eval do
      alias_method original, method
      example.call
      undef_method method
      alias_method method, original
    end
  end

  it "delegates to the superclass ##{method} method" do
    # This is the most succinct approach I could think of to test whether the
    # superclass method is called. All of the built-in rspec helpers did not
    # seem to work for this.
    called = false
    superclass.class_eval { define_method(method) { |_| called = true } }
    expect { subject }.to change { called }.from(false).to(true)
  end
end
