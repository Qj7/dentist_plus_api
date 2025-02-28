# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_12_27_131001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "patients", force: :cascade do |t|
    t.string "internal_id"
    t.string "fname"
    t.string "mname"
    t.string "lname"
    t.string "phone"
    t.string "phone_2"
    t.string "gender"
    t.date "date_of_birth"
    t.string "address"
    t.string "card"
    t.string "email"
    t.string "snils"
    t.string "iin"
    t.string "passport"
    t.string "representative_fio"
    t.string "representative_phone"
    t.string "representative_address"
    t.string "representative_passport"
    t.integer "discount"
    t.string "status"
    t.string "source"
    t.string "url"
    t.text "description"
    t.string "activity_status"
    t.integer "deposit"
    t.integer "bonus"
    t.integer "curator_id"
    t.json "tags"
    t.json "patient_condition"
    t.json "deposit_details"
    t.json "doctor"
    t.json "extra_fields"
    t.datetime "first_visit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
