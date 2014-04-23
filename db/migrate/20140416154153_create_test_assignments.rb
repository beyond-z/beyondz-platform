class CreateTestAssignments < ActiveRecord::Migration
  def up
    create_table :test_assignments do |t|
    	t.string :name
    	t.timestamps
    end

  end

  def down

  	drop_table :testassignments

  end
end
