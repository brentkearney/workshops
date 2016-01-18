# RSpec
# spec/support/factory_girl.rb
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  
  # config.before(:suite) do  
  #   begin
  #     FactoryGirl.lint
  #   end
  # end
end

