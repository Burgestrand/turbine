RSpec::Matchers.define :delay_for do |duration|
  match do |block|
    @block = block
    start = Time.now
    block.call
    @delta = Time.now - start
    @sway = Rational(duration, 10)

    @delta.should be_within(@sway).of(duration)
  end

  chain :seconds do
  end

  failure_message_for_should do
    "expected block to take #{duration}s (± #{@sway.to_f}s), but it took #{@delta}s"
  end
end
