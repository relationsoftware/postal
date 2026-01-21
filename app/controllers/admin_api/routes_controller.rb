# frozen_string_literal: true

module AdminAPI
  class RoutesController < BaseController

    before_action :find_organization
    before_action :find_server
    before_action :find_route, only: [:show, :update, :destroy]

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/routes
    def index
      routes = @server.routes.order(:name)
      result = paginate(routes)

      render_success(
        routes: result[:items].map { |r| route_json(r) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/routes/:id
    def show
      render_success(route: route_json(@route, include_details: true))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/routes
    def create
      route = @server.routes.build(route_params)
      set_endpoint(route)
      route.save!
      render_created(route: route_json(route))
    end

    # PATCH /api/v2/admin/organizations/:organization_id/servers/:server_id/routes/:id
    def update
      @route.assign_attributes(route_params)
      set_endpoint(@route) if params[:endpoint_uuid].present?
      @route.save!
      render_success(route: route_json(@route))
    end

    # DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/routes/:id
    def destroy
      @route.destroy!
      render_deleted
    end

    private

    def find_organization
      @organization = Organization.present.find_by!(permalink: params[:organization_id])
    end

    def find_server
      @server = @organization.servers.present.find_by!(permalink: params[:server_id])
    end

    def find_route
      @route = @server.routes.find_by!(uuid: params[:id])
    end

    def route_params
      params.permit(:name, :mode, :spam_mode)
    end

    def set_endpoint(route)
      return unless params[:endpoint_uuid].present?

      endpoint_uuid = params[:endpoint_uuid]
      endpoint_type = params[:endpoint_type]

      endpoint = case endpoint_type
                 when "HTTPEndpoint"
                   @server.http_endpoints.find_by!(uuid: endpoint_uuid)
                 when "SMTPEndpoint"
                   @server.smtp_endpoints.find_by!(uuid: endpoint_uuid)
                 when "AddressEndpoint"
                   @server.address_endpoints.find_by!(uuid: endpoint_uuid)
                 else
                   # Try to find by UUID in all endpoint types
                   @server.http_endpoints.find_by(uuid: endpoint_uuid) ||
                     @server.smtp_endpoints.find_by(uuid: endpoint_uuid) ||
                     @server.address_endpoints.find_by(uuid: endpoint_uuid)
                 end

      raise ActiveRecord::RecordNotFound, "Endpoint not found" unless endpoint

      route.endpoint = endpoint
    end

    def route_json(route, include_details: false)
      json = {
        id: route.id,
        uuid: route.uuid,
        name: route.name,
        mode: route.mode,
        spam_mode: route.spam_mode,
        endpoint_type: route.endpoint_type,
        created_at: route.created_at&.iso8601,
        updated_at: route.updated_at&.iso8601
      }

      if route.endpoint.present?
        json[:endpoint] = {
          id: route.endpoint.id,
          uuid: route.endpoint.uuid,
          name: route.endpoint.name,
          type: route.endpoint_type
        }
      end

      if include_details
        json[:additional_endpoints] = route.additional_route_endpoints.map do |are|
          {
            id: are.endpoint.id,
            uuid: are.endpoint.uuid,
            name: are.endpoint.name,
            type: are.endpoint_type
          }
        end
      end

      json
    end

  end
end
