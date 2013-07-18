module LessJs
  module Source
    def self.bundled_path
      File.expand_path("../less.js", __FILE__)
    end
  end
end
