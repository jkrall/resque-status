require 'resque/server'
require 'resque-status'

module Resque
  module StatusServer

    VIEW_PATH = File.join(File.dirname(__FILE__), 'server', 'views')

    def self.registered(app)

      app.get '/statuses' do
        @start = params[:start].to_i
        @end = @start + (params[:per_page].blank? ? 200 : params[:per_page]).to_i
        @filter = params[:filter].blank? ? nil : params[:filter]
        @statuses = Resque::Plugins::Status::Hash.statuses(@start, @end, @filter)
        @size = @statuses.size
        status_view(:statuses)
      end

      app.get '/statuses/:id.js' do
        @status = Resque::Plugins::Status::Hash.get(params[:id])
        content_type :js
        @status.json
      end

      app.get '/statuses/:id' do
        @status = Resque::Plugins::Status::Hash.get(params[:id])
        status_view(:status)
      end

      app.post '/statuses/:id/kill' do
        Resque::Plugins::Status::Hash.kill(params[:id])
        redirect u(:statuses)
      end

      app.post '/statuses/clear' do
        Resque::Plugins::Status::Hash.clear
        redirect u(:statuses)
      end

      app.post '/statuses/clear/completed' do
        Resque::Plugins::Status::Hash.clear_completed
        redirect u(:statuses)
      end

      app.post '/statuses/clear/failed' do
        Resque::Plugins::Status::Hash.clear_failed
        redirect u(:statuses)
      end

      app.get "/statuses.poll" do
        content_type "text/plain"
        @polling = true

        @start = params[:start].to_i
        @end = @start + (params[:per_page].blank? ? 200 : params[:per_page]).to_i
        @filter = params[:filter].blank? ? nil : params[:filter]
        @statuses = Resque::Plugins::Status::Hash.statuses(@start, @end, @filter)
        @size = @statuses.size

        status_view(:statuses, {:layout => false})
      end

      app.helpers do
        def status_view(filename, options = {}, locals = {})
          erb(File.read(File.join(::Resque::StatusServer::VIEW_PATH, "#{filename}.erb")), options, locals)
        end

        def status_poll(start, filter)
          if @polling
            text = "Last Updated: #{Time.now.strftime("%H:%M:%S")}"
          else
            querystring = "start=#{start}"
            querystring += "&filter=#{filter}" if filter
            text = "<a href='#{u(request.path_info)}.poll?#{querystring}' rel='poll'>Live Poll</a>"
          end
          "<p class='poll'>#{text}</p>"
        end
      end

      app.tabs << "Statuses"

    end

  end
end

Resque::Server.register Resque::StatusServer
