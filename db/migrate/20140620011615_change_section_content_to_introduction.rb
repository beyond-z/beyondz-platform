class ChangeSectionContentToIntroduction < ActiveRecord::Migration
  def up
    rename_column :task_sections, :content, :introduction
  end

  def down
    rename_column :task_sections, :introduction, :content
  end
end
