# The purpose of this controller is to centralize the endpoints for Salesforce triggers.
# Popup windows from SF buttons are still done in the admin area, but triggers notify
# this controller which will take appropriate action.
class SalesforceController < ApplicationController
  def change_apply_now
    # a simple filter to keep web crawlers from triggering this
    # needlessly
    if params[:magic_token] == 'test'
      params[:yes_list].split(',').each do |id|
        u = User.find_by_salesforce_id(id)
        u.apply_now_enabled = true
        u.save!
      end
      params[:no_list].split(',').each do |id|
        u = User.find_by_salesforce_id(id)
        u.apply_now_enabled = false
        u.save!
      end
    end

    render plain: ''
  end
end
