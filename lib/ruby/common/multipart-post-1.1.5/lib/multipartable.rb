#--
# Copyright (c) 2007-2012 Nick Sieger.
# See the file README.txt included with the distribution for
# software license details.
#++

require 'parts'
  module Multipartable
    DEFAULT_BOUNDARY = "-----------RubyMultipartPost"
    def initialize(path, params, headers={}, boundary = DEFAULT_BOUNDARY)
      super(path, headers)
      parts = params.map {|k,v| Parts::Part.new(boundary, k, v)}
      parts << Parts::EpiloguePart.new(boundary)
      ios = parts.map{|p| p.to_io }
      self.set_content_type(headers["Content-Type"] || "multipart/form-data",
                            { "boundary" => boundary })
      self.content_length = parts.inject(0) {|sum,i| sum + i.length }
      self.body_stream = CompositeReadIO.new(*ios)
    end
  end
