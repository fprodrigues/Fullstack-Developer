require "csv"
module UserImports
  class CsvReader
    def initialize(blob)
      @blob = blob
    end
    def rows
      CSV.parse(content, headers: true).filter_map do |row|
        hash = row.to_h
        next if hash.values.all?(&:blank?)
        hash.transform_keys { |key| normalize_key(key) }
      end
    end
  private
    attr_reader :blob
    def content
      blob.download
      .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      .delete_prefix("\uFEFF") # BOM do Excel
    end
    def normalize_key(key)
      key.to_s.strip.downcase.gsub(/\s+/, "_").to_sym
    end
  end
end
