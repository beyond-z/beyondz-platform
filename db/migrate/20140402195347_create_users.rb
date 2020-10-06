class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :name
      t.string :coach
      t.string :documentKey

      t.timestamps
    end
  end
end
