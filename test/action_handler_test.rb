require 'test_helper'
require 'lib/action_handler'

describe ActionHandler do
  class MockWorker
    attr_reader :queue
    def initialize
      @queue = []
    end

    def enqueue(item)
      @queue << item
    end
  end

  it "should create a job with URLs" do
    action = ActionHandler.new
    action.worker = MockWorker.new
    job = action.create_job "https://www.google.com", "https://www.statuspage.io"
    assert job.is_a?(Job)
    refute job.new?
    assert_equal 2, job.pages.length
    assert_equal 'inprogress', job.status
    assert_equal "https://www.google.com", job.pages.first.url
    assert_equal "https://www.statuspage.io", job.pages.last.url
  end

  # technically this returns a URI but it doesn't matter
  # it raises ValidationError when failing
  it "should validate URLs" do
    action = ActionHandler.new
    action.validate_url! "https://www.google.com"
    assert_raises(ValidationError) do
      action.validate_url! "[https://www.google.com]"
    end
  end

  it "should create a page with no parent" do
    action = ActionHandler.new
    action.worker = MockWorker.new
    j = Job.create
    p = action.create_page(j,"https://www.google.com")
    assert p.is_a?(Page)
    assert p.url = "https://www.google.com"
    assert_equal true, p.root?
    assert_equal 'inprogress', p.status
  end

  it "should create a page with a parent" do
    action = ActionHandler.new
    action.worker = MockWorker.new
    j = Job.create
    parent = Page.create(url:"https://www.example.com",job:j)
    child = action.create_page(j,"https://www.google.com",parent: parent)
    assert child.is_a?(Page)
    assert child.url = "https://www.google.com"
    assert_equal false, child.root?
  end

  it "should add a page to the worker" do
    action = ActionHandler.new
    m = MockWorker.new
    action.worker = m
    p = {mock:"page"}
    action.enqueue_page(p)
    assert m.queue.first == p
  end


  it "should process a page, enqueing subpages" do
    action = ActionHandler.new
    m = MockWorker.new
    action.worker = m
    def action.scrape_page(url)
      raw = open("test/samples/subpages.html").read
      Scraper.new("https://www.example.com", raw)
    end
    j = Job.create
    p = Page.create(job: j, url:"https://www.example.com")
    action.process_page(p)
    assert_equal 'completed', p.status
    assert_equal 2, p.children.count
    assert_equal 2, m.queue.length
  end

  it "should process a page, not enqueing subpages" do
    action = ActionHandler.new
    m = MockWorker.new
    action.worker = m
    def action.scrape_page(url)
      raw = open("test/samples/subpages.html").read
      Scraper.new("https://www.example.com", raw)
    end
    j = Job.create
    p = Page.create(job: j, url:"https://www.example.com")
    action.process_page(p)
    assert_equal 'completed', p.status
    assert_equal 2, p.children.count
    assert_equal 2, m.queue.length
  end

  it "should make a job complete when the last page is processed" do
    action = ActionHandler.new
    m = MockWorker.new
    action.worker = m
    def action.scrape_page(url)
      raw = open("test/samples/images.html").read
      Scraper.new("https://www.example.com", raw)
    end
    j = Job.create
    assert_equal 'inprogress', j.status
    p = Page.create(job: j, url:"https://www.example.com")
    action.process_page(p)
    assert_equal 'completed', p.status
    assert_equal 0, p.children.count
    assert_equal 'completed', j.status
  end
end
