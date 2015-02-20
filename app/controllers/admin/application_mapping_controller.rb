require 'salesforce'

class Admin::ApplicationMappingController < Admin::ApplicationController
  def index
    # We'll show all of them and query salesforce to see
    # if there's any campaigns there that don't have a mapping
    # to allow easy creation too - we make a skeleton immediately
    # and just let the user edit it
    existing = Application.all

    # Find unassigned SF campaigns to prompt for creation
    sf = BeyondZ::Salesforce.new
    client = sf.get_client
    client.materialize('Campaign')

    campaigns = SFDC_Models::Campaign.all

    # For prettifying so users can read it
    @campaign_names = Hash.new
    
    campaigns.each do |campaign|
      found = false
      @campaign_names[campaign.Id] = campaign.Name
      existing.each do |app|
        if app.associated_campaign == campaign.Id
          found = true
          break
        end
      end

      if !found
        Application.create(:associated_campaign => campaign.Id, :form => '')
      end
    end

    # Reload to include the new ones just created too for editing
    @applications = Application.all

    # The possible application forms for creating a drop down in the view
    @forms = ['', 'coach', 'student']
  end

  def update
    application = Application.find(params[:id])
    application.form = params[:application][:form]
    application.save!

    redirect_to admin_applications_path
  end
end
