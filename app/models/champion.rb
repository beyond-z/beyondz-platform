class Champion < ActiveRecord::Base
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :braven_fellow, presence: true
  validates :braven_lc, presence: true
  validates :industries, presence: true
  validates :studies, presence: true
end
