require "test_helper"
class UserTest < ActiveSupport::TestCase
  test "requires a full name" do
    user = build_user(full_name: "")
    assert_not user.valid?
    assert_includes user.errors[:full_name], "can't be blank"
  end
  test "requires an email address" do
    user = build_user(email_address: "")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end
  test "rejects a malformed email address" do
    user = build_user(email_address: "not-an-email")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "is invalid"
  end
  test "rejects a duplicate email address regardless of case" do
    user = build_user(email_address: "ADMIN@EXAMPLE.COM")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end
  test "normalizes the email address to lowercase and trims it" do
    user = build_user(email_address: " MiXeD@Example.COM ")
    assert user.save
    assert_equal "mixed@example.com", user.email_address
  end
  test "defaults the role to user" do
    user = build_user
    assert user.save
    assert_equal "user", user.role
    assert user.user?
    assert_not user.admin?
  end
  test "rejects an unknown role instead of raising" do
    user = build_user(role: "superuser")
    assert_not user.valid?
    assert_includes user.errors[:role], "is not included in the list"
  end
  test "requires a password of at least 8 characters" do
    user = build_user(password: "short", password_confirmation: "short")
    assert_not user.valid?
  end
  test "dashboard_stats counts totals, admins and regular users" do
    stats = User.dashboard_stats
    assert_equal User.count, stats[:total]
    assert_equal User.admins.count, stats[:admins]
    assert_equal User.regular.count, stats[:users]
  end
  test "rejects an avatar with an unsupported content type" do
    user = build_user
    user.avatar_image.attach(
    io: StringIO.new("not really a pdf"),
    filename: "cv.pdf",
    content_type: "application/pdf"
    )
    assert_not user.valid?
    assert_includes user.errors[:avatar_image], "must be a PNG, JPEG, WEBP or GIF"
  end
private
  def build_user(**overrides)
    User.new({
    full_name: "Test Person",
    email_address: "test.person@example.com",
    password: "password123",
    password_confirmation: "password123"
    }.merge(overrides))
  end
end
