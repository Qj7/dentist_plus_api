class CreatePatients < ActiveRecord::Migration[7.2]
  def change
    create_table :patients do |t|
      t.string :internal_id
      t.string :fname
      t.string :mname
      t.string :lname
      t.string :phone
      t.string :phone_2
      t.string :gender
      t.date :date_of_birth
      t.string :address
      t.string :card
      t.string :email
      t.string :snils
      t.string :iin
      t.string :passport
      t.string :representative_fio
      t.string :representative_phone
      t.string :representative_address
      t.string :representative_passport
      t.integer :discount
      t.string :status
      t.string :source
      t.string :url
      t.text :description
      t.string :activity_status
      t.integer :deposit
      t.integer :bonus
      t.integer :curator_id
      t.json :tags
      t.json :patient_condition
      t.json :deposit_details
      t.json :doctor
      t.json :extra_fields
      t.datetime :first_visit

      t.timestamps
    end
  end
end
