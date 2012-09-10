require 'stringio'

module YUICompressor
  # The path to the YUI Compressor jar file.
  JAR_FILE = File.expand_path('../yuicompressor-2.4.4.jar', __FILE__)

  module_function

  # Returns +true+ if the Ruby platform is JRuby.
  def jruby?
    !! (RUBY_PLATFORM =~ /java/)
  end

  # Compress the given CSS +stream_or_string+ using the given +options+.
  # Options should be a Hash with any of the following keys:
  #
  # +:line_break+::   The maximum number of characters that may appear in a
  #                   single line of compressed code. Defaults to no maximum
  #                   length. If set to 0 each line will be the minimum length
  #                   possible.
  def compress_css(stream_or_string, options={}, &block)
    compress(stream_or_string, options.merge(:type => 'css'), &block)
  end

  # Compress the given JavaScript +stream_or_string+ using the given +options+.
  # Options should be a Hash with any of the following keys:
  #
  # +:line_break+::   The maximum number of characters that may appear in a
  #                   single line of compressed code. Defaults to no maximum
  #                   length. If set to 0 each line will be the minimum length
  #                   possible.
  # +:munge+::        Should be +true+ if the compressor should shorten local
  #                   variable names when possible. Defaults to +false+.
  # +:preserve_semicolons+::  Should be +true+ if the compressor should preserve
  #                           all semicolons in the code. Defaults to +false+.
  # +:optimize+::     Should be +true+ if the compressor should enable all
  #                   micro optimizations. Defaults to +true+.
  def compress_js(stream_or_string, options={}, &block)
    compress(stream_or_string, options.merge(:type => 'js'), &block)
  end

  def default_css_options #:nodoc:
    { :line_break => nil }
  end

  def default_js_options #:nodoc:
    default_css_options.merge(
      :munge => false,
      :preserve_semicolons => false,
      :optimize => true
    )
  end

  def streamify(stream_or_string) #:nodoc:
    if IO === stream_or_string || StringIO === stream_or_string
      stream_or_string
    elsif String === stream_or_string
      StringIO.new(stream_or_string.to_s)
    else
      raise ArgumentError, 'Stream or string required'
    end
  end

  # If we're on JRuby we can use the YUI Compressor Java classes directly. This
  # gives a huge speed boost. Otherwise we need to make a system call to the
  # Java interpreter and stream IO to/from the shell.
  if jruby?
    require 'yuicompressor/jruby'
  else
    require 'yuicompressor/shell'
  end
end
