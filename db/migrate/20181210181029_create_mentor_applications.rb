class CreateMentorApplications < ActiveRecord::Migration
  def change
    create_table :mentor_applications do |t|
      t.integer :user_id
      t.string :campaign_id
      t.string :application_type
      t.text :can_commit
      t.string :can_meet
      t.string :city
      t.string :comfortable
      t.string :desired_job
      t.string :email
      t.string :employer
      t.string :employer_industry
      t.string :first_name
      t.string :how_hear
      t.string :industry
      t.string :interests
      t.string :last_name
      t.string :linkedin_url
      t.string :major
      t.string :other_industries
      t.string :phone
      t.string :reference2_email
      t.string :reference2_name
      t.string :reference2_phone
      t.string :reference_email
      t.string :reference_name
      t.string :reference_phone
      t.string :state
      t.text :strengths_and_growths
      t.string :title
      t.text :what_do
      t.text :what_most_helpful
      t.text :what_skills
      t.string :when_graduate
      t.text :why_interested_in_pm
      t.string :why_interested_in_field
      t.text :why_want_to_be_pm
      t.string :willing_to_work_with_other_field
      t.string :work_city
      t.string :work_state

      t.timestamps
    end
  end
end
