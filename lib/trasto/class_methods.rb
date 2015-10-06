module Trasto
  module ClassMethods
    def translates?(column)
      translatable_columns.include?(column.to_sym)
    end

    def fallbacks_for_empty_translations_for?(name)
      # p [:fallbacks_for_empty_translations, @fallbacks_for_empty_translations, @fallbacks_for_empty_translations[name.to_sym]]
      @fallbacks_for_empty_translations[name.to_sym]
    end

    def translated_attribute_names
      translatable_columns
    end

    def localized_accessor name, locales: I18n.available_locales
      locales.each do |locale|
        name = name.to_s.parameterize.underscore
        locale = locale.to_s.parameterize.underscore

        define_method "#{name}_#{locale}" do
          read_localized_value name, locale: locale, fallback: false
        end

        define_method "#{name}_#{locale}=" do |value|
          write_localized_value name, locale: locale
        end
      end
    end

    def create_translation_table!(*)
      #noop
    end

    def add_translation_fields!(*)
      #noop
    end

    private

    def locale_name(locale)
      I18n.t(locale, scope: :"i18n.languages", default: locale.to_s.upcase)
    end
  end
end
