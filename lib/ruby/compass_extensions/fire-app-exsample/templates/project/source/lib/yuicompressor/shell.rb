require 'open3'

module YUICompressor
  # This file contains methods that allow the YUI Compressor to be used by
  # piping IO to a separate Java process via the system shell. It is used on all
  # Ruby platforms except for JRuby.

  module_function

  # Returns an array of flags that should be passed to the jar file on the
  # command line for the given set of +options+.
  def command_arguments(options={})
    args = []
    args.concat(['--type', options[:type].to_s]) if options[:type]
    args.concat(['--line-break', options[:line_break].to_s]) if options[:line_break]

    if options[:type].to_s == 'js'
      args << '--nomunge' unless options[:munge]
      args << '--preserve-semi' if options[:preserve_semicolons]
      args << '--disable-optimizations' unless options[:optimize]
    end

    args
  end

  # Returns a compressed version of the given +stream_or_string+ of code using
  # the given +options+. When using this method directly, at least the
  # <tt>:type</tt> option must be specified, and should be one of <tt>"css"</tt>
  # or <tt>"js"</tt>. See YUICompressor#compress_css and
  # YUICompressor#compress_js for details about which options are acceptable for
  # each type of compressor.
  #
  # In addition to the standard options, this method also accepts a
  # <tt>:java</tt> option that can be used to specify the location of the Java
  # executable. This option will default to using <tt>"java"</tt> unless
  # otherwise specified.
  def compress(stream_or_string, options={})
    raise ArgumentError, 'Option :type required' unless options.key?(:type)

    stream = streamify(stream_or_string)

    case options[:type].to_s
    when 'js'
      options = default_js_options.merge(options)
    when 'css'
      options = default_css_options.merge(options)
    else
      raise ArgumentError, 'Unknown resource type: %s' % options[:type]
    end

    command = [ options.delete(:java) || 'java', '-jar', JAR_FILE ]
    command.concat(command_arguments(options))

    Open3.popen3(command.join(' ')) do |input, output, stderr|
      begin
        while buffer = stream.read(4096)
          input.write(buffer)
        end
        input.close_write

        output.read
      rescue Exception => e
        raise 'Compression failed: %s' % e
      end
    end
  end
end
