require 'after_do'

class A
  def work
    # ..
  end
end

A.extend AfterDo
A.after :work do 1/0 end

A.new.work