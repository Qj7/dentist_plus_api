require 'rubyXL'
require 'net/http'

class HomeController < ApplicationController
  def index
    Signal.trap("INT") do
      puts "\nОбработка прервана пользователем."
      exit
    end

    unless api_available?("https://api2.dentist-plus.com")
      puts "API недоступно. Проверьте подключение."
      return render plain: "API недоступно. Проверьте подключение."
    end

    begin
      api_service = DentistPlusApiService.new
      login_response = api_service.login

      p '============================='
      p 'Авторизация api2 dentist-plus'
      p login_response

      if login_response[:error]
        puts "Ошибка авторизации: #{login_response[:error]}"
        return render plain: "Ошибка авторизации: #{login_response[:error]}"
      end

      puts "Успешный вход: #{login_response}"

      workbook = RubyXL::Workbook.new
      worksheet = workbook[0]
      worksheet.sheet_name = 'Processed Data'

      headers = %w[
        ID FName MName LName Phone Phone_2 Status Gender DOB Address Card Email SNILS IIN Passport
        Representative_FIO Representative_Phone Representative_Address Representative_Passport
        Discount Source Description Activity_Status Deposit Bonus Tags Patient_Condition Doctor
        Curator_ID Extra_Fields URL Created_At Updated_At Deleted
      ]
      headers.each_with_index do |header, index|
        worksheet.add_cell(0, index, header)
      end

      source_workbook = RubyXL::Parser.parse('clients_data.xlsx')
      source_worksheet = source_workbook[0]

      source_worksheet.each_with_index do |row, index|
        next if index.zero?

        cell = row && row[1]
        user_id_raw = cell&.value.to_s.strip
        next if user_id_raw.blank? || !user_id_raw.match?(/^\d+(\.0)?$/)

        user_id = user_id_raw.sub(/\.0$/, '')

        begin
          patient_data = api_service.get_patient_data(user_id)
        rescue StandardError => e
          puts "Критическая ошибка: #{e.message}. Прекращение обработки."
          raise "Критическая ошибка. Прекращение работы для ID #{user_id}"
        end

        if patient_data[:error]
          puts "Ошибка получения данных пациента: #{patient_data[:error]}"
          raise "Прекращение из-за ошибки API для ID #{user_id}"
        end

        new_row_index = worksheet.sheet_data.size
        patient_data_row = build_patient_data_row(user_id, patient_data)

        patient_data_row.each_with_index do |value, col_index|
          worksheet.add_cell(new_row_index, col_index, value)
        end

        workbook.write('clients_data_updated.xlsx')
      end

      puts "Все данные успешно обработаны и сохранены в clients_data_updated.xlsx"
      render plain: "Обновление завершено. Проверьте файл clients_data_updated.xlsx"
    rescue Interrupt
      puts "\nПрерывание процесса обработки. Частично обработанные данные сохранены."
      render plain: "Обработка прервана. Проверьте текущий файл clients_data_updated.xlsx"
    rescue => e
      puts "Ошибка обработки файла: #{e.message}"
      render plain: "Ошибка обработки файла: #{e.message}"
    end
  end

  def continue_processing(start_id)
    Signal.trap("INT") do
      puts "\nОбработка прервана пользователем."
      exit
    end

    unless api_available?("https://api2.dentist-plus.com")
      puts "API недоступно. Проверьте подключение."
      return render plain: "API недоступно. Проверьте подключение."
    end

    begin
      api_service = DentistPlusApiService.new
      login_response = api_service.login

      p '============================='
      p 'Авторизация api2 dentist-plus'
      p login_response

      if login_response[:error]
        puts "Ошибка авторизации: #{login_response[:error]}"
        return render plain: "Ошибка авторизации: #{login_response[:error]}"
      end

      puts "Успешный вход: #{login_response}"

      workbook = RubyXL::Parser.parse('clients_data_updated.xlsx')
      worksheet = workbook[0]

      source_workbook = RubyXL::Parser.parse('clients_data.xlsx')
      source_worksheet = source_workbook[0]

      all_ids = source_worksheet.map do |row|
        cell = row && row[1]
        cell_value = cell&.value.to_s.strip
        next nil if cell_value.blank? || !cell_value.match?(/^\d+(\.0)?$/)

        cell_value.sub(/\.0$/, '')
      end.compact

      puts "Все ID из исходного файла: #{all_ids.inspect}"

      start_index = all_ids.index(start_id)
      if start_index.nil?
        puts "ID #{start_id} не найден в исходном файле."
        return render plain: "ID #{start_id} не найден в исходном файле."
      end

      puts "Индекс начального ID (#{start_id}): #{start_index}"

      remaining_ids = all_ids.drop(start_index + 1)

      current_row_index = worksheet.sheet_data.size

      remaining_ids.each do |user_id|
        begin
          patient_data = api_service.get_patient_data(user_id)

          if patient_data[:error]
            puts "Ошибка получения данных пациента: #{patient_data[:error]}"
            raise "Прекращение из-за ошибки API для ID #{user_id}"
          end

          patient_data_row = build_patient_data_row(user_id, patient_data)

          patient_data_row.each_with_index do |value, col_index|
            worksheet.add_cell(current_row_index, col_index, value)
          end

          current_row_index += 1
          workbook.write('clients_data_updated.xlsx')
        rescue StandardError => e
          puts "Критическая ошибка: #{e.message}. Прекращение обработки."
          raise
        end
      end

      puts "Все данные успешно обработаны и сохранены в clients_data_updated.xlsx"
      render plain: "Продолжение завершено. Проверьте файл clients_data_updated.xlsx"
    rescue Interrupt
      puts "\nПрерывание процесса обработки. Частично обработанные данные сохранены."
      render plain: "Обработка прервана. Проверьте текущий файл clients_data_updated.xlsx"
    rescue => e
      puts "Ошибка обработки файла: #{e.message}"
      render plain: "Ошибка обработки файла: #{e.message}"
    end
  end

  private

  def api_available?(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = 30 # Таймаут на открытие соединения
    http.read_timeout = 60 # Таймаут на чтение данных

    response = http.get(uri.request_uri)
    response.is_a?(Net::HTTPSuccess)
  rescue => e
    puts "Ошибка проверки API: #{e.message}"
    false
  end

  def build_patient_data_row(user_id, patient_data)
    [
      user_id,
      patient_data["fname"],
      patient_data["mname"],
      patient_data["lname"],
      patient_data["phone"],
      patient_data["phone_2"],
      patient_data["status"],
      patient_data["gender"],
      patient_data["date_of_birth"],
      patient_data["address"],
      patient_data["card"],
      patient_data["email"],
      patient_data["snils"],
      patient_data["iin"],
      patient_data["passport"],
      patient_data["representative_fio"],
      patient_data["representative_phone"],
      patient_data["representative_address"],
      patient_data["representative_passport"],
      patient_data["discount"],
      patient_data["source"],
      patient_data["description"],
      patient_data["activity_status"],
      patient_data["deposit"],
      patient_data["bonus"],
      patient_data["tags"]&.join(", "),
      patient_data.dig("patient_condition", "title"),
      patient_data.dig("doctor", "fname"),
      patient_data["curator_id"],
      patient_data["extra_fields"]&.join(", "),
      patient_data["url"],
      patient_data["created_at"],
      patient_data["updated_at"],
      patient_data["deleted"]
    ]
  end
end
