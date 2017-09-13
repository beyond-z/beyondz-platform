class CreateChampionContacts < ActiveRecord::Migration
  def change
    create_table :champion_contacts do |t|
      t.integer :user_id
      t.integer :champion_id
      t.boolean :champion_replied
      t.boolean :fellow_get_to_talk_to_champion
      t.text :why_not_talk_to_champion
      t.integer :would_fellow_recommend_champion
      t.text :what_did_champion_do_well
      t.text :what_could_champion_improve
      t.boolean :reminder_requested
      t.datetime :fellow_survey_answered_at
      t.text :inappropriate_champion_interaction
      t.text :inappropriate_fellow_interaction
      t.boolean :champion_get_to_talk_to_fellow
      t.text :why_not_talk_to_fellow
      t.integer :how_champion_felt_conversaion_went
      t.text :what_did_fellow_do_well
      t.text :what_could_fellow_improve
      t.text :champion_comments
      t.datetime :champion_survey_answered_at
      t.text :fellow_comments

      t.timestamps
    end
  end
end
