require 'after_do'

module M
  def self.magic
    puts 'magic'
  end
end

M.singleton_class.extend AfterDo
M.singleton_class.after :magic do puts 'after_do is pure magic' end

M.magic
M.magic