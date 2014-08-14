require 'after_do'

class Example
  def zero
    # ...
  end

  def two(a, b)
    # ...
  end

  def value
    'some value'
  end
end

Example.extend AfterDo

Example.after :zero do puts 'Hello!' end
Example.after :zero do |obj| puts obj.value end
Example.after :two do |first, second| puts first + ' ' + second end
Example.after :two do |a, b, obj| puts a + ' ' + b + ' ' + obj.value end
Example.after :two do |*, obj| puts 'just ' +  obj.value end

e = Example.new
e.zero
e.two 'one', 'two'
# prints:
# Hello!
# some value
# one two
# one two some value
# just some value