class User < ApplicationRecord
  ROLES = %w[user admin].freeze
  AVATAR_CONTENT_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  AVATAR_MAX_SIZE = 5.megabytes
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :user_imports, foreign_key: :created_by_id,
  inverse_of: :created_by, dependent: :destroy
  has_one_attached :avatar_image
  enum :role, { user: "user", admin: "admin" },
  default: :user, validate: true, scopes: false
  normalizes :email_address, with: ->(email) { email.to_s.strip.downcase }
  validates :full_name, presence: true, length: { maximum: 120 }
  validates :email_address,
  presence: true,
  uniqueness: { case_sensitive: false },
  format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :acceptable_avatar_image
  after_commit :broadcast_dashboard_stats, on: %i[create destroy]
  after_commit :broadcast_dashboard_stats, on: :update, if: :saved_change_to_role?
  scope :admins, -> { where(role: "admin") }
  scope :regular, -> { where(role: "user") }
  class << self
    def dashboard_stats
      counts = group(:role).count
      {
      total: counts.values.sum,
      admins: counts["admin"].to_i,
      users: counts["user"].to_i
      }
    end

    def broadcast_dashboard_stats
      Turbo::StreamsChannel.broadcast_replace_to(
      "admin_dashboard",
      target: "dashboard_stats",
      partial: "admin/dashboard/stats",
      locals: { stats: dashboard_stats }
      )
    end

    def suppressing_dashboard_broadcasts
      previous = Thread.current[:suppress_dashboard_broadcasts]
      Thread.current[:suppress_dashboard_broadcasts] = true
      yield
    ensure
      Thread.current[:suppress_dashboard_broadcasts] = previous
    end

    def dashboard_broadcasts_suppressed?
      Thread.current[:suppress_dashboard_broadcasts].present?
    end
  end

  def initials
    full_name.to_s.split.first(2).map { |part| part[0] }.join.upcase
  end

  private

  def broadcast_dashboard_stats
    return if self.class.dashboard_broadcasts_suppressed?
    self.class.broadcast_dashboard_stats
  end

  def acceptable_avatar_image
    return unless avatar_image.attached?
    unless AVATAR_CONTENT_TYPES.include?(avatar_image.content_type)
      errors.add(:avatar_image, "must be a PNG, JPEG, WEBP or GIF")
    end
    if avatar_image.byte_size > AVATAR_MAX_SIZE
      errors.add(:avatar_image, "must be smaller than 5MB")
    end
  end
end
