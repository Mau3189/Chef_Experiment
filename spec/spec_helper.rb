Dir[File.dirname(__FILE__) + '/../lib/aws_instance_manager.rb'].each { |file| require file }
RSpec.configure do |config|
  config.color_enabled = true
  config.fail_fast = true
end
