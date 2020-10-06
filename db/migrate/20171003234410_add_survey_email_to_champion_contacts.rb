class AddSurveyEmailToChampionContacts < ActiveRecord::Migration
  def change
    add_column :champion_contacts, :champion_survey_email_sent, :boolean, default: false
    add_column :champion_contacts, :fellow_survey_email_sent, :boolean, default: false
  end
end
