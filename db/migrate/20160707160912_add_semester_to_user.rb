class AddSemesterToUser < ActiveRecord::Migration
  def change
    add_column :users, :anticipated_graduation_semester, :string
  end
end
