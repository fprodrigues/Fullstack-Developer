require "test_helper"
class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "renders the registration form to a visitor" do
    get new_registration_path
    assert_response :success
  end
  test "public registration creates a signed-in regular user" do
    assert_difference -> { User.count }, 1 do
      post registration_path, params: { user: valid_attributes }
    end
    user = User.order(:id).last
    assert_equal "user", user.role
    assert_redirected_to profile_path
  end
  test "a forged role parameter is ignored" do
    post registration_path, params: { user: valid_attributes(role: "admin") }
    assert_equal "user", User.order(:id).last.role
  end
  test "the email address is normalized on registration" do
    post registration_path, params: { user: valid_attributes(email_address: " NEW@Example.COM ") }
    assert_equal "new@example.com", User.order(:id).last.email_address
  end
  test "invalid input re-renders the form" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: valid_attributes(email_address: "nope") }
    end
    assert_response :unprocessable_entity
  end
private
  def valid_attributes(**overrides)
    {
    full_name: "New Person",
    email_address: "new@example.com",
    password: "password123",
    password_confirmation: "password123"
    }.merge(overrides)
  end
end
