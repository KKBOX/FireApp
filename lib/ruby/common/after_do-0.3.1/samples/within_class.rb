require 'after_do'

class Team
  extend AfterDo
  
  def add_member(member)
    # ...
  end
  
  def remove_member(member)
    # ..
  end
  
  def change_name(new_name)
    # ..
  end
  
  def save
   # ..
   puts 'saving...'
  end
  
  after :add_member, :remove_member, :change_name do |*, team| team.save end
end

team = Team.new
team.add_member 'Maren'
team.change_name 'Ruby Cherries'
team.remove_member 'Guilia'

# Output is:
# saving...
# saving...
# saving...