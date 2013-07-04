require 'pathname'

module Less

  # Convert lesscss source into an abstract syntax Tree
  class Parser

    # Construct and configure new Less::Parser
    #
    # @param [Hash] options configuration options
    # @option options [Array] :paths a list of directories to search when handling \@import statements
    # @option options [String] :filename to associate with resulting parse trees (useful for generating errors)
    # @option options [TrueClass, FalseClass] :compress
    # @option options [TrueClass, FalseClass] :strictImports
    # @option options [TrueClass, FalseClass] :relativeUrls
    # @option options [String] :dumpLineNumbers one of 'mediaquery', 'comments', or 'all'
    def initialize(options = {})
      # LeSS supported _env_ options :
      # 
      # - paths (unmodified) - paths to search for imports on
      # - optimization - optimization level (for the chunker)
      # - mime (browser only) mime type for sheet import
      # - contents (browser only)
      # - strictImports
      # - dumpLineNumbers - whether to dump line numbers
      # - compress - whether to compress
      # - processImports - whether to process imports. if false then imports will not be imported
      # - relativeUrls (true/false) whether to adjust URL's to be relative
      # - errback (error callback function)
      # - rootpath string
      # - entryPath string
      # - files (internal) - list of files that have been imported, used for import-once
      # - currentFileInfo (internal) - information about the current file - 
      #   for error reporting and importing and making urls relative etc :
      #     this.currentFileInfo = {
      #        filename: filename,
      #        relativeUrls: this.relativeUrls,
      #        rootpath: options.rootpath || "",
      #        currentDirectory: entryPath,
      #        entryPath: entryPath,
      #        rootFilename: filename
      #     };
      #
      env = {}
      Less.defaults.merge(options).each do |key, val|
        env[key.to_s] = 
          case val
          when Symbol, Pathname then val.to_s
          when Array
            val.map!(&:to_s) if key.to_sym == :paths # might contain Pathname-s
            val # keep the original passed Array
          else val # true/false/String/Method
          end
      end
      @parser = Less::JavaScript.exec { Less['Parser'].new(env) }
    end

    # Convert `less` source into a abstract syntaxt tree
    # @param [String] less the source to parse
    # @return [Less::Tree] the parsed tree
    def parse(less)
      error, tree = nil, nil
      Less::JavaScript.exec do
        @parser.parse(less, lambda { |*args| # (error, tree)
          # v8 >= 0.10 passes this as first arg :
          if args.size > 2
            error, tree = args[-2], args[-1]
          elsif args.last.respond_to?(:message) && args.last.message
            # might get invoked as callback(error)
            error = args.last
          else
            error, tree = *args
          end
          fail error.message unless error.nil?
        })
      end
      Tree.new(tree) if tree
    end

    def imports
      Less::JavaScript.exec { @parser.imports.files.map { |file, _| file } }
    end

    private

    # Abstract LessCSS syntax tree Less. Mainly used to emit CSS
    class Tree

      # Create a tree from a native javascript object.
      # @param [V8::Object] tree the native less.js tree
      def initialize(tree)
        @tree = tree
      end

      # Serialize this tree into CSS.
      # By default this will be in pretty-printed form.
      # @param [Hash] opts modifications to the output
      # @option opts [Boolean] :compress minify output instead of pretty-printing
      def to_css(options = {})
        Less::JavaScript.exec { @tree.toCSS(options) }
      end

    end

  end

end
