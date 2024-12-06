require "rolify/shared_contexts"
require "rolify/shared_examples/shared_examples_for_add_role"
require "rolify/shared_examples/shared_examples_for_has_role"
require "rolify/shared_examples/shared_examples_for_only_has_role"
require "rolify/shared_examples/shared_examples_for_has_all_roles"
require "rolify/shared_examples/shared_examples_for_has_any_role"
require "rolify/shared_examples/shared_examples_for_remove_role"
require "rolify/shared_examples/shared_examples_for_finders"


shared_examples_for Rolify::Role do
  before(:all) do
    reset_defaults
    Rolify.dynamic_shortcuts = false
    rolify_options = { :role_cname => role_class.to_s }
    rolify_options[:role_join_table_name] = join_table if defined? join_table
    silence_warnings { user_class.rolify rolify_options }
    role_class.destroy_all
    Forum.resourcify :roles, :role_cname => role_class.to_s
    Group.resourcify :roles, :role_cname => role_class.to_s
    Organization.resourcify :roles, :role_cname => role_class.to_s
  end

  context "in the Instance level" do
    before(:all) do
      admin = user_class.first
      admin.add_role :admin
      admin.add_role :moderator, Forum.first
    end

    subject { user_class.first }

    [ :grant, :add_role ].each do |method_alias|
      it { should respond_to(method_alias.to_sym).with(1).arguments }
      it { should respond_to(method_alias.to_sym).with(2).arguments }
    end

    it { should respond_to(:has_role?).with(1).arguments }
    it { should respond_to(:has_role?).with(2).arguments }

    it { should respond_to(:has_all_roles?) }
    it { should respond_to(:has_all_roles?) }

    it { should respond_to(:has_any_role?) }
    it { should respond_to(:has_any_role?) }

    [ :has_no_role, :revoke, :remove_role ].each do |method_alias|
      it { should respond_to(method_alias.to_sym).with(1).arguments }
      it { should respond_to(method_alias.to_sym).with(2).arguments }
    end

    it { should_not respond_to(:is_admin?) }
    it { should_not respond_to(:is_moderator_of?) }

    describe "#has_role?" do
      it_should_behave_like "#has_role?_examples", "String", :to_s
      it_should_behave_like "#has_role?_examples", "Symbol", :to_sym
    end

    describe "#only_has_role?" do
      it_should_behave_like "#only_has_role?_examples", "String", :to_s
      it_should_behave_like "#only_has_role?_examples", "Symbol", :to_sym
    end

    describe "#has_all_roles?" do
      it_should_behave_like "#has_all_roles?_examples", "String", :to_s
      it_should_behave_like "#has_all_roles?_examples", "Symbol", :to_sym
    end

    describe "#has_any_role?" do
      it_should_behave_like "#has_any_role?_examples", "String", :to_s
      it_should_behave_like "#has_any_role?_examples", "Symbol", :to_sym
    end

    describe "#has_no_role" do
      it_should_behave_like "#remove_role_examples", "String", :to_s
      it_should_behave_like "#remove_role_examples", "Symbol", :to_sym
    end
  end

  context "with a new instance" do
    let(:user) { user_class.new }

    before do
      user.add_role :admin
      user.add_role :moderator, Forum.first
    end

    subject { user }

    it { should have_role :admin }
    # it { should have_role :admin, Forum }
    # it { should have_role :admin, :any }
    # it { should have_role :moderator, Forum.first }
    # it { should have_role :moderator, :any }
    # it { should_not have_role :moderator }
    # it { should_not have_role :moderator, Forum }
    it { subject.has_any_role?(:admin).should be_truthy }
  end

  context "on the Class level ", :scope => :mixed do
    it_should_behave_like :finders, "String", :to_s
    it_should_behave_like :finders, "Symbol", :to_sym
  end
end
