class ChangeMentorApplicationColumnSizes < ActiveRecord::Migration
  def change
    change_column :mentor_applications, :why_interested_in_pm, :text
    change_column :mentor_applications, :why_interested_in_field, :text
    change_column :mentor_applications, :what_most_helpful, :text
  end
end
