class Scraper
  attr_accessor :agent
  AMAZON_URL = "http://www.amazon.com/Inateck-Apple-Carrying-Protector-TPB-IA/dp/B00MVFGM4A/ref=sr_1_cc_1?s=aps&ie=UTF8&qid=1455405145&sr=1-1-catcorr&keywords=felt+ipad+case"

  def run
    @agent ||= Mechanize.new
  end

  private

  def get_product
    product_page = agent.get AMAZON_URL
  end
end

class ScraperAgent
  DIRECTORY_URL = "http://beech.hbs.edu/classcards/search.do"

  def initialize
    login
  end

  def agent
    @agent ||= Mechanize.new
  end

  def auth_credentials
    {:username => ENV["HBS_DIRECTORY_USERNAME"], :password => ENV["HBS_DIRECTORY_PASSWORD"]}
  end

  def login
    search_page = agent.get(DIRECTORY_URL)
    if search_page.form_with :name => 'loginForm'
      form             = search_page.form_with :name => 'loginForm'
      form["username"] = auth_credentials[:username]
      form["password"] = auth_credentials[:password]
      form.submit
    end
  end
end