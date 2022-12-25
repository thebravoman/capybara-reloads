# frozen_string_literal: true

require_relative "reloads/version"
require_relative "reloads/node/matchers"

module Capybara
  module Reloads
    class Error < StandardError; end
      @@recommended_allow_max_reloads = 2

    # By default Capybara::Reloads should have no impact
    # It should be explicitly enabled, by setting to the recommended_allow_max_reloads with
    # Capybara::Reloads.allow_max_reloads = CapybaraReload.recommended_allow_max_reloads
    @@allow_max_reloads = 0

    # The goal of Capybara::Reloads is to help identify places where the JS does not load
    # not to hide them. By default Capybara::Reloads will try to reload to see if the error
    # we can continue, but even if we do it will by default report this as an error.
    # In this way we have clearly shown that this example depends on reloading the page
    # and this is the real error here. Not that we can't find an element on the page
    # but that this element is found sometimes and if we refresh it will be found
    # more often than not
    #
    # To make Capybara::Reloads continue use only_report
    @@only_report = false

    @@before_reload_callback = Proc.new do |args|
      puts "Refreshing the page as an exception occurred: #{args[:exception].message}"
    end

    @@reload_callback = Proc.new do |args|
      base = args[:base]
      base.session.refresh
    end

    @@reload_fixed_it_callback = Proc.new do |args|
      Capybara::Reloads.construct_message(args)
    end

    # @param args
    # @params states
    # @params reloads_made
    def self.construct_message args
       message = <<-MESSAGE
  The example initially failed, but after #{args[:reloads_made]} reloads it was successful.
  States are shown below in order:
  MESSAGE
      args[:states].each_with_index do |state, index|
        message += "\n"
        message += "State #{index}\n"
        message += JSON.pretty_generate(state)
      end
      message
    end

    def self.recommended_allow_max_reloads
      @@recommended_allow_max_reloads
    end

    def self.allow_max_reloads
      @@allow_max_reloads
    end

    def self.allow_max_reloads=(reloads)
      if reloads > @@recommended_allow_max_reloads
        puts "You are setting Capybara::Reloads.allow_max_reloads to be #{reloads}."
        puts "This is more than the recommended value of #{@@recommended_allow_max_reloads} (Capybara::Reloads.recommended_allow_max_reloads)."
        puts "Please refer to documentation about why this might be a bad idea."
      end
      @@allow_max_reloads = reloads
    end

    def self.only_report
      @@only_report
    end

    def self.only_report=(value)
      @@only_report = value
    end

    def self.before_reload_callback
      @@before_reload_callback
    end

    def self.before_reload_callback=(the_proc)
      @@before_reload_callback = the_proc
    end

    def self.reload_callback
      @@reload_callback
    end

    def self.reload_callback=(the_proc)
      @@reload_callback = the_proc
    end

    def self.reload_fixed_it_callback
      @@reload_fixed_it_callback
    end

  end
end

Capybara::Node::Base.send(:prepend, Capybara::Reloads::Node::Matchers)