require "roo"
module UserImports
  class XlsxReader
    def initialize(blob)
      @blob = blob
    end

    def rows
      blob.open do |file|
        sheet = Roo::Excelx.new(file.path)
        headers = sheet.row(1).map { |header| normalize_key(header) }
        (2..sheet.last_row).filter_map do |index|
          values = sheet.row(index)
          next if values.all?(&:blank?)
          headers.zip(values.map { |value| stringify(value) }).to_h
        end
      end
    end

  private
    attr_reader :blob

    def normalize_key(key)
      key.to_s.strip.downcase.gsub(/\s+/, "_").to_sym
    end

    def stringify(value)
      case value
      when Float then value == value.to_i ? value.to_i.to_s : value.to_s
      when nil then nil
      else value.to_s.strip
      end
    end
  end
end
