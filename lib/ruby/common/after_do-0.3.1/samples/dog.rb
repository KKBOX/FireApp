require 'after_do'

class Dog
  def bark
    puts 'Woooof'
  end
end

Dog.extend AfterDo
Dog.after :bark do puts 'I just heard a dog bark!' end

dog = Dog.new
dog2 = Dog.new

dog.bark
dog2.bark
