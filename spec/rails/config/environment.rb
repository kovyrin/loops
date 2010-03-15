RAILS_ENVIRONMENT_LOADED = true

require 'ostruct'
Rails = OpenStruct.new([:logger])
Rails.logger = 'rails default logger'