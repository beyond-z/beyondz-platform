class AddFormToApplication < ActiveRecord::Migration
  def change
    add_column :applications, :form, :string
  end
end
