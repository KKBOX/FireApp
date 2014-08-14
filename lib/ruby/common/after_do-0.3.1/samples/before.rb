require 'after_do'

class MyClass
  attr_accessor :value
end

MyClass.extend AfterDo
MyClass.after :value= do |*, obj| puts 'after: ' + obj.value.to_s end
MyClass.before :value= do |*, obj| puts 'before: ' + obj.value.to_s end

m = MyClass.new
m.value = 'Hello'
m.value = 'new value'

# Output is:
# before:
# after: Hello
# before: Hello
# after: new value
