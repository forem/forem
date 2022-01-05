require 'spec_helper'

HairTrigger::Builder.show_warnings = false

class MockAdapter
  attr_reader :adapter_name
  def initialize(type, methods = {})
    @adapter_name = type
    methods.each do |key, value|
      instance_eval("def #{key}; #{value.inspect}; end")
    end
  end

  def quote_table_name(table)
    table
  end
end

def builder(name = nil)
  HairTrigger::Builder.new(name, :adapter => @adapter)
end

describe "builder" do
  context "chaining" do
    it "should use the last redundant chained call" do
      @adapter = MockAdapter.new("mysql")
      builder.where(:foo).where(:bar).options[:where].should be(:bar)
    end
  end

  context "generation" do
    it "should tack on a semicolon if none is provided" do
      @adapter = MockAdapter.new("mysql")
      builder.on(:foos).after(:update){ "FOO " }.generate.
        grep(/FOO;/).size.should eql(1)
    end

    it "should work with frozen strings" do
      @adapter = MockAdapter.new("mysql")
      lambda {
        builder.on(:foos).after(:update){ "FOO".freeze }.generate
      }.should_not raise_error
    end
  end

  context "comparison" do
    it "should view identical triggers as identical" do
      @adapter = MockAdapter.new("mysql")
      builder.on(:foos).after(:update){ "FOO" }.
        should eql(builder.on(:foos).after(:update){ "FOO" })
    end

    it "should view incompatible triggers as different" do
      @adapter = MockAdapter.new("mysql")
      HairTrigger::Builder.new(nil, :adapter => @adapter, :compatibility => 0).on(:foos).after(:update){ "FOO" }.
        should_not eql(builder.on(:foos).after(:update){ "FOO" })
    end
  end

  describe "name" do
    it "should be inferred if none is provided" do
      builder.on(:foos).after(:update){ "foo" }.prepared_name.
        should == "foos_after_update_row_tr"
    end

    it "should respect the last chained name" do
      builder("lolwut").on(:foos).after(:update){ "foo" }.prepared_name.
        should == "lolwut"
      builder("lolwut").on(:foos).name("zomg").after(:update).name("yolo"){ "foo" }.prepared_name.
        should == "yolo"
    end
  end

  describe "`of' columns" do
    it "should be disallowed for non-update triggers" do
      lambda {
        builder.on(:foos).after(:insert).of(:bar, :baz){ "BAR" }
      }.should raise_error /of may only be specified on update triggers/
    end
  end

  describe "groups" do
    it "should allow chained methods" do
      triggers = builder.on(:foos){ |t|
        t.where('bar=1').name('bar'){ 'BAR;' }
        t.where('baz=1').name('baz'){ 'BAZ;' }
      }.triggers
      triggers.map(&:prepare!)
      triggers.map(&:prepared_name).should == ['bar', 'baz']
      triggers.map(&:prepared_where).should == ['bar=1', 'baz=1']
      triggers.map(&:prepared_actions).should == ['BAR;', 'BAZ;']
    end
  end

  context "adapter-specific actions" do
    before(:each) do
      @adapter = MockAdapter.new("mysql")
    end

    it "should generate the appropriate trigger for the adapter" do
      sql = builder.on(:foos).after(:update).where('BAR'){
        {:default => "DEFAULT", :mysql => "MYSQL"}
      }.generate

      sql.grep(/DEFAULT/).size.should eql(0)
      sql.grep(/MYSQL/).size.should eql(1)

      sql = builder.on(:foos).after(:update).where('BAR'){
        {:default => "DEFAULT", :postgres => "POSTGRES"}
      }.generate

      sql.grep(/POSTGRES/).size.should eql(0)
      sql.grep(/DEFAULT/).size.should eql(1)
    end

    it "should complain if no actions are provided for this adapter" do
      lambda {
        builder.on(:foos).after(:update).where('BAR'){ {:postgres => "POSTGRES"} }.generate
      }.should raise_error
    end
  end

  context "mysql" do
    before(:each) do
      @adapter = MockAdapter.new("mysql")
    end

    it "should create a single trigger for a group" do
      trigger = builder.on(:foos).after(:update){ |t|
        t.where('BAR'){ 'BAR' }
        t.where('BAZ'){ 'BAZ' }
      }
      trigger.generate.grep(/CREATE.*TRIGGER/).size.should eql(1)
    end

    it "should disallow nested groups" do
      lambda {
        builder.on(:foos){ |t|
          t.after(:update){ |t|
            t.where('BAR'){ 'BAR' }
            t.where('BAZ'){ 'BAZ' }
          }
        }.generate
      }.should raise_error
    end

    it "should warn on explicit subtrigger names and no group name" do
      trigger = builder.on(:foos){ |t|
        t.where('bar=1').name('bar'){ 'BAR;' }
        t.where('baz=1').name('baz'){ 'BAZ;' }
      }
      trigger.warnings.size.should == 1
      trigger.warnings.first.first.should =~ /nested triggers have explicit names/
    end

    it "should accept security" do
      builder.on(:foos).after(:update).security(:definer){ "FOO" }.generate.
        grep(/DEFINER/).size.should eql(0) # default, so we don't include it
      builder.on(:foos).after(:update).security("CURRENT_USER"){ "FOO" }.generate.
        grep(/DEFINER = CURRENT_USER/).size.should eql(1)
      builder.on(:foos).after(:update).security("'user'@'host'"){ "FOO" }.generate.
        grep(/DEFINER = 'user'@'host'/).size.should eql(1)
    end

    it "should infer `if' conditionals from `of' columns" do
      builder.on(:foos).after(:update).of(:bar){ "BAZ" }.generate.join("\n").
        should include("IF NEW.bar <> OLD.bar OR (NEW.bar IS NULL) <> (OLD.bar IS NULL) THEN")
    end

    it "should merge `where` and `of` into an `if` conditional" do
      builder.on(:foos).after(:update).of(:bar).where("lol"){ "BAZ" }.generate.join("\n").
        should include("IF (lol) AND (NEW.bar <> OLD.bar OR (NEW.bar IS NULL) <> (OLD.bar IS NULL)) THEN")
    end

    it "should reject :invoker security" do
      lambda {
        builder.on(:foos).after(:update).security(:invoker){ "FOO" }.generate
      }.should raise_error
    end

    it "should reject for_each :statement" do
      lambda {
        builder.on(:foos).after(:update).for_each(:statement){ "FOO" }.generate
      }.should raise_error
    end

    it "should reject multiple events" do
      lambda {
        builder.on(:foos).after(:update, :delete){ "FOO" }.generate
      }.should raise_error
    end

    it "should reject truncate" do
      lambda {
        builder.on(:foos).after(:truncate){ "FOO" }.generate
      }.should raise_error
    end

    describe "#to_ruby" do
      it "should fully represent the builder" do
        code = <<-CODE.strip.gsub(/^ +/, '')
          on("foos").
          security(:definer).
          for_each(:row).
          before(:update) do |t|
            t.where("NEW.foo") do
              "FOO;"
            end
          end
        CODE
        b = builder
        b.instance_eval(code)
        b.to_ruby.strip.gsub(/^ +/, '').should be_include(code)
      end
    end
  end

  context "postgresql" do
    before(:each) do
      @adapter = MockAdapter.new("postgresql", :postgresql_version => 94000)
    end

    it "should create multiple triggers for a group" do
      trigger = builder.on(:foos).after(:update){ |t|
        t.where('BAR'){ 'BAR' }
        t.where('BAZ'){ 'BAZ' }
      }
      trigger.generate.grep(/CREATE.*TRIGGER/).size.should eql(2)
    end

    it "should allow nested groups" do
      trigger = builder.on(:foos){ |t|
        t.after(:update){ |t|
          t.where('BAR'){ 'BAR' }
          t.where('BAZ'){ 'BAZ' }
        }
        t.after(:insert){ 'BAZ' }
      }
      trigger.generate.grep(/CREATE.*TRIGGER/).size.should eql(3)
    end

    it "should warn on an explicit group names and no subtrigger names" do
      trigger = builder.on(:foos).name('foos'){ |t|
        t.where('bar=1'){ 'BAR;' }
        t.where('baz=1'){ 'BAZ;' }
      }
      trigger.warnings.size.should == 1
      trigger.warnings.first.first.should =~ /trigger group has an explicit name/
    end

    it "should accept `of' columns" do
      trigger = builder.on(:foos).after(:update).of(:bar, :baz){ "BAR" }
      trigger.generate.grep(/AFTER UPDATE OF bar, baz/).size.should eql(1)
    end

    it "should accept security" do
      builder.on(:foos).after(:update).security(:invoker){ "FOO" }.generate.
        grep(/SECURITY/).size.should eql(0) # default, so we don't include it
      builder.on(:foos).after(:update).security(:definer){ "FOO" }.generate.
        grep(/SECURITY DEFINER/).size.should eql(1)
    end

    it "should reject arbitrary user security" do
      lambda {
        builder.on(:foos).after(:update).security("'user'@'host'"){ "FOO" }.
        generate
      }.should raise_error
    end

    it "should accept multiple events" do
      builder.on(:foos).after(:update, :delete){ "FOO" }.generate.
        grep(/UPDATE OR DELETE/).size.should eql(1)
    end

    it "should reject long names" do
      lambda {
        builder.name('A'*65).on(:foos).after(:update){ "FOO" }.generate
      }.should raise_error
    end

    it "should allow truncate with for_each statement" do
      builder.on(:foos).after(:truncate).for_each(:statement){ "FOO" }.generate.
        grep(/TRUNCATE.*FOR EACH STATEMENT/m).size.should eql(1)
    end

    it "should reject truncate with for_each row" do
      lambda {
        builder.on(:foos).after(:truncate){ "FOO" }.generate
      }.should raise_error
    end

    it "should add a return statement if none is provided" do
      builder.on(:foos).after(:update){ "FOO" }.generate.
        grep(/RETURN NULL;/).size.should eql(1)
    end

    it "should not wrap the action in a function" do
      builder.on(:foos).after(:update).nowrap{ 'existing_procedure()' }.generate.
        grep(/CREATE FUNCTION/).size.should eql(0)
    end

    it "should reject combined use of security and nowrap" do
      lambda {
        builder.on(:foos).after(:update).security("'user'@'host'").nowrap{ "FOO" }.generate
      }.should raise_error
    end

    it "should allow variable declarations" do
      builder.on(:foos).after(:insert).declare("foo INT"){ "FOO" }.generate.join("\n").
        should match(/DECLARE\s*foo INT;\s*BEGIN\s*FOO/)
    end

    context "legacy" do
      it "should reject truncate pre-8.4" do
        @adapter = MockAdapter.new("postgresql", :postgresql_version => 80300)
        lambda {
          builder.on(:foos).after(:truncate).for_each(:statement){ "FOO" }.generate
        }.should raise_error
      end

      it "should use conditionals pre-9.0" do
        @adapter = MockAdapter.new("postgresql", :postgresql_version => 80400)
        builder.on(:foos).after(:insert).where("BAR"){ "FOO" }.generate.
        grep(/IF BAR/).size.should eql(1)
      end

      it "should reject combined use of where and nowrap pre-9.0" do
        @adapter = MockAdapter.new("postgresql", :postgresql_version => 80400)
        lambda {
          builder.on(:foos).after(:insert).where("BAR").nowrap{ "FOO" }.generate
        }.should raise_error
      end

      it "should infer `if' conditionals from `of' columns on pre-9.0" do
        @adapter = MockAdapter.new("postgresql", :postgresql_version => 80400)
        builder.on(:foos).after(:update).of(:bar){ "BAZ" }.generate.join("\n").
          should include("IF NEW.bar <> OLD.bar OR (NEW.bar IS NULL) <> (OLD.bar IS NULL) THEN")
      end
    end

    describe "#to_ruby" do
      it "should fully represent the builder" do
        code = <<-CODE.strip.gsub(/^ +/, '')
          on("foos").
          of("bar").
          security(:invoker).
          for_each(:row).
          before(:update) do |t|
            t.where("NEW.foo").declare("row RECORD") do
              "FOO;"
            end
          end
        CODE
        b = builder
        b.instance_eval(code)
        b.to_ruby.strip.gsub(/^ +/, '').should be_include(code)
      end
    end
  end

  context "sqlite" do
    before(:each) do
      @adapter = MockAdapter.new("sqlite")
    end

    it "should create multiple triggers for a group" do
      trigger = builder.on(:foos).after(:update){ |t|
        t.where('BAR'){ 'BAR' }
        t.where('BAZ'){ 'BAZ' }
      }
      trigger.generate.grep(/CREATE.*TRIGGER/).size.should eql(2)
    end

    it "should allow nested groups" do
      trigger = builder.on(:foos){ |t|
        t.after(:update){ |t|
          t.where('BAR'){ 'BAR' }
          t.where('BAZ'){ 'BAZ' }
        }
        t.after(:insert){ 'BAZ' }
      }
      trigger.generate.grep(/CREATE.*TRIGGER/).size.should eql(3)
    end

    it "should warn on an explicit group names and no subtrigger names" do
      trigger = builder.on(:foos).name('foos'){ |t|
        t.where('bar=1'){ 'BAR;' }
        t.where('baz=1'){ 'BAZ;' }
      }
      trigger.warnings.size.should == 1
      trigger.warnings.first.first.should =~ /trigger group has an explicit name/
    end

    it "should accept `of' columns" do
      trigger = builder.on(:foos).after(:update).of(:bar, :baz){ "BAR" }
      trigger.generate.grep(/AFTER UPDATE OF bar, baz/).size.should eql(1)
    end

    it "should reject security" do
      lambda {
        builder.on(:foos).after(:update).security(:definer){ "FOO" }.generate
      }.should raise_error
    end

    it "should reject for_each :statement" do
      lambda {
        builder.on(:foos).after(:update).for_each(:statement){ "FOO" }.generate
      }.should raise_error
    end

    it "should reject multiple events" do
      lambda {
        builder.on(:foos).after(:update, :delete){ "FOO" }.generate
      }.should raise_error
    end

    it "should reject truncate" do
      lambda {
        builder.on(:foos).after(:truncate){ "FOO" }.generate
      }.should raise_error
    end

    describe "#to_ruby" do
      it "should fully represent the builder" do
        code = <<-CODE.strip.gsub(/^ +/, '')
          on("foos").
          of("bar").
          before(:update) do |t|
            t.where("NEW.foo") do
              "FOO;"
            end
          end
        CODE
        b = builder
        b.instance_eval(code)
        b.to_ruby.strip.gsub(/^ +/, '').should be_include(code)
      end
    end
  end
end
