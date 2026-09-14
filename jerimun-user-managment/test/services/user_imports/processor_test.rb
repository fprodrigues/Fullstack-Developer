require "test_helper"
module UserImports
  class ProcessorTest < ActiveSupport::TestCase
    test "creates users from a CSV and counts failures without aborting" do
      user_import = csv_user_import
      assert_difference -> { User.count }, 2 do
        Processor.call(user_import)
      end
      user_import.reload
      assert_equal 3, user_import.total_rows
      assert_equal 3, user_import.processed_rows
      assert_equal 2, user_import.successful_rows
      assert_equal 1, user_import.failed_rows
      assert user_import.completed?
      assert_equal 100, user_import.progress_percent
    end
    test "normalizes imported email addresses and honours the role column" do
      Processor.call(csv_user_import)
      assert User.exists?(email_address: "valid.two@example.com")
      assert_equal "admin", User.find_by(email_address: "valid.two@example.com").role
    end
    test "moves the import through processing to completed" do
      user_import = csv_user_import
      statuses = []
      # Cada update! do Processor dispara after_update_commit; observamos as transições.
      user_import.define_singleton_method(:broadcast_progress) do
        statuses << status
      end
      Processor.call(user_import)
      assert_includes statuses, "processing"
      assert_equal "completed", statuses.last
    end
    test "imports an XLSX file" do
      user_import = xlsx_user_import(rows: [
      %w[full_name email_address password role],
      [ "Excel One", "excel.one@example.com", "password123", "user" ],
      [ "", "still-not-an-email", "password123", "user" ],
      [ "Excel Two", "excel.two@example.com", "password123", "admin" ]
      ])
      assert_difference -> { User.count }, 2 do
        Processor.call(user_import)
      end
      user_import.reload
      assert user_import.completed?
      assert_equal 2, user_import.successful_rows
      assert_equal 1, user_import.failed_rows
      assert User.exists?(email_address: "excel.one@example.com")
    end
    test "accepts name/email as column aliases" do
      user_import = xlsx_user_import(rows: [
      %w[Name Email],
      [ "Alias Person", "alias.person@example.com" ]
      ])
      Processor.call(user_import)
      assert User.exists?(email_address: "alias.person@example.com")
    end
    test "marks the import as failed when the file cannot be read" do
      user_import = csv_user_import
      user_import.file.attach(
        io: StringIO.new("this is not a valid spreadsheet"),
        filename: "users.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
      Processor.call(user_import)
      assert user_import.reload.failed?
      assert user_import.error_message.present?
    end
  end
end
