require 'roda'
require 'json'
require 'lib/action_handler'


module ImageGetter
  # Start the action handler and its worker
  $action = ActionHandler.new(items: Page.inprogress)
  $action.worker.start

  class App < Roda
    plugin :slash_path_empty
    plugin :halt
    plugin :json
    plugin :error_handler

    def request_data
      request.body.rewind
      JSON.parse(request.body.read,symbolize_names: true)
    end

    route do |r|
      r.root do
        "This isn't the page you're looking for ;)"
      end

      r.on 'jobs' do
        r.is do
          # List all Jobs
          r.get do
            Job.all.map(&:to_hash)
          end

          # Create a Job
          r.post do
            job = $action.create_job(request_data[:urls])
            response.status = 202
            {id: job.id}
          end
        end

        r.on ':id' do |id|
          begin
            @job = Job.with_pk! id
          rescue
            r.halt 404
          end
          # Get specific job status
          r.get('status'){ @job.status_hash }
          # Get specific job results
          r.get('results'){ @job.results_hash }
        end
      end
    end

    error do |e|
      if e.is_a?(ValidationError)
        response.status = 400
      end
      e.message
    end

  end
end
