# frozen_string_literal: true

module AdminAPI
  class SmtpEndpointsController < BaseController

    before_action :find_organization
    before_action :find_server
    before_action :find_endpoint, only: [:show, :update, :destroy]

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/smtp_endpoints
    def index
      endpoints = @server.smtp_endpoints.order(:name)
      result = paginate(endpoints)

      render_success(
        smtp_endpoints: result[:items].map { |e| endpoint_json(e) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/smtp_endpoints/:id
    def show
      render_success(smtp_endpoint: endpoint_json(@endpoint))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/smtp_endpoints
    def create
      endpoint = @server.smtp_endpoints.build(endpoint_params)
      endpoint.save!
      render_created(smtp_endpoint: endpoint_json(endpoint))
    end

    # PATCH /api/v2/admin/organizations/:organization_id/servers/:server_id/smtp_endpoints/:id
    def update
      @endpoint.update!(endpoint_params)
      render_success(smtp_endpoint: endpoint_json(@endpoint))
    end

    # DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/smtp_endpoints/:id
    def destroy
      @endpoint.destroy!
      render_deleted
    end

    private

    def find_organization
      @organization = Organization.present.find_by!(permalink: params[:organization_id])
    end

    def find_server
      @server = @organization.servers.present.find_by!(permalink: params[:server_id])
    end

    def find_endpoint
      @endpoint = @server.smtp_endpoints.find_by!(uuid: params[:id])
    end

    def endpoint_params
      params.permit(:name, :hostname, :port, :ssl_mode)
    end

    def endpoint_json(endpoint)
      {
        id: endpoint.id,
        uuid: endpoint.uuid,
        name: endpoint.name,
        hostname: endpoint.hostname,
        port: endpoint.port,
        ssl_mode: endpoint.ssl_mode,
        created_at: endpoint.created_at&.iso8601,
        updated_at: endpoint.updated_at&.iso8601
      }
    end

  end
end
