class CreateChampionContactLoggedEmails < ActiveRecord::Migration
  def change
    create_table :champion_contact_logged_emails do |t|
      t.references :champion_contact, index: true
      t.string :to
      t.string :from
      t.string :subject
      t.text :plain
      t.text :html

      t.timestamps
    end
  end
end
