class QueTest < Que::Job
    # Default settings for this job. These are optional - without them, jobs
    # will default to priority 100 and run immediately.
    self.run_at = proc { 5.seconds.from_now }
  
    # We use the Linux priority scale - a lower number is more important.
    self.priority = 10
  
    def run(message)
      puts message
    end

    def handle_error(error)
      puts error
      super
    end
  end