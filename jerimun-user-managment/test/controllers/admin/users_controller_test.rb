require "test_helper"
module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in_as users(:admin) }
    test "lists users" do
      get admin_users_path
      assert_response :success
      assert_select "tbody tr", count: User.count
    end
    test "creates a user" do
      assert_difference -> { User.count }, 1 do
        post admin_users_path, params: { user: {
        full_name: "Created By Admin",
        email_address: "created@example.com",
        password: "password123",
        password_confirmation: "password123",
        role: "admin"
        } }
      end
      assert_redirected_to admin_users_path
      assert_equal "admin", User.find_by(email_address: "created@example.com").role
    end
    test "rejects an invalid user" do
      assert_no_difference -> { User.count } do
        post admin_users_path, params: { user: { full_name: "", email_address: "x" } }
      end
      assert_response :unprocessable_entity
    end
    test "updates a user" do
      patch admin_user_path(users(:other)), params: { user: { full_name: "Otto Renamed" } }
      assert_redirected_to admin_users_path
      assert_equal "Otto Renamed", users(:other).reload.full_name
    end
    test "deletes a user" do
      assert_difference -> { User.count }, -1 do
        delete admin_user_path(users(:other))
      end
      assert_redirected_to admin_users_path
    end
    test "toggles a role in both directions" do
      other = users(:other)
      patch toggle_role_admin_user_path(other)
      assert_equal "admin", other.reload.role
      patch toggle_role_admin_user_path(other)
      assert_equal "user", other.reload.role
    end
    test "an admin cannot delete or demote themselves" do
      admin = users(:admin)
      assert_no_difference -> { User.count } do
        delete admin_user_path(admin)
      end
      assert_equal "You cannot change your own account here.", flash[:alert]
      patch toggle_role_admin_user_path(admin)
      assert_equal "admin", admin.reload.role
    end
  end
end
