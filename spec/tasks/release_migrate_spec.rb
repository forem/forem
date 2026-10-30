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

    it "logs a warning and falls back to invoking db:migrate if needs_migration? raises an error" do
      allow(migration_context).to receive(:needs_migration?).and_raise(StandardError, "unexpected migration error")
      allow(Rails.logger).to receive(:warn)

      Rake::Task["release:migrate_if_pending"].invoke

      expect(db_migrate_task).to have_received(:invoke).once
      expect(Rails.logger).to have_received(:warn).with(
        a_string_including("[release:migrate_if_pending] Falling back to db:migrate"),
      )
    end
  end

  describe "app_initializer:setup migration guard" do
    let(:setup_task) { Rake::Task["app_initializer:setup"] }
    let(:release_migrate_task) { Rake::Task["release:migrate_if_pending"] }

    before do
      setup_task.reenable
      allow(Rake::Task["forem:setup"]).to receive(:execute)
      allow(Rake::Task["data_updates:enqueue_data_update_worker"]).to receive(:execute)
      allow(Rake::Task["cache:clear_app_cache"]).to receive(:execute)
      allow(Rake::Task["cache:enqueue_path_bust_workers"]).to receive(:execute)
      allow(release_migrate_task).to receive(:invoke)
    end

    it "skips spawning bin/rails db:prepare and release:migrate_if_pending when no migrations are pending" do
      allow(ReleaseMigrate).to receive(:needs_migration?).and_return(false)
      allow(Kernel).to receive(:system)

      expect { setup_task.invoke }.to output(/== Preparing database ==/).to_stdout

      expect(ReleaseMigrate).to have_received(:needs_migration?).once
      expect(Kernel).not_to have_received(:system)
      expect(release_migrate_task).not_to have_received(:invoke)
    end

    it "runs bin/rails db:prepare and invokes release:migrate_if_pending when migrations are pending" do
      allow(ReleaseMigrate).to receive(:needs_migration?).and_return(true)
      allow(Kernel).to receive(:system).with("bin/rails db:prepare").and_return(true)

      expect { setup_task.invoke }.to output(/== Preparing database ==/).to_stdout

      expect(Kernel).to have_received(:system).with("bin/rails db:prepare").once
      expect(release_migrate_task).to have_received(:invoke).once
    end
  end
end
