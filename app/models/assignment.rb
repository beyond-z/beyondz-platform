class Assignment < ActiveRecord::Base
  has_many :resources
  has_many :todos

  def self.next_due
    return Assignment.where("assignments.end_date > ?", Time.now).
      order("assignments.end_date ASC").first
  end
end
