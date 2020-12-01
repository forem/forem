require 'rspec/rails/matchers/be_valid'

RSpec.describe "be_valid matcher" do
  class Post
    include ActiveModel::Validations
    attr_accessor :title
    validates_presence_of :title
  end

  class Book
    def valid?
      false
    end

    def errors
      ['the spine is broken', 'the pages are dog-eared']
    end
  end

  class Boat
    def valid?
      false
    end
  end

  class Car
    def valid?
      false
    end

    def errors(_)
    end
  end

  let(:post) { Post.new }
  let(:book) { Book.new }
  let(:boat) { Boat.new }
  let(:car) { Car.new }

  it "includes the error messages in the failure message" do
    expect {
      expect(post).to be_valid
    }.to raise_exception(/Title can't be blank/)
  end

  it "includes the error messages for simple implementations of error messages" do
    expect {
      expect(book).to be_valid
    }.to raise_exception(/the spine is broken/)
  end

  it "includes a brief error message for the simplest implementation of validity" do
    expect {
      expect(boat).to be_valid
    }.to raise_exception(/expected .+ to be valid\z/)
  end

  it "includes a brief error message when error message is wrong arity" do
    expect {
      expect(car).to be_valid
    }.to raise_exception(/expected .+ to be valid\z/)
  end

  it "includes a failure message for the negative case" do
    allow(post).to receive(:valid?) { true }
    expect {
      expect(post).not_to be_valid
    }.to raise_exception(/expected .* not to be valid/)
  end

  it "uses a custom failure message if provided" do
    expect {
      expect(post).to be_valid, "Post was not valid!"
    }.to raise_exception(/Post was not valid!/)
  end

  it "includes the validation context if provided" do
    expect(post).to receive(:valid?).with(:create) { true }
    expect(post).to be_valid(:create)
  end

  it "does not include the validation context if not provided" do
    expect(post).to receive(:valid?).with(no_args) { true }
    expect(post).to be_valid
  end
end
