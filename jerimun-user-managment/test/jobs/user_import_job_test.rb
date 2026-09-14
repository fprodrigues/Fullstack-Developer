require "test_helper"
class UserImportJobTest < ActiveJob::TestCase
  test "runs the processor and completes the import" do
    user_import = csv_user_import
    perform_enqueued_jobs do
      UserImportJob.perform_later(user_import.id)
    end
    assert user_import.reload.completed?
  end
  test "discards the job when the import no longer exists" do
    assert_nothing_raised do
      perform_enqueued_jobs { UserImportJob.perform_later(-1) }
    end
  end
end
