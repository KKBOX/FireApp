require 'after_do'

module M
  def method
  end
end

class A
  include M
end

class B
  include M
end

class C
  include M

  def method
    puts 'Overwritten method'
  end
end

M.extend AfterDo
M.after :method do puts 'method called' end

A.new.method
B.new.method
C.new.method # won't call callback since the implementation was overriden

# Output is:
# method called
# method called
# Overridden method