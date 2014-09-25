class AddCanvasInfoToUser < ActiveRecord::Migration
  def change
    add_column :users, :canvas_user_id, :integer
  end
end
