module LiveScript
  module Source
    def self.bundled_path
      File.expand_path("../livescript.js", __FILE__)
    end
  end
end
