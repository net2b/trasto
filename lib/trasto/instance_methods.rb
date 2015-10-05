module Trasto
  module InstanceMethods
    def translations
      models = {}.with_indifferent_access
      self.class.translated_attribute_names.each do |column|
        translation_hash_for_column(column).each do |locale, value|
          model = (models[locale] ||= self.class::Translation.new(locale: locale))
          model.send(:"#{column}=", value)
        end
      end
      models.values
    end

    def translations= models
      models.each do |model|
        locale = model.locale
        self.class.translated_attribute_names.each do |column|
          value = model.send(column)
          write_localized_value(column, value, locale: locale)
        end
      end
    end

    def write_attribute(name, value, locale: I18n.locale)
      translated_column = self.class.translated_attribute_names.include?(name.to_sym)
      return super(name, value) if locale.nil? or not(translated_column)

      write_localized_value(name, value, locale: locale)

      default_value = read_localized_value(name, locale: I18n.default_locale)
      write_attribute(name, default_value, locale: nil)

      value
    end

    def read_attribute(name, locale: I18n.locale, &block)
      translated_column = self.class.translated_attribute_names.include?(name.to_sym)
      return super(name, &block) if locale.nil? or not(translated_column)
      value = read_localized_value(name, locale: locale)#.tap(&block)
      # value or block.call(name) if block_given?
      value
    end


    private

    def translation_hash_for_column(column)
      (send("#{column}_i18n") || {})
    end

    def read_localized_value(column, locale:)
      return nil unless (column_value = send("#{column}_i18n"))

      locales_for_reading_column(column, locale: locale).each do |locale|
        value = column_value[locale]
        return value if value.present?
      end
      nil
    end

    def write_localized_value(column, value, locale:)
      translations_hash = translation_hash_for_column(column)
      send("#{column}_i18n=", translations_hash.merge(locale => value).with_indifferent_access)
    end

    def translation_for(locale, _build_if_missing = true)
      model = self.class::Translation.new(locale: locale)
      self.class.translated_attribute_names.each do |column|
        value = read_localized_value(column, locale: locale)
        model.send(:"#{column}=", value)
      end
      model
    end

    def locales_for_reading_column(column, locale: nil)
      current_locale ||= I18n.locale
      default_locale = I18n.default_locale
      return [current_locale] unless self.class.fallbacks_for_empty_translations_for?(column)

      send("#{column}_i18n").keys.sort_by do |locale|
        case locale.to_sym
        when current_locale then '0'
        when default_locale then '1'
        else locale.to_s
        end
      end
    end

    def locales_for_columns
      I18n.supported_locales
    end
  end
end
