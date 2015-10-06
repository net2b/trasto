require 'trasto/version'
require 'trasto/translates'
require 'trasto/class_methods'
require 'trasto/instance_methods'
require 'trasto/translation'

module Trasto
  extend self

  def supports_hstore?
    adapter = if ActiveRecord::Base.connected?
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter === ActiveRecord::Base.connection
    else
      ActiveRecord::Base.configurations[Rails.env]["adapter"].to_sym == :postgresql
    end
  end

  @fallbacks = []
  attr_accessor :fallbacks

  def locale
    I18n.locale
  end

  def with_locale locale
    old, I18n.locale = I18n.locale, locale
    yield
  ensure
    I18n.locale = old
  end
end

Globalize = Trasto unless defined? Globalize
