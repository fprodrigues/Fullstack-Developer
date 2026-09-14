require "test_helper"
class AuthorizationTest < ActionDispatch::IntegrationTest
  ADMIN_PATHS = %w[/admin /admin/users /admin/user_imports].freeze
  test "a visitor is sent to the sign in page for every admin route" do
    ADMIN_PATHS.each do |path|
      get path
      assert_redirected_to new_session_path, "expected #{path} to require authentication"
    end
  end
  test "a regular user cannot reach any admin route" do
    sign_in_as users(:member)
    ADMIN_PATHS.each do |path|
      get path
      assert_redirected_to profile_path, "expected #{path} to be denied"
      assert_equal "You are not authorized to access that page.", flash[:alert]
    end
  end
  test "an admin can reach the admin routes" do
    sign_in_as users(:admin)
    ADMIN_PATHS.each do |path|
      get path
      assert_response :success, "expected #{path} to be allowed"
    end
  end
  test "a regular user cannot edit another user" do
    sign_in_as users(:member)
    other = users(:other)
    patch admin_user_path(other), params: { user: { full_name: "Hacked" } }
    assert_redirected_to profile_path
    assert_equal "Otto Other", other.reload.full_name
  end
  test "a regular user cannot toggle a role" do
    sign_in_as users(:member)
    patch toggle_role_admin_user_path(users(:other))
    assert_redirected_to profile_path
    assert_equal "user", users(:other).reload.role
  end
  test "a regular user cannot escalate their own role through the profile form" do
    member = users(:member)
    sign_in_as member
    patch profile_path, params: { user: { full_name: "Mia M.", role: "admin" } }
    assert_equal "user", member.reload.role
    assert_equal "Mia M.", member.full_name
  end
  test "admins land on the dashboard and users land on the profile" do
    sign_in_as users(:admin)
    assert_redirected_to admin_root_url
    sign_out
    sign_in_as users(:member)
    assert_redirected_to profile_url
  end
  test "a bad password does not create a session" do
    assert_no_difference -> { Session.count } do
      sign_in_as users(:admin), password: "wrong-password"
    end
    assert_redirected_to new_session_path
  end
end
