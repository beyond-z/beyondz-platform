class CreateCoachStudents < ActiveRecord::Migration
  def change
    create_table :coach_students do |t|
      t.references :coach, index: true
      t.references :student, index: true

      t.timestamps
    end
  end
end
