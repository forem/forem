module Organizations
  class Delete
    def initialize(org)
      @org = org
    end

    def call
      org.destroy
    end

    def self.call(...)
      new(...).call
    end

    private

    attr_reader :org
  end
end
