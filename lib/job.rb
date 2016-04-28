require 'db/connect'

module ImageGetter
  class Job < Sequel::Model
    STATUS = %w|inprogress completed|.freeze
    one_to_many :pages

    def check_status!
      if pages_dataset.inprogress.count == 0
        update(status: STATUS[1])
      end
    end

    def status_hash
      {status:{
        'inprogress': pages_dataset.inprogress.count,
        'completed': pages_dataset.completed.count,
      }}
    end

    def results_hash
      results = {}
      pages.each{|page| results[page.url] = page.images }
      {results: results}
    end

    dataset_module do
      def inprogress
        where status: STATUS[0]
      end

      def completed
        where status: STATUS[1]
      end
    end
  end
end
