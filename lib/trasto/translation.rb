module Trasto
  class Translation
    include ActiveModel::Model

    attr_reader :locale
    def locale= value
      raise "can't modify locale once set" if @locale
      @locale = value.to_sym
    end
  end
end
