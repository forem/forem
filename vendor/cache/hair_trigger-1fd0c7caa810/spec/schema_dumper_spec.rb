require 'spec_helper'

# for this spec to work, you need to have postgres and mysql installed (in
# addition to the gems), and you should make sure that you have set up
# appropriate users and permissions. see database.yml for more info

describe "schema dumping" do
  include_context "hairtrigger utils"

  each_adapter do
    before do
      reset_tmp
      initialize_db
      migrate_db
      db_triggers.grep(/bob_count \+ 1/).size.should eql(1)
    end

    context "without schema.rb" do
      it "should work" do
        schema_rb = dump_schema
        schema_rb.should match(/create_trigger\("users_after_insert_row_when_new_name_bob__tr", :generated => true, :compatibility => 1\)/)
        schema_rb.should match(/create_trigger\("users_after_update_row_when_new_name_joe__tr", :compatibility => 1\)/)
      end

      it "should create adapter-specific triggers if no migrations exist" do
        FileUtils.rm_rf(Dir.glob('tmp/migrations/*rb'))
        schema_rb = dump_schema
        schema_rb.should_not match(/create_trigger\(/)
        schema_rb.should match(/no candidate create_trigger statement could be found, creating an adapter-specific one/)
      end

      it "should not dump triggers in migrations that haven't run" do
        # edit our model trigger, generate a new migration
        replace_file_contents HairTrigger.model_path + '/user.rb',
          '"UPDATE user_groups SET bob_count = bob_count + 1"',
          '{:default => "UPDATE user_groups SET bob_count = bob_count + 2"}'
        reset_models

        HairTrigger.should_not be_migrations_current
        migration = HairTrigger.generate_migration
        HairTrigger.should be_migrations_current

        schema_rb = dump_schema
        schema_rb.should match(/bob_count \+ 1/)
        schema_rb.should_not match(/bob_count \+ 2/)
      end

      it 'should take in consideration active record schema dumper ignore_tables option with regexp' do
        ActiveRecord::SchemaDumper.ignore_tables = [/users/]

        dump_schema.should_not match(/create_trigger/)
      end

      it 'should take in consideration active record schema dumper ignore_tables option with string' do
        ActiveRecord::SchemaDumper.ignore_tables = ['users']

        dump_schema.should_not match(/create_trigger/)
      end

      it 'should take in consideration active record schema dumper ignore_tables option with partial string' do
        ActiveRecord::SchemaDumper.ignore_tables = ['user']

        dump_schema.should match(/create_trigger/)
      end


    end

    context "with schema.rb" do
      before do
        ActiveRecord::SchemaDumper.previous_schema = dump_schema
      end

      it "should work" do
        schema_rb = dump_schema
        schema_rb.should match(/create_trigger\("users_after_insert_row_when_new_name_bob__tr", :generated => true, :compatibility => 1\)/)
        schema_rb.should match(/create_trigger\("users_after_update_row_when_new_name_joe__tr", :compatibility => 1\)/)
      end

      it "should still work even if migrations have been deleted" do
        FileUtils.rm_rf(Dir.glob('tmp/migrations/*rb'))
        schema_rb = dump_schema
        schema_rb.should match(/create_trigger\("users_after_insert_row_when_new_name_bob__tr", :generated => true, :compatibility => 1\)/)
        schema_rb.should match(/create_trigger\("users_after_update_row_when_new_name_joe__tr", :compatibility => 1\)/)
      end

      it "should evaluate all migrations even if they haven't run" do
        # edit our model trigger, generate a new migration
        replace_file_contents HairTrigger.model_path + '/user.rb',
          '"UPDATE user_groups SET bob_count = bob_count + 1"',
          '{:default => "UPDATE user_groups SET bob_count = bob_count + 2"}'
        reset_models

        HairTrigger.should_not be_migrations_current
        migration = HairTrigger.generate_migration
        HairTrigger.should be_migrations_current

        schema_rb = dump_schema
        schema_rb.should match(/bob_count \+ 1/)
        schema_rb.should_not match(/bob_count \+ 2/)
      end

      it 'should take in consideration active record schema dumper ignore_tables option with regexp' do
        ActiveRecord::SchemaDumper.ignore_tables = [/users/]

        dump_schema.should_not match(/create_trigger/)
      end

      it 'should take in consideration active record schema dumper ignore_tables option with string' do
        ActiveRecord::SchemaDumper.ignore_tables = ['users']

        dump_schema.should_not match(/create_trigger/)
      end

      it 'should take in consideration active record schema dumper ignore_tables option with partial string' do
        ActiveRecord::SchemaDumper.ignore_tables = ['user']

        dump_schema.should match(/create_trigger/)
      end

    end

  end
end
