class CreateRecruitmentPrograms < ActiveRecord::Migration
  def change
    create_table :recruitment_programs do |t|
      t.text :name
      t.text :campaign_id

      t.timestamps
    end
  end
end
