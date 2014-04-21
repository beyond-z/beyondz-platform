class AddSeoNameToAssignment < ActiveRecord::Migration
  def change
    add_column :assignments, :seo_name, :string
  end
end
