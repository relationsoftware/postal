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
        routes: result[:items].map { |r| serialize_route(r) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/routes/:id
    def show
      render_success(route: serialize_route(@route, include_details: true))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/routes
    def create
      route = @server.routes.build(route_params)
      parse_and_set_domain(route)
      set_endpoint(route)
      route.save!
      render_created(route: serialize_route(route))
    rescue ActiveRecord::RecordInvalid => e
      render_validation_error(e.record)
    end

    # PATCH /api/v2/admin/organizations/:organization_id/servers/:server_id/routes/:id
    def update
      @route.assign_attributes(route_params)
      parse_and_set_domain(@route)
      set_endpoint(@route) if params[:endpoint_uuid].present?
      @route.save!
      render_success(route: serialize_route(@route))
    rescue ActiveRecord::RecordInvalid => e
      render_validation_error(e.record)
    end

    # DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/routes/:id
    def destroy
      @route.destroy!
      render_deleted
    end

    private

    def find_organization
      @organization = Organization.present.find_by!(permalink: params[:organization_id])
    rescue ActiveRecord::RecordNotFound
      render_not_found("Organization not found")
    end

    def find_server
      @server = @organization.servers.present.find_by!(permalink: params[:server_id])
    rescue ActiveRecord::RecordNotFound
      render_not_found("Server not found")
    end

    def find_route
      @route = @server.routes.find_by!(uuid: params[:id])
    rescue ActiveRecord::RecordNotFound
      render_not_found("Route not found")
    end

    def route_params
      params.permit(:name, :mode, :spam_mode)
    end

    def parse_and_set_domain(route)
      # Parse domain from name if it contains "@"
      return unless route.name&.include?("@")

      local, domain_str = route.name.split("@", 2)
      route.name = local
      # Find existing domain or create a new one owned by the organization
      route.domain = @server.domains.find_by(name: domain_str) ||
                     Domain.create!(name: domain_str, server: @server, owner: @organization) do |domain|
                       domain.verified_at = Time.now
                       domain.verification_method = "DNS"
                     end
    end

    def set_endpoint(route)
      return unless params[:endpoint_uuid].present?

      endpoint_uuid = params[:endpoint_uuid]
      endpoint_type = params[:endpoint_type]

      case endpoint_type
      when "HTTPEndpoint"
        endpoint = @server.http_endpoints.find_by!(uuid: endpoint_uuid)
      when "SMTPEndpoint"
        endpoint = @server.smtp_endpoints.find_by!(uuid: endpoint_uuid)
      when "AddressEndpoint"
        endpoint = @server.address_endpoints.find_by!(uuid: endpoint_uuid)
      else
        endpoint = raise "Invalid endpoint type: #{endpoint_type}"
      end

      route.endpoint = endpoint
    end

    def serialize_route(route, include_details: false)
      json = {
        id: route.id,
        uuid: route.uuid,
        name: route.name,
        mode: route.mode,
        spam_mode: route.spam_mode,
        created_at: route.created_at&.iso8601,
        updated_at: route.updated_at&.iso8601
      }

      if route.domain.present?
        json[:domain] = {
          id: route.domain.id,
          uuid: route.domain.uuid,
          name: route.domain.name,
          verified: route.domain.verified?
        }
      end

      if route.endpoint.present?
        json[:endpoint] = {
          id: route.endpoint.id,
          uuid: route.endpoint.uuid,
          name: route.endpoint.name,
          type: route.endpoint_type
        }
      end

      if include_details && route.additional_route_endpoints.present?
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
