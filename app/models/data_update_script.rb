class DataUpdateScript < ApplicationRecord
  DIRECTORY = Rails.root.join("lib/data_update_scripts").freeze
  NAMESPACE = "DataUpdateScripts".freeze
  STATUSES = { enqueued: 0, working: 1, succeeded: 2, failed: 3 }.freeze
  resourcify

  enum status: STATUSES

  validates :file_name, presence: true, uniqueness: true
  validates :status, presence: true

  class << self
    def scripts_to_run
      insert_new_scripts

      enqueued.order(file_name: :asc)
    end

    # true if there are more files on disk or any scripts to run, false otherwise
    def scripts_to_run?
      db_scripts = DataUpdateScript.pluck(:file_name, :status).to_h

      return true if filenames.size > db_scripts.size
      return true if db_scripts.values.any? { |s| s.to_sym == :enqueued }

      false
    end

    private

    def filenames
      Dir.glob("*.rb", base: DIRECTORY).map do |f|
        File.basename(f, ".rb")
      end
    end

    def insert_new_scripts
      now = Time.current
      scripts_params = filenames.map do |fn|
        { file_name: fn, created_at: now, updated_at: now }
      end

      DataUpdateScript.insert_all(scripts_params)
    end
  end

  def mark_as_run!
    update!(run_at: Time.current, status: :working)
  end

  def mark_as_finished!
    update!(finished_at: Time.current, status: :succeeded, error: nil)
  end

  def mark_as_failed!(err)
    update!(
      finished_at: Time.current,
      status: :failed,
      error: "#{err.class}: #{err.message}",
    )
  end

  def file_path
    "#{self.class::DIRECTORY}/#{file_name}.rb"
  end

  def file_class
    "#{self.class::NAMESPACE}::#{parsed_file_name.camelcase}".safe_constantize
  end

  private

  def parsed_file_name
    file_name.match(/\d{14}_(.*)/)[1]
  end
end
