require "active_support"
require "active_record"
require "miq_performance/middleware"

# Stub rails
class Rails
  Application = Struct.new :config
  Config      = Struct.new :filter_parameters

  def self.application
    Application.new Config.new([:password, :verify, :data])
  end
end

shared_examples "middleware functionality for" do |middleware_order|
  middleware_order.each do |name|
    it "loads #{name} middleware" do
      expect(subject.private_methods.include? "#{name}_start".to_sym).to  be true
      expect(subject.private_methods.include? "#{name}_finish".to_sym).to be true
      expect(subject.private_methods.include? "#{name}_initialize".to_sym).to be true
    end
  end

  describe "#call" do
    it "skips the middleware if the proper header is not present" do
      expect(subject).to receive(:performance_middleware_start).never
      expect(subject).to receive(:performance_middleware_finish).never

      subject.call({})
    end

    it "runs the middleware if the proper header is present" do
      expect(subject).to receive(:performance_middleware_start).once
      expect(subject).to receive(:performance_middleware_finish).once

      subject.call({ MiqPerformance::Middleware::PERFORMANCE_HEADER => true})
    end

    it "runs the middleware in order" do
      allow(subject).to receive(:performance_middleware_finish)

      middleware_order.each do |name|
        expect(subject).to receive("#{name}_start").ordered
      end

      subject.call({ MiqPerformance::Middleware::PERFORMANCE_HEADER => true})
    end

    it "finishes the middleware in reverse order" do
      allow(subject).to receive(:performance_middleware_start)

      middleware_order.reverse.each do |name|
        expect(subject).to receive("#{name}_finish").ordered
      end

      subject.call({ MiqPerformance::Middleware::PERFORMANCE_HEADER => true})
    end
  end
end

describe MiqPerformance::Middleware do

  context "with no configuration set (default)" do
    subject { described_class.new(Proc.new {}) }
    include_examples "middleware functionality for",
                     [:stackprof, :activesupport_timers, :activerecord_queries]
  end
end
