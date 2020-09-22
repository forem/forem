require 'helper'

describe OmniAuth::AuthHash do
  subject { OmniAuth::AuthHash.new }
  it 'converts a supplied info key into an InfoHash object' do
    subject.info = {:first_name => 'Awesome'}
    expect(subject.info).to be_kind_of(OmniAuth::AuthHash::InfoHash)
    expect(subject.info.first_name).to eq('Awesome')
  end

  it 'does not try to parse `string` as InfoHash' do
    subject.weird_field = {:info => 'string'}
    expect(subject.weird_field.info).to eq 'string'
  end

  describe '#valid?' do
    subject { OmniAuth::AuthHash.new(:uid => '123', :provider => 'example', :info => {:name => 'Steven'}) }

    it 'is valid with the right parameters' do
      expect(subject).to be_valid
    end

    it 'requires a uid' do
      subject.uid = nil
      expect(subject).not_to be_valid
    end

    it 'requires a provider' do
      subject.provider = nil
      expect(subject).not_to be_valid
    end

    it 'requires a name in the user info hash' do
      subject.info.name = nil
      expect(subject).not_to be_valid
    end
  end

  describe '#name' do
    subject do
      OmniAuth::AuthHash.new(:info => {
                               :name => 'Phillip J. Fry',
                               :first_name => 'Phillip',
                               :last_name => 'Fry',
                               :nickname => 'meatbag',
                               :email => 'fry@planetexpress.com'
                             })
    end

    it 'defaults to the name key' do
      expect(subject.info.name).to eq('Phillip J. Fry')
    end

    it 'falls back to go to first_name last_name concatenation' do
      subject.info.name = nil
      expect(subject.info.name).to eq('Phillip Fry')
    end

    it 'displays only a first or last name if only that is available' do
      subject.info.name = nil
      subject.info.first_name = nil
      expect(subject.info.name).to eq('Fry')
    end

    it 'displays the nickname if no name, first, or last is available' do
      subject.info.name = nil
      %w[first_name last_name].each { |k| subject.info[k] = nil }
      expect(subject.info.name).to eq('meatbag')
    end

    it 'displays the email if no name, first, last, or nick is available' do
      subject.info.name = nil
      %w[first_name last_name nickname].each { |k| subject.info[k] = nil }
      expect(subject.info.name).to eq('fry@planetexpress.com')
    end
  end

  describe '#to_hash' do
    subject { OmniAuth::AuthHash.new(:uid => '123', :provider => 'test', :name => 'Example User') }
    let(:hash) { subject.to_hash }

    it 'is a plain old hash' do
      expect(hash.class).to eq(::Hash)
    end

    it 'has string keys' do
      expect(hash.keys).to be_include('uid')
    end

    it 'converts an info hash as well' do
      subject.info = {:first_name => 'Example', :last_name => 'User'}
      expect(subject.info.class).to eq(OmniAuth::AuthHash::InfoHash)
      expect(subject.to_hash['info'].class).to eq(::Hash)
    end

    it 'supplies the calculated name in the converted hash' do
      subject.info = {:first_name => 'Examplar', :last_name => 'User'}
      expect(hash['info']['name']).to eq('Examplar User')
    end

    it "does not pollute the URL hash with 'name' etc" do
      subject.info = {'urls' => {'Homepage' => 'http://homepage.com'}}
      expect(subject.to_hash['info']['urls']).to eq('Homepage' => 'http://homepage.com')
    end
  end

  describe OmniAuth::AuthHash::InfoHash do
    describe '#valid?' do
      it 'is valid if there is a name' do
        expect(OmniAuth::AuthHash::InfoHash.new(:name => 'Awesome')).to be_valid
      end
    end

    require 'hashie/version'
    if Gem::Version.new(Hashie::VERSION) >= Gem::Version.new('3.5.1')
      context 'with Hashie 3.5.1+' do
        around(:each) do |example|
          original_logger = Hashie.logger
          example.run
          Hashie.logger = original_logger
        end

        it 'does not log anything in Hashie 3.5.1+' do
          logger = double('Logger')
          expect(logger).not_to receive(:warn)

          Hashie.logger = logger

          subject.name = 'test'
        end
      end
    end
  end
end
