class NotNullMentorApplication < ActiveRecord::Migration
  def up
    change_column_null :mentor_applications, :phone, false, ''
  end
end
