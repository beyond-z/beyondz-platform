class Assignment < ActiveRecord::Base
  has_many :resources
  has_many :todos
end
