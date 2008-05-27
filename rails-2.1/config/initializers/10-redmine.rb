
ActiveRecord::Errors.default_error_messages = {
  :inclusion => "activerecord_error_inclusion",
  :exclusion => "activerecord_error_exclusion",
  :invalid => "activerecord_error_invalid",
  :confirmation => "activerecord_error_confirmation",
  :accepted  => "activerecord_error_accepted",
  :empty => "activerecord_error_empty",
  :blank => "activerecord_error_blank",
  :too_long => "activerecord_error_too_long",
  :too_short => "activerecord_error_too_short",
  :wrong_length => "activerecord_error_wrong_length",
  :taken => "activerecord_error_taken",
  :not_a_number => "activerecord_error_not_a_number"
}

ActionView::Base.field_error_proc = Proc.new{ |html_tag, instance| "#{html_tag}" }

Mime::SET << Mime::CSV unless Mime::SET.include?(Mime::CSV)
Mime::Type.register 'application/pdf', :pdf

GLoc.set_config :default_language => :en
GLoc.clear_strings
GLoc.set_kcode
GLoc.load_localized_strings
GLoc.set_config(:raise_string_not_found_errors => false)

require 'redmine'