require "caxlsx"
module ImportTestHelper
  def csv_user_import(fixture: "users.csv", created_by: users(:admin))
    user_import = UserImport.new(created_by: created_by)
    user_import.file.attach(
    io: Rails.root.join("test/fixtures/files", fixture).open,
    filename: fixture,
    content_type: "text/csv"
    )
    user_import.save!
    user_import
  end

  def xlsx_user_import(rows:, created_by: users(:admin))
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "Users") do |sheet|
      rows.each { |row| sheet.add_row(row) }
    end
    tempfile = Tempfile.new(%w[users .xlsx], binmode: true)
    tempfile.write(package.to_stream.read)
    tempfile.rewind
    user_import = UserImport.new(created_by: created_by)
    user_import.file.attach(
    io: tempfile,
    filename: "users.xlsx",
    content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
    user_import.save!
    user_import
  end
end
