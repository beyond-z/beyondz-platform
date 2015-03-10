# This is a simple store for text lists which we enter
# one per line in the admin text area, analogously to a
# Salesforce pick list.
#
# It is stored as a string with an identifier called friendly_name.
#
# The two we have right now are universities and bz_regions. More can
# be added on-demand by simply linking to them in the admin and using the
# name in the code. Remember to check for nil on find_by_friendly_name
# to handle that case gracefully when you use it.
class List < ActiveRecord::Base
  def items
    content.split("\n")
  end
end
