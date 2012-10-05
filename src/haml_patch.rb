# http://haml.info/docs/yardoc/file.HAML_REFERENCE.html#markdown-filter
# But Fire.app use kramdown
module Haml
  module Filters
    module Markdown
      puts 'zzzzzz'
      def render(text)
        ::Kramdown::Document.new(text).to_html
      end 
    end 
  end
end
