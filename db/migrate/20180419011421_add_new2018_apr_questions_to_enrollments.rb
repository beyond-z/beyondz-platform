class AddNew2018AprQuestionsToEnrollments < ActiveRecord::Migration
  def change
    add_column :enrollments, :address1, :string
    add_column :enrollments, :address2, :string
    add_column :enrollments, :zip, :string
    add_column :enrollments, :want_grow_professionally, :text
  end
end
