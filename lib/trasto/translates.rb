module Trasto
  module Translates
    def translates(*columns, fallbacks_for_empty_translations: false)
      extend Trasto::ClassMethods
      include Trasto::InstanceMethods

      unless Trasto.supports_hstore?
        columns.each do |name|
          serialize "#{name}_i18n", JSON
        end
      end

      # Don't overwrite values if running multiple times in the same class
      # or in different classes of an inheritance chain.
      unless respond_to?(:translatable_columns)
        class_attribute :translatable_columns
        self.translatable_columns = []

        self.const_set(:Translation, Class.new(::Trasto::Translation))
      end

      self::Translation.send(:attr_accessor, *columns)

      self.translatable_columns |= columns.map(&:to_sym)

      columns.each do |column|
        define_localized_attribute(column, fallbacks_for_empty_translations: fallbacks_for_empty_translations)
      end
    end

    private

    def define_localized_attribute(column, fallbacks_for_empty_translations: false)
      @fallbacks_for_empty_translations ||= {}
      @fallbacks_for_empty_translations[column.to_sym] = fallbacks_for_empty_translations

      # define_method(column) do
      #   read_localized_value(column, locale: I18n.locale)
      # end
      #
      # define_method("#{column}=") do |value|
      #   write_attribute(column, value) if read_attribute(column).blank? or I18n.locale == I18n.default_locale
      #   write_localized_value(column, value, locale: I18n.locale)
      # end
    end
  end
end

ActiveRecord::Base.send :extend, Trasto::Translates
