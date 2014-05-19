module ConcurrencyUtilities
  def wait_until_done(thread)
    thread.join rescue nil
  end

  def wait_until_sleep(thread)
    Thread.pass until thread.status == "sleep"
  end
end

RSpec.configure do |config|
  config.include(ConcurrencyUtilities)
end
