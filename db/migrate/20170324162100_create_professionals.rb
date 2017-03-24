class CreateProfessionals < ActiveRecord::Migration
  def change
    create_table :professionals do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :linkedin_url
      t.boolean :braven_fellow
      t.boolean :braven_lc
      t.boolean :willing_to_be_contacted
      t.string :industries, :array => true
      t.string :studies, :array => true

      t.timestamps
    end
  end
end
