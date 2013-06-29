require 'bacon'
require 'temple'

class HtmlSafeString < String
  def html_safe?
    true
  end

  def to_s
    self
  end
end

module TestHelper
  def with_html_safe
    String.send(:define_method, :html_safe?) { false }
    String.send(:define_method, :html_safe) { HtmlSafeString.new(self) }
    yield
  ensure
    String.send(:undef_method, :html_safe?) if String.method_defined?(:html_safe?)
    String.send(:undef_method, :html_safe) if String.method_defined?(:html_safe)
  end

  def grammar_validate(grammar, exp, message)
    lambda { grammar.validate!(exp) }.should.raise(Temple::InvalidExpression).message.should.equal message
  end

  def erb(src, options = {})
    Temple::ERB::Template.new(options) { src }.render
  end
end

class Bacon::Context
  include TestHelper
end
