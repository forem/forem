class DataUpdateScript < ApplicationRecord
  DIRECTORY = Rails.root.join("lib/data_update_scripts").freeze
  NAMESPACE = "DataUpdateScripts".freeze
  STATUSES = { enqueued: 0, working: 1, succeeded: 2, failed: 3 }.freeze

  default_scope { order(file_name: :asc) }

  enum status: STATUSES
  validates :file_name, uniqueness: true

  class << self
    def filenames
      Dir.glob("*.rb", base: DIRECTORY).map do |f|
        Pathname.new(f).basename(".rb").to_s
      end
    end

    def load_script_ids
      filenames.
        map { |file_name| find_or_create_by(file_name: file_name) }.
        select(&:enqueued?).
        map(&:id)
    end

    def scripts_to_run
      DataUpdateScript.where(id: load_script_ids).select(&:enqueued?)
    end

    # true if there are more files on disk or any scripts to run, false otherwise
    def scripts_to_run?
      db_scripts = DataUpdateScript.pluck(:file_name, :status).to_h

      return true if filenames.size > db_scripts.size
      return true if db_scripts.values.any? { |s| s.to_sym == :enqueued }

      false
    end
  end

  def mark_as_run!
    update!(run_at: Time.current, status: :working)
  end

  def mark_as_finished!
    update!(finished_at: Time.current, status: :succeeded)
  end

  def mark_as_failed!
    update!(finished_at: Time.current, status: :failed)
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
