# Capybara::Reloads

Reload the page when a Capybara selector fails. After reload assert the selector again. Repeat until the number of reloads is equal to allow_max_reloads. Store screenshot and html version of the page to allow for easier debug and understanding of why the spec has failed.

When used for a randomly failing spec it will store and show the states before every load.

```ruby
expect(page).to have_xpath("//..the xpath value", 
    allow_max_reloads: Capybara::Reloads.recommended_allow_max_reloads)
```

If the selector is first not matched and matched after reload capybara-reloads will report it as:

```bash
Failures:

  1) Articles system specs
     Failure/Error: raise message
     
     RuntimeError:
         The example initially failed, but after 1 reloads it was successful.
         States are shown below in order:
     
       State 0
       {
         "html": ".../tmp/capybara/screenshot_2022-12-25-21-57-53.129.html",
         "image": ".../tmp/capybara/screenshot_2022-12-25-21-57-53.129.png",
         "exception": "expected to find xpath \"//a[@class='select2-choice']/span[text()='United States']\" but there were no matches",
         "reloads_made": 0
       }
       State 1
       {
         "html": ".../tmp/capybara/screenshot_2022-12-25-21-57-53.906.html",
         "image": ".../tmp/capybara/screenshot_2022-12-25-21-57-53.906.png",
         "exception": null,
         "reloads_made": 1
       }
     
     [Screenshot Image]: .../tmp/capybara/failures_r_spec_example_groups_article_807.png

     
     # .../capybara-reloads/lib/capybara/reloads/node/matchers.rb:54:in `after_success'
     # .../capybara-reloads/lib/capybara/reloads/node/matchers.rb:28:in `block in with_reload_on_fail'
     # .../capybara-reloads/lib/capybara/reloads/node/matchers.rb:23:in `loop'
     # .../capybara-reloads/lib/capybara/reloads/node/matchers.rb:23:in `with_reload_on_fail'
     # .../capybara-reloads/lib/capybara/reloads/node/matchers.rb:7:in `assert_selector'
     # .../gems/capybara-3.38.0/lib/capybara/session.rb:773:in `assert_selector'
     # .../gems/capybara-3.38.0/lib/capybara/rspec/matchers/have_selector.rb:18:in `element_matches?'
     # .../gems/capybara-3.38.0/lib/capybara/rspec/matchers/base.rb:51:in `matches?'
     # ./spec/system/articles_spec.rb:101:in `block (3 levels) in <top (required)>'
     # ./spec/system/articles_spec.rb:157:in `block (3 levels) in <top (required)>'
     # ./spec/system/articles_spec.rb:135:in `upto'
     # ./spec/system/articles_spec.rb:135:in `block (2 levels) in <top (required)>'
     # ./spec/spec_helper.rb:664:in `block (2 levels) in <top (required)>'
     # .../gems/webmock-3.14.0/lib/webmock/rspec.rb:37:in `block (2 levels) in <top (required)>'

Finished in 13.71 seconds (files took 4.49 seconds to load)
```

## What's the goal and the job to be done

Sometimes a spec for an application that uses JavaScript fails "randomly". The goal of capybara-reloads is to help identify and resolve specs that are randomly failing due to JavaScript timing, load and reload precularities in non-trivial platform. It helps by saving a screenshot and html version of the page, reloading the page, and trying the selector again. If the second or the third time the selector is matched then the gem reports this.

An alternative to capybara-reloads is:

```ruby
0.upto(2) do 
    begin 
        expect(page).to have_xpath "//..the xpath"
    rescue Exception=>e
        save screenshots and html of the page        
        page.refresh
    end
end
```
but the above has to be done for every call and makes the spec more difficult to read and maintain. capybara-reloads patches Capybara in a way that makes enabling the reload for every or for specific selector very easy. 

## Reasoning

A non-trivial suite of system specs running over a non-trivial platform often contains specs that fail randomly, generally due to part of the JS not loading properly or not loading at all. 

It is difficult to debug these randomly failing specs.

Capybara provides a mechanism to wait for an expression to be matched agains a page. Check Capybara.default_max_wait_time and the 'wait: ' options on selectors. 

There are cases where waiting for an expression does not help as the JS has not loaded. One reason might be that the JS is loaded through a network request and is inserted on the page without a proper async attribute on the script tag. Another reason might a a bug in a JS around timing issues. Non-trivial apps often load JS from sprockets, webpack, esbuild, vite, network and others where the source is comming from rails gems, npm packages or as hosted scripts. 

The issue with randomly failing spec is that they reduce the trust that a team has in the system specs. Team members might be reluctant to develop and run a proper system specs when a spec fails from time to time. 

During the development of this gem I stumbled upon such a case where the JS on the page was not loaded at all. I ran a spec 100 times and the results were:

- 100 times - 0 failed
- 100 times - Run 2 and Run 14 failed
- 100 times - 0 failed
- 1000 times - Run 353, 370, 409, 575, 624, 721, 959 failed 

capybara-reloads is **not designed to hide this issues**. These are real issues that happen for real user requests. It is very possible that 1 in 100-200 requests from the set above loads a page that is broken for the user. Users generally reload the page and move one. If it happens once in a few hundred requests they might not even notice it.

capybara-reloads is **designed to help identify, track and bring more light to this issue**. In this way teams could have more visibility on the patterns in the suites. They could budget proper time to address these issue when they feel they are important. capybara-reloads also provides a way to track information like images and html versions of the page, to log information and to place brakepoints for when this issues occur.

## Installation

Add to gem file

    $ gem install capybara-reloads

or add to Gemfile

    gem 'capybara-reloads'

## Usage

capybara-reloads is non-intrusive. It will extend Capybara, but will not change behavior and will not cause a reload unless enabled. **To enable it the value of 'allow_max_reloads' should be explicitly set.**

For RSpec add the configuration to spes/spec_helper.rb or spec/rails_helper.rb

### To enable globally for all specs

This will enable capybara-reloads for every matcher.

```ruby
Capybara::Reloads.allow_max_reloads = 2
```

It is recommended to use the Capybara::Reloads.recommended_allow_max_reloads value like:

```ruby
Capybara::Reloads.allow_max_reloads = Capybara::Reloads.recommended_allow_max_reloads
``` 

### To enable for specific matcher

```ruby
expect(page).to have_xpath "//..the xpath value", allow_max_reloads: 2
```

or the recommended

```ruby
expect(page).to have_xpath("//..the xpath value", 
    allow_max_reloads: Capybara::Reloads.recommended_allow_max_reloads)
```

### Stop at a breakpoint only when reload 'fixed it'

The example below configures capybara-reloads with a breakpoint where a debugger will stop only after a selector was first not matched, then page was refreshed and then the selector was matched for the second page. 

```ruby
Capybara::Reloads.allow_max_reloads = 1
Capybara::Reloads.reload_fixed_it_callback do |args|
    debugger
    Capybara::Reloads.construct_message(args)
end
```

## Configuration

```ruby
# The number of reloads that capybara-reloads will do. It will check if the selector is matched for every returned page.
# It is a bad idea to have this set to a large number and 1-2 is the recommended on.
# 
# Default value is 0 which disables any reloads
Capybara::Reloads.allow_max_reloads

# The number of max reloads recommended by capybara-reloads author  
Capybara::Reloads.recommended_allow_max_reloads

# By default when capybara-reloads reloads the page and the matcher is resolved on the new page, we will throw an expection even though the new
# page makes the specs pass. In this way we clearly inform that this spec fails and should be inspected. 
# When you are ok with the test continuing you can set 'only_report' to true
#
# Require.
# Default value is false
Capybara::Reloads::only_report

# A Proc called before reload of the page
# 
# It is useful to print a different kind of message, to stop, debug and inspect the state.
#
# Capybara::Reloads.before_reload_callback = Proc.new do |args|
#   args[:base] # contains the instance of Capybara::Node::Base where we assert the matcher
#   args[:expcetion] # contains the Capybara::ElementNotFound exception that occurred
# end
# 
# Optional. Can be set to nil
# Default value is provided that prints a message that the page will be reloaded
Capybara::Reloads.before_reload_callback

# A Proc called to reload the page
#
# Capybara::Reloads.reload_callback = Proc.new do |args|
#   args[:base] # contains the instance of Capybara::Node::Base where we assert the matcher
# end
# 
# Required. 
# Default value is provided. Check source code of what it is as of current version 
Capybara::Reloads.reload_callback

# A proc called after capybara-reloads has reloaded the page and the new page passes the test.
# This means that the reload has 'fixed the test'. By default screenshot and html version 
# of the page are saved in a 'states' array after every assert of the matcher. 
# 
# Capybara::Reloads.reload_callback = Proc.new do |args|
#   args[:states] # contains the states after every assert of the matcher
#   # The states object contains
#   {
#     :html=>"/path/to/html",
#     :image=>"/path/to/screenshot",
#     :exception=>... # The Capybara::ElementNotFound exception that occurred,
#     :reloads_made=>... # The number of reloads that were made when this state was saved
#   }
#   args[:reloads_made] # contains the reloads that were already made before this proc was called
#   
#   # This return value should be a message.
#   # It will be reported or raise based on Capybara::Reloads.only_report
#   # This gives the chance to add additional things to the report message
#   # that are important for this spec/suite
#   # The default message is constructed with Capybara::Reloads.construct_message(args)
#   message
# end
# 
# Required.
# Default value is provided. Check source code of what it is as of current version
# Should return a message
Capybara::Reloads.reload_fixed_it_callback 
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thebravoman/capybara-reloads.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
