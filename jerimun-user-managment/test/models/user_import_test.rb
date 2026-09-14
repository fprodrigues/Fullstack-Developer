require "test_helper"
class UserImportTest < ActiveSupport::TestCase
  test "starts as pending" do
    assert csv_user_import.pending?
  end
  test "exposes the four statuses" do
    assert_equal %w[pending processing completed failed], UserImport.statuses.keys
  end
  test "moves through the status lifecycle" do
    user_import = csv_user_import
    user_import.update!(status: :processing)
    assert user_import.processing?
    assert_not user_import.finished?
    user_import.update!(status: :completed)
    assert user_import.completed?
    assert user_import.finished?
  end
  test "rejects an unknown status" do
    user_import = csv_user_import
    user_import.status = "exploded"
    assert_not user_import.valid?
  end
  test "requires an attached csv or xlsx file" do
    user_import = UserImport.new(created_by: users(:admin))
    assert_not user_import.valid?
    assert_includes user_import.errors[:file], "must be attached"
    user_import.file.attach(
    io: StringIO.new("nope"), filename: "notes.txt", content_type: "text/plain"
    )
    assert_not user_import.valid?
    assert_includes user_import.errors[:file], "must be a .csv or .xlsx file"
  end
  test "computes progress percentage safely" do
    user_import = csv_user_import
    assert_equal 0, user_import.progress_percent
    user_import.update!(total_rows: 1000, processed_rows: 780)
    assert_equal 78, user_import.progress_percent
  end
end
