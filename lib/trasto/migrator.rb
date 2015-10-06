module Trasto
  class Migrator
    module Name
      def name
        table_name.classify
      end
    end

    def initialize(table_name, translations_table_name: nil, column_names: nil)
      table_name = table_name.to_s
      translations_table_name ||= "#{table_name.singularize}_translations"
      namespace = self.class.create_namespace

      translations_class = Class.new(ActiveRecord::Base) { extend Name; self.table_name = translations_table_name }
      model_class        = Class.new(ActiveRecord::Base) { extend Name; self.table_name = table_name }
      namespace.const_set translations_class.name, translations_class
      namespace.const_set model_class.name, model_class

      model_class.class_eval do
        has_many :translations, class_name: namespace.const_get(translations_class.name), foreign_key: "#{table_name.singularize}_id"
      end

      model_class.find_each do |record|
        translations = {}
        record.translations.pluck(:locale, *column_names).each do |(locale, *column_values)|
          column_names.each_with_index do |name, index|
            value = column_values[index]
            next if name.blank?
            translations[name] ||= {}
            translations[name][locale] = value
          end
        end
        column_names.each do |name|
          record["#{name}_i18n"] = translations[name]
        end
        record.save!
      end
    end

    def self.create_namespace
      @namespace_count ||= 0
      @namespace_count += 1
      namespace = Module.new
      const_set :"Namespace#{@namespace_count}", namespace
      namespace
    end
  end
end
