class CreatePupils < ActiveRecord::Migration
  def change
    create_table :pupils do |t|
      t.references :user, index: true
      t.references :pupil, index: true

      t.timestamps
    end
  end
end
