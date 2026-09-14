require "test_helper"
module Admin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in_as users(:admin) }
    test "renders the live counters" do
      get admin_root_path
      assert_response :success
      assert_select "#stat_total", text: User.count.to_s
      assert_select "#stat_admins", text: User.admins.count.to_s
      assert_select "#stat_users", text: User.regular.count.to_s
    end
    test "subscribes to the dashboard stream" do
      get admin_root_path
      assert_select "turbo-cable-stream-source"
    end
  end
end
