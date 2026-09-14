module UserImports
  class Processor
    class UnsupportedFormat < StandardError; end

    BROADCAST_EVERY = 25
    BROADCAST_EACH_ROW_UNTIL = 25

    READERS = {
      ".csv" => CsvReader,
      ".xlsx" => XlsxReader
    }.freeze

    def self.call(user_import)
      new(user_import).call
    end

    def initialize(user_import)
      @user_import = user_import
      @successful = 0
      @failed = 0
      @processed = 0
      @total_rows = 0
    end

    def call
      start!

      rows = reader.rows
      @total_rows = rows.size

      user_import.update!(total_rows: @total_rows)

      User.suppressing_dashboard_broadcasts do
        rows.each_with_index do |row, index|
          import_row(row)

          persist_progress if persist_progress?(index)

        end
      end

      finish!
    rescue StandardError => e
      fail!(e)
    ensure
      User.broadcast_dashboard_stats
    end

    private

    attr_reader :user_import

    def start!
      user_import.update!(
        status: :processing,
        total_rows: 0,
        processed_rows: 0,
        successful_rows: 0,
        failed_rows: 0,
        error_message: nil
      )
    end

    def import_row(row)
      user = User.new(
        full_name: row[:full_name].presence || row[:name],
        email_address: row[:email_address].presence || row[:email],
        password: row[:password].presence || SecureRandom.base58(24),
        role: role_for(row[:role])
      )

      if user.save
        @successful += 1
      else
        @failed += 1
      end
    rescue StandardError => e
      Rails.logger.warn(
        "UserImport ##{user_import.id}: row failed: " \
        "#{e.class}: #{e.message}"
      )

      @failed += 1
    ensure
      @processed += 1
    end

    def role_for(value)
      normalized = value.to_s.strip.downcase

      User.roles.key?(normalized) ? normalized : "user"
    end

    def persist_progress?(index)
      current_row = index + 1

      return true if @total_rows <= BROADCAST_EACH_ROW_UNTIL
      return true if (current_row % BROADCAST_EVERY).zero?
      return true if current_row == @total_rows

      false
    end

    def persist_progress(status: nil)
      attributes = {
        processed_rows: @processed,
        successful_rows: @successful,
        failed_rows: @failed
      }

      attributes[:status] = status if status

      user_import.update!(attributes)
    end

    def finish!
      persist_progress(status: :completed)
    end

    def fail!(error)
      Rails.logger.error(
        "UserImport ##{user_import.id} failed: " \
        "#{error.class}: #{error.message}"
      )

      user_import.update!(
        status: :failed,
        processed_rows: @processed,
        successful_rows: @successful,
        failed_rows: @failed,
        error_message: error.message.to_s.truncate(500)
      )
    end

    def reader
      klass = READERS[user_import.extension]

      unless klass
        raise UnsupportedFormat,
              "Unsupported file type: #{user_import.extension}"
      end

      klass.new(user_import.file.blob)
    end
  end
end