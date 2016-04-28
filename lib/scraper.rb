require 'http'
require 'oga'
module ImageGetter
  class Scraper
    attr_reader :base_url, :document, :html
    def initialize(base_url,document)
      @base_url = base_url
      @document = document
      @html = Oga.parse_html(@document)
    end

    def links
      @links ||= get_links
    end

    def images
      @images ||= get_images
    end

    private
    def valid_href?(href)
      !!(href.is_a?(String) &&
         href.length > 0 &&
         !(/^#/ =~ href) &&
         !(/^mailto:/ =~ href)
      )
    end

    def get_links
      html.css('a[href]').inject([]) do |res, node|
        href = node.get('href')
        begin
          res << URI.join(base_url,href).to_s if valid_href?(href)
        rescue
          puts "UNABLE TO PARSE HREF: #{href.inspect} (from #{base_url})"
        end
        res
      end
    end

    def valid_image?(path)
      !!(path && /(jpg|gif|png)$/i =~ path)
    end

    def get_images
      res = []
      grab = ->(selector,attribute) do
        html.css(selector).each do |node|
          path = node.get(attribute)
          res << URI.join(base_url,path).to_s if valid_image?(path)
        end
      end
      # These are roughly in the order they would appear in most pages
      grab.call 'meta[itemprop="image"]', 'content'
      grab.call 'meta[property="og:image"]', 'content'
      grab.call 'link[rel="image_src"]', 'href'
      grab.call 'img', 'src'
      res += css_images
      res
    end

    def css_images
      res = []
      html.css('style').each do |node|
        node.text.scan(/url\((.*)\)/i).flatten.each do |path|
          path.tr!("'\"","")
          next unless valid_image?(path)
          begin
            res << URI.join(base_url,path).to_s
          rescue
            puts "UNABLE TO PARSE IMAGE PATH: #{path.inspect} (from #{base_url})"
          end
        end
      end
      res
    end

    class << self
      def call(url)
        res = HTTP.get(url)
        new(url,res.to_s)
      end
    end
  end
end
