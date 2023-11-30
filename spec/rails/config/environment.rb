# frozen_string_literal: true

RAILS_ENVIRONMENT_LOADED = true

require 'ostruct'
Rails = OpenStruct.new
Rails.logger = 'rails default logger'
