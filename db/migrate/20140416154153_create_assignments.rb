class CreateAssignments < ActiveRecord::Migration
  def up
    create_table :test_assignments do |t|
    	t.string :name
    	t.timestamps
    end

    5.times do |n|
    	TestAssignment.create(name: "Assignment #{n}")
    end

  end

  def down

  	drop_table :testassignments

  end
end
