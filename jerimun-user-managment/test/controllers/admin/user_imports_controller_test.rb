require "test_helper"
module Admin
  class UserImportsControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in_as users(:admin) }
    test "uploading a spreadsheet creates the record and enqueues the job" do
      assert_difference -> { UserImport.count }, 1 do
        assert_enqueued_with(job: UserImportJob) do
          post admin_user_imports_path, params: { user_import: {
          file: fixture_file_upload("users.csv", "text/csv")
          } }
        end
      end
      user_import = UserImport.order(:id).last
      assert user_import.pending?
      assert_equal users(:admin), user_import.created_by
      assert_redirected_to admin_user_import_path(user_import)
    end
    test "rejects an unsupported file type without enqueuing anything" do
      assert_no_enqueued_jobs only: UserImportJob do
        post admin_user_imports_path, params: { user_import: {
          file: fixture_file_upload("users.txt", "text/plain")
        } }
      end
      assert_response :unprocessable_entity
    end
    test "shows the progress panel subscribed to the import stream" do
      user_import = csv_user_import
      get admin_user_import_path(user_import)
      assert_response :success
      assert_select "turbo-cable-stream-source"
      assert_select "#user_import_progress"
    end
    test "lists imports" do
      csv_user_import
      get admin_user_imports_path
      assert_response :success
    end
  end
end
