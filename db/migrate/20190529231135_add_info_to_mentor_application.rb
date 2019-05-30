class AddInfoToMentorApplication < ActiveRecord::Migration
  def change
    add_column :mentor_applications, :bkg_african_americanblack, :boolean
    add_column :mentor_applications, :bkg_asian_american, :boolean
    add_column :mentor_applications, :bkg_latino_or_hispanic, :boolean
    add_column :mentor_applications, :bkg_native_alaskan, :boolean
    add_column :mentor_applications, :bkg_native_american_american_indian, :boolean
    add_column :mentor_applications, :bkg_native_hawaiian, :boolean
    add_column :mentor_applications, :bkg_pacific_islander, :boolean
    add_column :mentor_applications, :bkg_whitecaucasian, :boolean
    add_column :mentor_applications, :bkg_multi_ethnicmulti_racial, :boolean
    add_column :mentor_applications, :identify_poc, :boolean
    add_column :mentor_applications, :identify_low_income, :boolean
    add_column :mentor_applications, :identify_first_gen, :boolean
    add_column :mentor_applications, :bkg_other, :boolean
    add_column :mentor_applications, :hometown, :text
    add_column :mentor_applications, :pell_grant, :boolean
    add_column :mentor_applications, :gender_identity, :text
    add_column :mentor_applications, :functional_area, :text
    add_column :mentor_applications, :what_gain, :text
    add_column :mentor_applications, :internships_count, :text
    add_column :mentor_applications, :lingering_questions, :text
    add_column :mentor_applications, :interests_areas, :text
  end
end
