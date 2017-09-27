from scrapy.spiders import CrawlSpider, Rule
from scrapy.linkextractors import LinkExtractor
from scrapy.selector import Selector

class ExampleSpider(CrawlSpider):
    
    name = "course_scraper"

    # name = "course_scraper"
    # allowed_domains = ["www.coursera.org"] # Which (sub-)domains shall be scraped?
    # start_urls = ["https://www.coursera.org"] # Start with this one
 
    # # Follow any link scrapy finds (that is allowed and matches the patterns).
    # rules = [Rule(LinkExtractor(allow=(r'/specializations.*', r'/learn.*'),deny=(r'.*authMode.*')), callback='parse_item', follow=True)] 
    # #rules = [Rule(LinkExtractor(allow=(r'/specializations.*'),deny=(r'.*authMode.*')), callback='parse_item', follow=True)] 

    # def parse_item(self, response):
        
    #     text = []

    #     if 'specialization' in response.url:
    #         title = response.css('h1 span::text').extract_first()
    #     else:
    #         title = response.css('h1::text').extract_first()

    #     text += response.css('div.body-1-text span::text').extract()
    #     text += response.css('div.content-inner p::text').extract()
    #     text += response.css('div.target-audience-section p::text').extract()
    #     text += response.css('div.description.subsection div::text').extract()
    #     text += response.css('div.content-inner p::text').extract()

    #     if len(text) > 0:
    #         yield {
    #             'title': title,
    #             'url': response.url,
    #             'text': text,
    #         }


    
    allowed_domains = ["www.udacity.com"] # Which (sub-)domains shall be scraped?
    start_urls = ["https://www.udacity.com/courses/all"] # Start with this one
 
    # Follow any link scrapy finds (that is allowed and matches the patterns).
    rules = [Rule(LinkExtractor(allow=(r'/course/.*')), callback='parse_item', follow=True)] 

    def parse_item(self, response):
        
        title = response.css('h1.hero__course--title::text').extract_first()
        text = []

        text += response.css('section.information div.information__summary p::text').extract()
        text += response.css('section.information div.information__summary li::text').extract()
        text += response.css('section.course-why div.why--summary p::text').extract()
        text += response.css('div.lesson--description li::text').extract()

        if len(text) > 0:
            yield {
                'title': title,
                'url': response.url,
                'text': text,
            }
