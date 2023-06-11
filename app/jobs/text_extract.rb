require 'open3'

class TextExtract < Que::Job
    # Default settings for this job. These are optional - without them, jobs
    # will default to priority 100 and run immediately.
    # self.run_at = proc { 5.seconds.from_now }
  
    # We use the Linux priority scale - a lower number is more important.
    # self.priority = 10
  
    def run(document_id)
      document = Document.find(document_id)
      document.file.open do |file|
        Document.transaction do
          puts("Extracting Text #{document.id} #{document.title}")
          # output = system 'ls -lA', file.path
          # puts(output)
          stdin, stdout, stderr, wait_thr = Open3.popen3('/usr/bin/java', '-jar', '/tika-app.jar', '-t',  file.path)
          output = stdout.gets(nil)
          stdout.close
          error = stderr.gets(nil)
          stderr.close
          exit_code = wait_thr.value
          puts(exit_code)
          if exit_code != 0
            puts(error)
          end
          document.body = output
          document.save
        end
      end
    end

    def handle_error(error)
      puts error
      super
    end
  end