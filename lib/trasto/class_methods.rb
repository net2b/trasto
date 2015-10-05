module Trasto
  module ClassMethods
    def translates?(column)
      translatable_columns.include?(column.to_sym)
    end

    def fallbacks_for_empty_translations_for?(name)
      @fallbacks_for_empty_translations[name.to_sym]
    end

    def translated_attribute_names
      translatable_columns
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
