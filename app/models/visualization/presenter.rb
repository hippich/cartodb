# encoding: utf-8
require 'json'
require 'ostruct'
require_relative '../layer/presenter'
require_relative '../overlay/presenter'

module CartoDB
  module Visualization
    class Presenter
      VERSION = "0.1.0"

      def initialize(visualization, options={}, configuration={}, logger=nil)
        @visualization    = visualization
        @map              = visualization.map
        @options          = { full: true }.merge(options)
        @configuration    = configuration
        logger.info(map.inspect) if logger
      end #initialize
    
      def to_poro
        {
          id:             visualization.id,
          version:        VERSION,
          title:          visualization.name,
          description:    visualization.description,
          url:            options.delete(:url),
          map_provider:   map.provider,
          bounds:         bounds_from(map),
          center:         map.center,
          zoom:           map.zoom,
          updated_at:     map.viz_updated_at,
          table:          visualization.table_data,
          layers:         layer_data_for(visualization),
          overlays:       overlay_data_for(visualization)
        }
      end #to_poro

      private

      attr_reader :visualization, :map, :options, :configuration

      def bounds_from(map)
        ::JSON.parse("[#{map.view_bounds_sw}, #{map.view_bounds_ne}]")
      rescue => exception
      end #bounds_from

      def layer_data_for(visualization)
        ordered_layers_for(visualization).map do |layer|
          Layer::Presenter.new(layer, options, configuration).to_poro
        end
      end #layer_data_for

      def overlay_data_for(map)
        ordered_overlays_for(visualization).map do |overlay| 
          Overlay::Presenter.new(overlay).to_poro
        end
      end #overlay_data_for

      def ordered_layers_for(visualization)
        visualization.layers(:base)       + 
        cartodb_layers_for(visualization) + 
        visualization.layers(:other)
      end #ordered_layers_for

      def cartodb_layers_for(visualization)
        [OpenStruct.new( 
          type:   'layergroup',
          layers: visualization.layers(:cartodb)
        )]
      end #cartodb_layers_for

      def ordered_overlays_for(visualization)
        hardcoded_overlays + visualization.overlays.to_a
      end #ordered_overlays_for

      def hardcoded_overlays
        [zoom_overlay, loader_overlay]
      end #hardcoded_overlays

      def zoom_overlay
        OpenStruct.new(
          type: "zoom",
          template: '<a class="zoom_in">+</a><a class="zoom_out">-</a>'
        )
      end #zoom_overlay

      def loader_overlay
        OpenStruct.new(
          type: "loader",
          template: '<div class="loader"></div>'
        )
      end #loader_overlay
    end # Presenter
  end # Visualization
end # CartoDB
