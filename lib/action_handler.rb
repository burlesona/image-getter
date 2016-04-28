require 'lib/worker'
require 'lib/job'
require 'lib/page'
require 'lib/scraper'

module ImageGetter
  # In most cases I'd build invidiual actions into individual Service Objects
  # but given the quick scope of this as a demo project I figure it makes
  # enough sense to just group the workflow together for easy reading

  # The main thing is, the core business logic becomes easily unit testable
  # when the actions themselves can be handled by an instance and
  # dependencies can be injected

  # These sort of multi-object, multi-process flows normally end up in the
  # controller method or route block, but it's hard to test them there
  # because you have to simulate http request/response in order to see if
  # it worked, and when something goes wrong it's hard to get into the state
  # of the code. Therefore I try to keep any meaningful business logic
  # wrapped up in plain old ruby that I can easily test, and limit the controller
  # or router layer to basically just converting HTTP <-> Ruby
  class ActionHandler
    # This will keep the reference to the single worker
    # Allow dependency injection for testing
    attr_accessor :worker
    def initialize(items:[],threads:1)
      @worker = Worker.new(items:items,threads:threads,&method(:process_page))
    end

    def validate_url!(url)
      raise unless URI.regexp =~ url #this detects if a valid url is in the string
      URI.parse(url) # but this is needed too because strings like "|http://foo.com" will pass the first
    rescue
      raise ValidationError, "Invalid URL #{url}"
    end

    # Create a Job
    def create_job(*urls)
      # So [1,2,3] and 1,2,3 are OK
      urls.flatten!

      # This means looping through the URLS twice, but it's a relatively
      # inexpensive operation and better to early exit before beginning
      # to write to the database.
      urls.each{|url| validate_url!(url)}

      # Create the job and pages together
      job = nil
      DB.transaction do
        job = Job.create
        urls
          .map{|url| create_page(job,url) }
          .each{|page| enqueue_page(page) }
      end
      job
    end

    # Create Page
    def create_page(job, url, parent:nil)
      Page.create(url: url, job: job, parent: parent)
    end

    # Add Page to Queue
    def enqueue_page(page)
      puts "Enqueuing Page: #{page.id}"
      @worker.enqueue(page)
    end

    # Allow stubbing for testing
    def scrape_page(url)
      puts "Scraping Page: #{url}"
      Scraper.call(url)
    end

    # Process a Page
    def process_page(page)
      puts "Processing Page: #{page.id}"
      # open transaction
      DB.transaction do
        # scrape page, save results
        result = scrape_page(page.url)
        page.images = result.images
        result.links.each do |url|
          page.links << url
          create_page(page.job, url, parent: page) if page.root?
        end
        page.completed!
        # enqueue children (if any) as the final step
        page.children.each{|page| enqueue_page(page)}
      end
      page.job.check_status!
      puts "Completed Page: #{page.id}"
    end
  end
end
