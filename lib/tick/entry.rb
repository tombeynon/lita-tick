module Tick
  class Entry
    extend Client

    def self.all
      get('entries.json').map{|u| new(u) }
    end

    def self.where(params={})
      get('entries.json', params).map{|u| new(u) }
    end

    attr_reader :id, :date, :hours, :notes

    def initialize(params={})
      @id = params['id']
      @date = params['date']
      @hours = params['hours']
      @notes = params['notes']
    end
  end
end
