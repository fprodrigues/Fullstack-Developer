class UserImport < ApplicationRecord
  ALLOWED_EXTENSIONS = %w[.csv .xlsx].freeze

  belongs_to :created_by, class_name: "User"

  has_one_attached :file

  enum :status,
       {
         pending: "pending",
         processing: "processing",
         completed: "completed",
         failed: "failed"
       },
       default: :pending,
       validate: true,
       scopes: false

  validate :acceptable_file

  after_update_commit :broadcast_progress, if: :progress_changed?

  def extension
    File.extname(file.filename.to_s).downcase
  end

  def filename
    file.attached? ? file.filename.to_s : "(no file)"
  end

  def progress_percent
    return 0 if total_rows.to_i.zero?

    ((processed_rows.to_f / total_rows) * 100)
      .round
      .clamp(0, 100)
  end

  def finished?
    completed? || failed?
  end

  private

  def acceptable_file
    return errors.add(:file, "must be attached") unless file.attached?

    unless ALLOWED_EXTENSIONS.include?(extension)
      errors.add(:file, "must be a .csv or .xlsx file")
    end
  end

  def progress_changed?
    saved_change_to_total_rows? ||
      saved_change_to_processed_rows? ||
      saved_change_to_successful_rows? ||
      saved_change_to_failed_rows? ||
      saved_change_to_status? ||
      saved_change_to_error_message?
  end

  def broadcast_progress
    broadcast_replace_to(
      self,
      target: "user_import_progress",
      partial: "admin/user_imports/progress",
      locals: { user_import: self }
    )
  end
end