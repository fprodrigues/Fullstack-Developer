require "test_helper"
class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:member) }
  test "shows the signed-in user's own profile" do
    get profile_path
    assert_response :success
    assert_select "h1", text: users(:member).full_name
  end
  test "updates the signed-in user's own profile" do
    patch profile_path, params: { user: { full_name: "Mia Updated" } }
    assert_redirected_to profile_path
    assert_equal "Mia Updated", users(:member).reload.full_name
  end
  test "keeps the current password when the field is left blank" do
    digest_before = users(:member).password_digest
    patch profile_path, params: { user: { full_name: "Mia", password: "", password_confirmation: "" } }
    assert_equal digest_before, users(:member).reload.password_digest
  end
  test "rejects invalid input" do
    patch profile_path, params: { user: { email_address: "broken" } }
    assert_response :unprocessable_entity
  end
  test "deletes the signed-in user's own account and ends the session" do
    assert_difference -> { User.count }, -1 do
      delete profile_path
    end
    assert_redirected_to root_path
    get profile_path
    assert_redirected_to new_session_path
  end
end
