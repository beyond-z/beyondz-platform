class ReferralsController < ApplicationController
  layout 'public'

  def index
  end

  def new
    @referral = Referral.new
    @referral_type = params[:type]
    @referral_type_text = case params[:type]
      when 'fellow'
        "Fellow"
      when 'lc'
        "Leadership Coach"
      else
        redirect_to referrals_path
    end
  end

  def create
    referral = Referral.new(params[:referral].permit(
      :referred_by_first_name,
      :referred_by_last_name,
      :referred_by_email,
      :referred_by_phone,
      :referral_location,
      :referred_by_employer,
      :referred_by_affiliation,
      :referred_first_name,
      :referred_last_name,
      :referred_email,
      :referred_phone,
      :referrer_user_id,
      :referrer_salesforce_id,
      :referred_salesforce_id,
      :referring_type
    ))

    referral.save

    referral.create_on_salesforce
  end
end
