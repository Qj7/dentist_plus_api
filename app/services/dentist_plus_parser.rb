require 'nokogiri'
require 'httparty'
require 'selenium-webdriver'

class DentistPlusParser
  include HTTParty
  base_uri 'https://my.dentist-plus.com'

  def initialize
    @login = ENV['DENTIST_API_LOGIN']
    @password = ENV['DENTIST_API_PASS']
    @cookies = {}
    setup_selenium
  end

  def access_patients_page
    response = get_page('/patients/')
    if redirected_to_login?(response)
      puts "Перенаправлено на страницу логина. Попробуем авторизоваться..."
      login_to_site
      response = get_page('/patients/')
      if redirected_to_login?(response)
        puts "Не удалось авторизоваться."
      else
        puts "Успешный вход на /patients/."
      end
    else
      puts "Уже на странице /patients/."
    end
  ensure
    teardown_selenium
  end

  private

  def setup_selenium
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless') # Запуск в безголовом режиме
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')

    @driver = Selenium::WebDriver.for :chrome, options: options
    puts "WebDriver успешно запущен."
  rescue => e
    puts "Ошибка при запуске WebDriver: #{e.message}"
    raise
  end

  def teardown_selenium
    @driver.quit if @driver
    puts "WebDriver завершен."
  rescue => e
    puts "Ошибка при завершении WebDriver: #{e.message}"
  end

  def get_page(path)
    response = self.class.get(path, headers: headers)
    if response.headers['set-cookie']
      @cookies.merge!(parse_cookies(response.headers['set-cookie']))
    end
    response
  rescue Net::ReadTimeout => e
    puts "Ошибка чтения (таймаут) при получении страницы #{path}: #{e.message}"
    raise
  rescue => e
    puts "Ошибка при получении страницы #{path}: #{e.message}"
    raise
  end

  def redirected_to_login?(response)
    response.request.last_uri.path == '/login/'
  end

  def login_to_site
    @driver.navigate.to "#{self.class.base_uri}/login/"

    # Ожидание загрузки страницы
    wait = Selenium::WebDriver::Wait.new(timeout: 10)
    login_input = wait.until { @driver.find_element(:css, "input[placeholder='Логин']") }
    password_input = @driver.find_element(:css, "input[placeholder='Пароль']")

    login_input.send_keys(@login)
    password_input.send_keys(@password)

    login_button = @driver.find_element(:css, "button[type='submit']")
    login_button.click

    # Ожидание перенаправления после входа
    wait.until { @driver.current_url != "#{self.class.base_uri}/login/" }

    save_cookies
  rescue Selenium::WebDriver::Error::TimeoutError => e
    puts "Таймаут при попытке входа на сайт: #{e.message}"
    raise
  rescue => e
    puts "Ошибка при попытке входа на сайт: #{e.message}"
    raise
  end

  def save_cookies
    cookies = @driver.manage.all_cookies
    @cookies = cookies.map { |cookie| "#{cookie[:name]}=#{cookie[:value]}" }.join('; ')
  rescue => e
    puts "Ошибка при сохранении cookies: #{e.message}"
    raise
  end

  def headers
    { 'Cookie' => @cookies }
  end

  def parse_cookies(cookie_header)
    cookie_header.split('; ').map { |cookie| cookie.split('=', 2) }.to_h
  end
end
