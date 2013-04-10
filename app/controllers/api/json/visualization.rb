# encoding: utf-8
require 'sinatra/base'
require 'json'
require_relative '../../../models/visualization/member'
require_relative '../../../models/visualization/presenter'
require_relative '../../../models/visualization/collection'

module CartoDB
  module Visualization
    class API < Sinatra::Base
      get '/viz/:id/viz' do
        begin
          member    = Member.new(id: params[:id]).fetch
          return [200, member.to_json] if member.public?
          [204]
        rescue KeyError
          head :forbidden
        end
      end #get /viz/:id/viz

      get '/api/v1/visualizations' do
        collection  = Visualization::Collection.new.fetch(params.dup)
        response    = {
          visualizations: collection,
          total_entries:  collection.count
        }.to_json

        [200, response]
      end

      post '/api/v1/visualizations' do
        member      = Member.new(payload).store
        collection  = Visualization::Collection.new.fetch
        collection.add(member)
        collection.store

        response  = member.attributes.to_json
        [201, response]
      end # post /api/visualizations

      get '/api/v1/visualizations/:id' do
        begin
          member    = Member.new(id: params.fetch('id')).fetch
          response  = member.attributes.to_json
          [200, response]
        rescue KeyError
          [404]
        end
      end # get /api/v1/visualizations/:id
      
      put '/api/v1/visualizations/:id' do
        begin
          member            = Member.new(id: params.fetch('id')).fetch
          member.attributes = payload
          member.store
          [200, member.attributes.to_json]
        rescue KeyError
          [404]
        end
      end # put /api/v1/visualizations/:id

      delete '/api/v1/visualizations/:id' do
        member      = Member.new(id: params.fetch('id'))
        member.delete
        [204]
      end # delete '/api/v1/visualizations/:id

      helpers do
        def payload
          ::JSON.parse(request.body.read.to_s || String.new)
        end #payload
      end 
    end # Visualization
  end # API
end # CartoDB
