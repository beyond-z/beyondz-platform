class CreateAssignments < ActiveRecord::Migration
  def change
    create_table :assignments do |t|
      t.string :title
      t.string :led_by
      t.datetime :start_date
      t.datetime :end_date
      t.text :front_page_info
      t.text :details_summary
      t.text :details_content
      t.string :complete_module_url
      t.string :assignment_download_url
      t.datetime :eal_due_date
      t.text :final_message

      t.timestamps
    end
  end
end
