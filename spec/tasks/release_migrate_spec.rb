require "rails_helper"

RSpec.describe "Release migrate tasks", type: :task do
  describe "release:migrate_if_pending" do
    let(:db_migrate_task) { Rake::Task["db:migrate"] }
    let(:migration_context) { instance_double(ActiveRecord::MigrationContext) }

    before do
      Rake.application["release:migrate_if_pending"].reenable
      allow(ActiveRecord::Base.connection_pool).to receive(:migration_context).and_return(migration_context)
      allow(db_migrate_task).to receive(:invoke)
    end

    it "invokes db:migrate when migrations are pending" do
      allow(migration_context).to receive(:needs_migration?).and_return(true)

      Rake::Task["release:migrate_if_pending"].invoke

      expect(db_migrate_task).to have_received(:invoke).once
    end

    it "skips db:migrate when no migrations are pending" do
      allow(migration_context).to receive(:needs_migration?).and_return(false)

      Rake::Task["release:migrate_if_pending"].invoke

      expect(db_migrate_task).not_to have_received(:invoke)
    end
  end
end
