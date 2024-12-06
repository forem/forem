RSpec.describe Flipper::UI::Action do
  describe 'request methods' do
    let(:action_subclass) do
      Class.new(described_class) do
        def noooope
          raise 'should never run this'
        end

        def get
          [200, {}, 'get']
        end

        def post
          [200, {}, 'post']
        end

        def put
          [200, {}, 'put']
        end

        def delete
          [200, {}, 'delete']
        end
      end
    end

    it "won't run method that isn't whitelisted" do
      fake_request = Struct.new(:request_method, :env, :session).new('NOOOOPE', {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect do
        action.run
      end.to raise_error(Flipper::UI::RequestMethodNotSupported)
    end

    it 'will run get' do
      fake_request = Struct.new(:request_method, :env, :session).new('GET', {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, {}, 'get'])
    end

    it 'will run post' do
      fake_request = Struct.new(:request_method, :env, :session).new('POST', {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, {}, 'post'])
    end

    it 'will run put' do
      fake_request = Struct.new(:request_method, :env, :session).new('PUT', {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, {}, 'put'])
    end
  end

  describe 'FeatureNameFromRoute' do
    let(:action_subclass) do
      Class.new(described_class) do |parent|
        include parent::FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)\Z}

        def get
          [200, { feature_name: feature_name }, 'get']
        end
      end
    end

    it 'decodes feature_name' do
      requested_feature_name = Rack::Utils.escape("team:side_pane")
      fake_request = Struct
                     .new(:request_method, :env, :session, :path_info)
                     .new('GET', {}, {}, "/features/#{requested_feature_name}")
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, { feature_name: "team:side_pane" }, 'get'])
    end
  end
end
