module Capybara
  module Reloads
    module Node
      module Matchers

        def assert_selector(*args, &optional_filter_block)
          with_reload_on_fail(args.last.delete(:allow_max_reloads)) do
            super
          end
        end

        private

        def with_reload_on_fail allow_max_reloads_arg
          local_max_reloads = allow_max_reloads_arg || Capybara::Reloads.allow_max_reloads
          unless local_max_reloads.is_a?(Numeric) || local_max_reloads == nil
            raise "'allow_max_reloads' must be Numeric or nil"
          end
          local_max_reloads == local_max_reloads || 0
          result = nil
          reloads_made = 0
          @previous_states = []
          loop do
            begin
              result = yield
              # there is a result. We don't have to retry
              # If previously there were errors get the current state and report
              after_success reloads_made
              break
            rescue Capybara::ElementNotFound => e
              record_state e, reloads_made
              if reloads_made == local_max_reloads
                raise e
              end
              reloads_made+=1
              args = { base: self, exception: e }
              # Allows us to change the way we report that a refresh should happend
              if Capybara::Reloads.before_reload_callback != nil
                Capybara::Reloads.before_reload_callback.call(args)
              end
              Capybara::Reloads.reload_callback.call(args)
            end
          end
          result
        end

        def after_success reloads_made
          if @previous_states.size > 0
            record_state nil, reloads_made
            message = Capybara::Reloads.reload_fixed_it_callback.call(states: @previous_states, reloads_made: reloads_made)
            if Capybara::Reloads.only_report
              puts message
            else
              raise message
            end
            @previous_states = []
          end
        end

        def record_state exception, reloads_made
          html_and_image = Capybara::Screenshot.screenshot_and_save_page
          # html_and_image is of the form
          # {:html=>"...screenshot_2022-12-25-17-42-37.712.html", :image=>"...screenshot_2022-12-25-17-42-37.712.png"}
          exception_hash = exception ?
            {
              instance: exception,
              backtrace: exception.backtrace
            } : nil

          @previous_states << html_and_image.merge({
            exception: exception_hash,
            reloads_made: reloads_made
          })
        end

      end
    end
  end
end