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

    def translations_attributes= attributes
      raise attributes.inspect
    end

    def trasto_write_attribute(name, value, locale: I18n.locale)
      write_localized_value(name, value, locale: locale)
      write_default_value(name, value)
      value
    end

    def trasto_read_attribute(name, locale: I18n.locale)
      read_localized_value(name, locale: locale)
    end

    def write_default_i18n_values
      self.class.translated_attribute_names.each do |name|
        translations_hash = translation_hash_for_column(name)
        write_default_value(name, translations_hash[I18n.default_locale] || translations_hash.values.first)
      end
    end


    private

    def translation_hash_for_column(column)
      (send("#{column}_i18n") || {}).with_indifferent_access
    end

    def read_localized_value(column, locale:, fallback: :auto)
      i18n_name      = "#{column}_i18n"
      column_value   = send(i18n_name) || {}
      current_locale = (locale || I18n.locale).to_s
      default_locale = I18n.default_locale.to_s

      fallback = self.class.fallbacks_for_empty_translations_for?(column) if fallback == :auto

      if fallback
        locales = [current_locale, default_locale]
      else
        locales = [current_locale]
      end

      locales.each do |locale|
        value = column_value[locale]
        return value if value.present?
      end

      read_attribute(column) if fallback # fallback to the default value
    end

    def write_localized_value(column, value, locale:)
      translations_hash = translation_hash_for_column(column)
      send("#{column}_i18n=", translations_hash.merge(locale => value).with_indifferent_access)
    end

    def write_default_value(name, value)
      default_value = read_localized_value(name, locale: I18n.default_locale) || value

      # COPIED FROM GLOBALIZE
      # Dirty tracking, paraphrased from
      # ActiveRecord::AttributeMethods::Dirty#write_attribute.
      name_str = name.to_s
      if attribute_changed?(name_str)
        # If there's already a change, delete it if this undoes the change.
        old = changed_attributes[name_str]
        @changed_attributes.delete(name_str) if value == old
      else
        # If there's not a change yet, record it.
        # WAS: old = globalize.fetch(options[:locale], name)
        old = read_attribute(name)
        old = old.dup if old.duplicable?
        @changed_attributes[name_str] = old if value != old
      end
      # END OF COPY

      write_attribute(name, default_value)
    end

    def translation_for(locale, _build_if_missing = true)
      model = self.class::Translation.new(locale: locale)
      self.class.translated_attribute_names.each do |column|
        value = read_localized_value(column, locale: locale)
        model.send(:"#{column}=", value)
      end
      model
    end

    def locales_for_columns
      I18n.supported_locales
    end
  end
end
