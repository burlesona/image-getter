require 'db/connect'

module ImageGetter
  class Page < Sequel::Model
    STATUS = %w|inprogress completed|.freeze
    many_to_one :job
    many_to_one :parent, :class => self
    one_to_many :children, :key => :parent_id, :class => self

    def root?
      !parent
    end

    # Convenience for PG Array instead of initializing with nil
    def images
      @images = super || []
    end

    # Convenience for PG Array instead of initializing with nil
    def links
      @links = super || []
    end

    def completed!
      update(status: STATUS[1])
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
