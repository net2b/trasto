module Trasto
  module Translates
    def translates(*columns, fallbacks_for_empty_translations: false, accessor_locales: nil)
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
        define_localized_attribute(column, fallbacks_for_empty_translations: fallbacks_for_empty_translations, accessor_locales: accessor_locales)
      end

      before_validation :write_default_i18n_values
    end

    private

    def define_localized_attribute(column, fallbacks_for_empty_translations: false, accessor_locales: nil)
      @fallbacks_for_empty_translations ||= {}
      @fallbacks_for_empty_translations[column.to_sym] = fallbacks_for_empty_translations

      localized_accessor column, locales: (accessor_locales || I18n.available_locales)

      define_method(column) do
        trasto_read_attribute(column, locale: I18n.locale)
      end

      define_method("#{column}=") do |value|
        trasto_write_attribute(column, value, locale: I18n.locale)
      end
    end
  end
end

ActiveRecord::Base.send :extend, Trasto::Translates
