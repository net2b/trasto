require 'trasto/version'
require 'trasto/translates'
require 'trasto/class_methods'
require 'trasto/instance_methods'
require 'trasto/translation'

module Trasto
  extend self

  def supports_hstore?
    ActiveRecord::Base.configurations[Rails.env]["adapter"] == "postgresql"
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
