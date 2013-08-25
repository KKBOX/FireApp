require 'less_js'
require 'test/unit'
require 'stringio'

class TestLessJs < Test::Unit::TestCase
  def test_compile
    assert_equal ".a {\n  border: 4px;\n}\n",
      LessJs.compile(".a { border: 2px * 2;}\n")
  end

  def test_compile_with_io
    io = StringIO.new(".a { border: 2px * 2;}\n")
    assert_equal ".a {\n  border: 4px;\n}\n",
      LessJs.compile(io)
  end

  def test_compilation_error
    assert_raise LessJs::ParseError do
      LessJs.compile("&&&&.a")
    end
  end

  def assert_exception_does_not_match(pattern)
    yield
    flunk "no exception raised"
  rescue Exception => e
    assert_no_match pattern, e.message
  end
end
