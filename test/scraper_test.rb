require 'test_helper'
require 'lib/scraper'

describe Scraper do
  def getpage(name)
    open("test/samples/#{name}.html").read
  end

  it "should get all links in a page" do
    s = Scraper.new("https://www.google.com", getpage("links"))
    assert_equal 4, s.links.count
  end

  it "should fully qualify links" do
    s = Scraper.new("https://www.google.com/test/", getpage("links"))
    assert_equal "https://www.google.com/test/page-rel.html", s.links[0]
    assert_equal "https://www.google.com/root-rel.html", s.links[1]
    assert_equal "https://www.google.com/full", s.links[2]
    assert_equal "https://www.external.com/external", s.links[3]
  end

  it "should get all images in a page" do
    s = Scraper.new("https://www.google.com", getpage("images"))
    assert_equal 8, s.images.count
  end

  it "should fully qualify image paths" do
    s = Scraper.new("https://www.example.com/test/", getpage("images"))
    assert_equal "https://www.example.com/test/meta-itemprop.png", s.images[0]
    assert_equal "https://www.example.com/test/og-image.png", s.images[1]
    assert_equal "https://www.example.com/test/image_src.png", s.images[2]
    assert_equal "https://www.example.com/test/img1.png", s.images[3]
    assert_equal "https://www.example.com/rootrelative/img2.png", s.images[4]
    assert_equal "https://www.example.com/test/dirrelative/img3.png", s.images[5]
    assert_equal "https://www.example.com/full.png", s.images[6]
    assert_equal "https://www.external.com/external.png", s.images[7]
  end

  it "should get images from inline CSS" do
    s = Scraper.new("https://www.example.com/test/", getpage("css"))
    assert_equal 5, s.images.count
  end

  it "should fully qualify images from CSS" do
    s = Scraper.new("https://www.example.com/test/", getpage("css"))
    assert_equal "https://www.example.com/test/bare.png", s.images[0]
    assert_equal "https://www.example.com/singlequotes.png", s.images[1]
    assert_equal "https://www.example.com/doublequotes.png", s.images[2]
    assert_equal "https://www.example.com/test/nest/ed.png", s.images[3]
    assert_equal "https://www.external.com/test.png", s.images[4]
  end
end
