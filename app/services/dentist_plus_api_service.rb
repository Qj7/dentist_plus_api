require 'httparty'

class DentistPlusApiService
  include HTTParty
  base_uri 'https://api2.dentist-plus.com'

  def initialize
    @login = ENV['DENTIST_API_LOGIN']
    @password = ENV['DENTIST_API_PASS']
    @token = nil
    @default_options = {
      timeout: 60 # Увеличенный таймаут в секундах
    }
    @max_retries = 3 # Количество повторных попыток
  end

  def login
    options = @default_options.merge({
      body: {
        login: @login,
        pass: @password
      }.to_json,
      headers: {
        'Content-Type' => 'application/json'
      }
    })

    response = self.class.post('/partner/auth', options)
    parsed_response = parse_response(response)

    if parsed_response[:error].nil?
      @token = parsed_response['token'] # Сохраняем токен для дальнейшего использования
    end

    parsed_response
  end

  def get_patient_data(patient_id)
    return { error: 'Unauthorized: Missing token' } if @token.nil?

    options = @default_options.merge({
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{@token}"
      }
    })

    attempt_request { self.class.get("/partner/patients/#{patient_id}", options) }
  end

  private

  def parse_response(response)
    if response.success?
      response.parsed_response # JSON, преобразованный в Ruby hash
    else
      { error: response['message'] || 'Unknown error', code: response.code }
    end
  end

  def attempt_request
    retries = 0
    begin
      response = yield
      parse_response(response)
    rescue Net::OpenTimeout, Net::ReadTimeout, HTTParty::Error => e
      retries += 1
      if retries <= @max_retries
        puts "Ошибка соединения: #{e.message}. Повторная попытка #{retries} из #{@max_retries}..."
        sleep(2**retries) # Экспоненциальная задержка перед повторной попыткой
        retry
      else
        { error: "Max retries reached: #{e.message}" }
      end
    end
  end
end
