# This is a holder class for applications - the form which is filled
# out to create an Enrollment.
#
# Its fields right now are active and associated_campaign. active tells
# if the apply now button is enabled. associated_campaign is a Salesforce
# campaign ID that controls this application.
#
# Other fields will be added to control application contents and matching
# the correct one to each potential applicant was we iron out those details.
class Application < ActiveRecord::Base
end
