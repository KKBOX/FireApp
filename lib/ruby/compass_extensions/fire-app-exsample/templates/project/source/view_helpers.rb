require "./lib/yuicompressor/jruby"
def minify_js(file)
  YUICompressor.compress_js(File.new(File.expand_path(file, __FILE__), 'r'), :munge => true, :optimize => true)
end
