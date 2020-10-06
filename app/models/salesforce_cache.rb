# The salesforce cache is a key-value mapping in our database
# that is used to store data from the salesforce API that we
# frequently need to avoid the slow process of asking them for
# it all the time.
#
# Its structure is just string key, text value. The lib/salesforce.rb
# file uses this model. It should never be used anywhere else - it is
# an implementation detail of the salesforce wrapper library code.
class SalesforceCache < ActiveRecord::Base
end
