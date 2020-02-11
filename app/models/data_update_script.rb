class DataUpdateScript < ApplicationRecord
  DIRECTORY = Rails.root.join("lib/data_update_scripts").freeze
  NAMESPACE = "DataUpdateScripts".freeze
  STATUSES = %i[enqueued working succeeded failed].freeze

  enum status: STATUSES
  validates :file_name, uniqueness: true

  def self.filenames
    Pathname.
      new(self::DIRECTORY).
      children.
      select { |path| path.file? && path.extname == ".rb" }.
      map { |path| path.basename(".rb").to_s }
  end

  def self.load_script_ids
    filenames.
      map { |file_name| find_or_create_by(file_name: file_name) }.
      select(&:enqueued?).
      map(&:id)
  end

  def mark_as_run!
    update!(run_at: Time.now.utc, status: :working)
  end

  def mark_as_finished!
    update!(finished_at: Time.now.utc, status: :succeeded)
  end

  def mark_as_failed!
    update!(finished_at: Time.now.utc, status: :failed)
  end

  def file_class
    "#{self.class::NAMESPACE}::#{file_name.camelcase}".constantize
  end
end
