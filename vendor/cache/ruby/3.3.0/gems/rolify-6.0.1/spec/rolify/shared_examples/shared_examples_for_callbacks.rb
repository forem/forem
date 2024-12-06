shared_examples_for "Rolify.callbacks" do
  before(:all) do
    reset_defaults
    Rolify.dynamic_shortcuts = false
    role_class.destroy_all
  end

  after :each do
    @user.roles.destroy_all
  end

  describe "rolify association callbacks", :if => (Rolify.orm == "active_record") do
    describe "before_add" do
      it "should receive callback" do
        rolify_options = { :role_cname => role_class.to_s, :before_add => :role_callback }
        rolify_options[:role_join_table_name] = join_table if defined? join_table
        silence_warnings { user_class.rolify rolify_options }
        @user = user_class.first
        @user.stub(:role_callback)
        @user.should_receive(:role_callback)
        @user.add_role :admin
      end
    end

    describe "after_add" do
      it "should receive callback" do
        rolify_options = { :role_cname => role_class.to_s, :after_add => :role_callback }
        rolify_options[:role_join_table_name] = join_table if defined? join_table
        silence_warnings { user_class.rolify rolify_options }
        @user = user_class.first
        @user.stub(:role_callback)
        @user.should_receive(:role_callback)
        @user.add_role :admin
      end
    end

    describe "before_remove" do
      it "should receive callback" do
        rolify_options = { :role_cname => role_class.to_s, :before_remove => :role_callback }
        rolify_options[:role_join_table_name] = join_table if defined? join_table
        silence_warnings { user_class.rolify rolify_options }
        @user = user_class.first
        @user.add_role :admin
        @user.stub(:role_callback)

        @user.should_receive(:role_callback)
        @user.remove_role :admin
      end
    end

    describe "after_remove" do
      it "should receive callback" do
        rolify_options = { :role_cname => role_class.to_s, :after_remove => :role_callback }
        rolify_options[:role_join_table_name] = join_table if defined? join_table
        silence_warnings { user_class.rolify rolify_options }
        @user = user_class.first
        @user.add_role :admin
        @user.stub(:role_callback)

        @user.should_receive(:role_callback)
        @user.remove_role :admin
      end
    end
  end
end
