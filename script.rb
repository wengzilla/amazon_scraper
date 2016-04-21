require 'mechanize'
require 'bigdecimal'
require 'csv'

AMAZON_URLS = [
"http://www.amazon.com/Inateck-Apple-Carrying-Protector-TPB-IA/dp/B00MVFGM4A/ref=sr_1_cc_1?s=aps&ie=UTF8&qid=1455405145&sr=1-1-catcorr&keywords=felt+ipad+case",
"http://www.amazon.com/Mosiso-Shoulder-Briefcase-Compatible-Ultrabook/dp/B016OBOEQY/ref=sr_1_cc_4?s=aps&ie=UTF8&qid=1455512214&sr=1-4-catcorr&keywords=felt+ipad+case",
"http://www.amazon.com/Eagwell-MacBook-Sleeve-Ultrabook-Netbook/dp/B018DMSDDW/ref=sr_1_cc_5?s=aps&ie=UTF8&qid=1455512214&sr=1-5-catcorr&keywords=felt+ipad+case",
"http://www.amazon.com/Inateck-Carrying-Protector-Display-Portable/dp/B00MVFGJNE/ref=sr_1_cc_6?s=aps&ie=UTF8&qid=1455512214&sr=1-6-catcorr&keywords=felt+ipad+case",
"http://www.amazon.com/Bear-Motion-iPad-Premium-Display/dp/B00KQD0VCI/ref=pd_sim_sbs_147_1?ie=UTF8&dpID=41RSs2PxYcL&dpSrc=sims&preST=_AC_UL160_SR160%2C160_&refRID=1720EFKPD1WPEGSG1WWF",
"http://www.amazon.com/iPad-Pro-Case-built--Protective/dp/B017YP5X1Y/ref=sr_1_cc_8?s=aps&ie=UTF8&qid=1455512214&sr=1-8-catcorr&keywords=felt+ipad+case"
]

class AmazonScraper
  def initialize(urls)
    @urls = urls
    @product_pages = {}
  end

  def run!
    data = @urls.map do |url|
      {
        :product_title => product_page(url).product_title,
        :review_velocity => product_page(url).review_velocity,
        :review_count => product_page(url).review_count,
        :review_count => product_page(url).review_count,
        :newest_date => product_page(url).newest_date,
        :oldest_date => product_page(url).oldest_date,
        :total_days => (product_page(url).newest_date - product_page(url).oldest_date).to_i,
        :review_link => product_page(url).review_link.attributes["href"],
      }
    end
    write_to_csv(data)
  end

  def write_to_csv(data)
    CSV.open("amazon_results.csv", "wb") do |csv|
    csv << data.first.keys.map{ |k| k.to_s.split("_").map(&:capitalize).join(" ") } # adds the attributes name on the first line
      data.each do |hash|
        csv << hash.values
      end
    end
  end

  def agent
    @agent ||= Mechanize.new do |agent|
      agent.user_agent_alias = 'Mac Safari'
      agent.follow_meta_refresh = true
      agent.redirect_ok = true
    end
  end

  def product_page(url)
    @product_pages[url] ||= ProductPage.new(agent.get(url), agent)
  end
end

class ProductPage
  attr_accessor :content, :agent

  def initialize(content, agent)
    @content = content
    @agent = agent
  end

  def product_title
    content.css("#productTitle").children.first.to_s
  end

  def review_count
    content.css("#acrCustomerReviewText").text.to_i
  end

  def review_link
    content.xpath('//a[contains(text(), "newest first")]').first
  end

  def newest_date
    review_page.newest_date
  end

  def oldest_date
    review_page.oldest_date
  end

  def review_page
    @review_page ||= ReviewPage.new(agent.click(review_link), agent)
  end

  def review_velocity
    BigDecimal.new(review_count / (newest_date - oldest_date), 3).to_f
  end
end

class ReviewPage
  attr_accessor :content, :agent

  def initialize(content, agent)
    @content = content
    @agent = agent
  end

  def sorted_dates
    @sorted_dates ||= content.css('.review-date').map{ |x| Date.parse(x.text) }.sort
  end

  def newest_date
    sorted_dates.last
  end

  def oldest_date
    sorted_dates.first
  end

  def reviews_last_page
    @reviews_last_page ||= ReviewPage.new(agent.click(reviews_last_page), agent)
  end

  def oldest_review_date
    reviews_last_page.oldest_date
  end
end

AmazonScraper.new(AMAZON_URLS).run!