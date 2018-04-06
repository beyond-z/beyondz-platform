class CreateReferrals < ActiveRecord::Migration
  def change
    create_table :referrals do |t|
      t.string :referred_by_first_name
      t.string :referred_by_last_name
      t.string :referred_by_email
      t.string :referred_by_phone
      t.string :referral_location
      t.string :referred_by_employer
      t.string :referred_by_affiliation
      t.string :referred_first_name
      t.string :referred_last_name
      t.string :referred_email
      t.string :referred_phone
      t.references :referrer_user, index: true
      t.string :referrer_salesforce_id
      t.string :referred_salesforce_id
      t.string :referring_type

      t.timestamps
    end
  end
end
