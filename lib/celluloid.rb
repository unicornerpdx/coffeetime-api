class Jsonatra::Base
  def self.set_up_actors(&block)
    if defined?(PhusionPassenger)
      PhusionPassenger.on_event(:starting_worker_process) do |forked|
        if forked
          # We're in smart spawning mode.
          yield
        else
          # We're in direct spawning mode. We don't need to do anything.
          yield
        end
      end
    else
      # Not running under Passenger
      yield
    end
  end
end
