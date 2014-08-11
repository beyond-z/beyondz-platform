class CreateEnrollments < ActiveRecord::Migration
  def up
    create_table :enrollments do |t|
      t.integer :user_id
      t.timestamps
    end

    add_index :enrollments, :user_id
  end

  def down
    remove_index :enrollments, :user_id

    drop_table :enrollments
  end
end
