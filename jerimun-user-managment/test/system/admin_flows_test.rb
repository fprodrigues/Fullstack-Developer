require "application_system_test_case"
class AdminFlowsTest < ApplicationSystemTestCase
  test "an admin signs in, sees the dashboard and creates a user" do
    sign_in_through_ui users(:admin)
    assert_current_path admin_root_path
    assert_selector "#stat_total", text: User.count.to_s
    click_on "Users"
    click_on "New user"
    fill_in "Full name", with: "Created In Browser"
    fill_in "Email address", with: "browser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_on "Create User"
    assert_text "User created."
    assert_text "Created In Browser"
  end
  test "an admin uploads a spreadsheet and sees the import page" do
    sign_in_through_ui users(:admin)
    assert_current_path admin_root_path
    visit new_admin_user_import_path
    attach_file "user_import_file", Rails.root.join("test/fixtures/files/users.csv")
    click_on "Start import"
    assert_text "Import queued"
    assert_selector "#user_import_progress"
    assert_text "users.csv"
  end
end
