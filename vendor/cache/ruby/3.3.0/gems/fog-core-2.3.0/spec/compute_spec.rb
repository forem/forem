require "spec_helper"

module Fog
  module Compute
    def self.require(*_args); end
  end
end

describe "Fog::Compute" do
  describe "#new" do
    module Fog
      module TheRightWay
        class Compute
          def initialize(_args); end
        end
      end
    end

    module Fog
      module TheRightWay
        extend Provider
        service(:compute, "Compute")
      end
    end

    it "instantiates an instance of Fog::Compute::<Provider> from the :provider keyword arg" do
      compute = Fog::Compute.new(:provider => :therightway)
      assert_instance_of(Fog::TheRightWay::Compute, compute)
    end

    module Fog
      module Compute
        class TheWrongWay
          def initialize(_args); end
        end
      end
    end

    module Fog
      module TheWrongWay
        extend Provider
        service(:compute, "Compute")
      end
    end

    it "instantiates an instance of Fog::<Provider>::Compute from the :provider keyword arg" do
      compute = Fog::Compute.new(:provider => :thewrongway)
      assert_instance_of(Fog::Compute::TheWrongWay, compute)
    end

    module Fog
      module BothWays
        class Compute
          attr_reader :args
          def initialize(args)
            @args = args
          end
        end
      end
    end

    module Fog
      module Compute
        class BothWays
          def initialize(_args); end
        end
      end
    end

    module Fog
      module BothWays
        extend Provider
        service(:compute, "Compute")
      end
    end

    describe "when both Fog::Compute::<Provider> and Fog::<Provider>::Compute exist" do
      it "prefers Fog::<Provider>::Compute" do
        compute = Fog::Compute.new(:provider => :bothways)
        assert_instance_of(Fog::BothWays::Compute, compute)
      end
    end

    it "passes the supplied keyword args less :provider to Fog::Compute::<Provider>#new" do
      compute = Fog::Compute.new(:provider => :bothways, :extra => :stuff)
      assert_equal({ :extra => :stuff }, compute.args)
    end

    it "raises ArgumentError when given a :provider where a Fog::Compute::Provider that does not exist" do
      assert_raises(ArgumentError) do
        Fog::Compute.new(:provider => :wat)
      end
    end
  end
end
