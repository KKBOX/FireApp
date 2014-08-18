require 'after_do'

class A
  def a
    # ...
  end
end

class B < A
end

A.extend AfterDo
A.after :a do puts 'a was called' end

b = B.new
b.a #prints out: a was called
