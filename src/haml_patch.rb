# http://haml.info/docs/yardoc/file.HAML_REFERENCE.html#markdown-filter
# But Fire.app use kramdown
module Haml
  module Filters
    
    module Markdown
      def render(text)
        ::Kramdown::Document.new(text, :input => 'markdown').to_html
      end 
    end 

    module Kramdown
      include Base
      def render(text)
        ::Kramdown::Document.new(text).to_html
      end
    end

  end
end
