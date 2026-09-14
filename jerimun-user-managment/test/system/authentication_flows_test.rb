require "application_system_test_case"
class AuthenticationFlowsTest < ApplicationSystemTestCase
  test "a visitor registers and lands on their profile as a regular user" do
    visit new_registration_path
    fill_in "Full name", with: "Sam Signup"
    fill_in "Email address", with: "sam.signup@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_on "Create account"
    assert_current_path profile_path
    assert_text "Sam Signup"
    assert_text "USER"
  end
  test "a regular user signs in and is sent to the profile page" do
    sign_in_through_ui users(:member)
    assert_current_path profile_path
    assert_text "Cabra member"
    assert_no_link "Dashboard"
  end
end
