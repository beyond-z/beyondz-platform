# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140429172306) do

  create_table "assignment_definitions", force: true do |t|
    t.string   "title"
    t.string   "led_by"
    t.datetime "start_date"
    t.datetime "end_date"
    t.text     "front_page_info"
    t.text     "details_summary"
    t.text     "details_content"
    t.string   "complete_module_url"
    t.string   "assignment_download_url"
    t.datetime "eal_due_date"
    t.text     "final_message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "seo_name"
  end

  create_table "assignments", force: true do |t|
    t.integer  "assignment_definition_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
    t.datetime "completed_at"
    t.boolean  "tasks_complete",           default: false
  end

  add_index "assignments", ["assignment_definition_id"], name: "index_assignments_on_assignment_definition_id", using: :btree
  add_index "assignments", ["state"], name: "index_assignments_on_state", using: :btree
  add_index "assignments", ["user_id"], name: "index_assignments_on_user_id", using: :btree

  create_table "coach_students", force: true do |t|
    t.integer  "coach_id"
    t.integer  "student_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "coach_students", ["coach_id"], name: "index_coach_students_on_coach_id", using: :btree
  add_index "coach_students", ["student_id"], name: "index_coach_students_on_student_id", using: :btree

  create_table "commontator_comments", force: true do |t|
    t.string   "creator_type"
    t.integer  "creator_id"
    t.string   "editor_type"
    t.integer  "editor_id"
    t.integer  "thread_id",                     null: false
    t.text     "body",                          null: false
    t.datetime "deleted_at"
    t.integer  "cached_votes_up",   default: 0
    t.integer  "cached_votes_down", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "commontator_comments", ["cached_votes_down"], name: "index_commontator_comments_on_cached_votes_down", using: :btree
  add_index "commontator_comments", ["cached_votes_up"], name: "index_commontator_comments_on_cached_votes_up", using: :btree
  add_index "commontator_comments", ["creator_id", "creator_type", "thread_id"], name: "index_commontator_comments_on_c_id_and_c_type_and_t_id", using: :btree
  add_index "commontator_comments", ["thread_id"], name: "index_commontator_comments_on_thread_id", using: :btree

  create_table "commontator_subscriptions", force: true do |t|
    t.string   "subscriber_type", null: false
    t.integer  "subscriber_id",   null: false
    t.integer  "thread_id",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "commontator_subscriptions", ["subscriber_id", "subscriber_type", "thread_id"], name: "index_commontator_subscriptions_on_s_id_and_s_type_and_t_id", unique: true, using: :btree
  add_index "commontator_subscriptions", ["thread_id"], name: "index_commontator_subscriptions_on_thread_id", using: :btree

  create_table "commontator_threads", force: true do |t|
    t.string   "commontable_type"
    t.integer  "commontable_id"
    t.datetime "closed_at"
    t.string   "closer_type"
    t.integer  "closer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "commontator_threads", ["commontable_id", "commontable_type"], name: "index_commontator_threads_on_c_id_and_c_type", unique: true, using: :btree

  create_table "resources", force: true do |t|
    t.string   "url"
    t.string   "title"
    t.text     "note"
    t.boolean  "optional"
    t.integer  "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "task_definitions", force: true do |t|
    t.integer  "assignment_definition_id"
    t.text     "name"
    t.string   "kind"
    t.string   "file_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "details"
    t.boolean  "required",                 default: false
    t.integer  "position"
    t.text     "summary"
  end

  add_index "task_definitions", ["assignment_definition_id"], name: "index_task_definitions_on_assignment_definition_id", using: :btree
  add_index "task_definitions", ["position"], name: "index_task_definitions_on_position", using: :btree
  add_index "task_definitions", ["required"], name: "index_task_definitions_on_required", using: :btree

  create_table "task_files", force: true do |t|
    t.integer  "task_definition_id"
    t.integer  "task_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.string   "document_file_name"
    t.string   "document_content_type"
    t.integer  "document_file_size"
    t.datetime "document_updated_at"
    t.string   "video_file_name"
    t.string   "video_content_type"
    t.integer  "video_file_size"
    t.datetime "video_updated_at"
    t.string   "audio_file_name"
    t.string   "audio_content_type"
    t.integer  "audio_file_size"
    t.datetime "audio_updated_at"
  end

  add_index "task_files", ["task_definition_id"], name: "index_task_files_on_task_definition_id", using: :btree
  add_index "task_files", ["task_id"], name: "index_task_files_on_task_id", using: :btree

  create_table "tasks", force: true do |t|
    t.integer  "assignment_id"
    t.integer  "task_definition_id"
    t.integer  "user_id"
    t.string   "kind"
    t.string   "file_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
  end

  add_index "tasks", ["assignment_id"], name: "index_tasks_on_assignment_id", using: :btree
  add_index "tasks", ["state"], name: "index_tasks_on_state", using: :btree
  add_index "tasks", ["task_definition_id"], name: "index_tasks_on_task_definition_id", using: :btree
  add_index "tasks", ["user_id"], name: "index_tasks_on_user_id", using: :btree

  create_table "user_coaches", force: true do |t|
    t.integer  "user_id"
    t.integer  "pupil_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_coaches", ["pupil_id"], name: "index_user_coaches_on_pupil_id", using: :btree
  add_index "user_coaches", ["user_id"], name: "index_user_coaches_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email"
    t.string   "name"
    t.string   "coach"
    t.string   "documentKey"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password"
    t.string   "reset_token"
    t.datetime "reset_expiration"
    t.string   "first_name"
    t.string   "last_name"
  end

end
