class SubmissionValidator < ActiveModel::Validator
  
  def validate(record)
    if $userInfos[record.email] == nil
      record.errors[:base] << "That email address is not recognized.  Please use the email address that you used to sign up for Beyond Z or email our <a href=\"mailto:tech@beyondz.org\">tech support</a> if you don't know it."
    end
  end
end

class Submission
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  attr_accessor :email, :url
  
  validates :email, :url, :presence => true 
  validates_with SubmissionValidator

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  # This model is not persisted to the database.  Once we move from a hardcoded website to one that is
  # backed by a database with a login then we can change this model to an ActiveRecord
  def persisted?
    false
  end

end
