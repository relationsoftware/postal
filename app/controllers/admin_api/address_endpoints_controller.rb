# frozen_string_literal: true

module AdminAPI
  class AddressEndpointsController < BaseController

    before_action :find_organization
    before_action :find_server
    before_action :find_endpoint, only: [:show, :update, :destroy]

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/address_endpoints
    def index
      endpoints = @server.address_endpoints.order(:address)
      result = paginate(endpoints)

      render_success(
        address_endpoints: result[:items].map { |e| endpoint_json(e) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/address_endpoints/:id
    def show
      render_success(address_endpoint: endpoint_json(@endpoint))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/address_endpoints
    def create
      endpoint = @server.address_endpoints.build(endpoint_params)
      endpoint.save!
      render_created(address_endpoint: endpoint_json(endpoint))
    end

    # PATCH /api/v2/admin/organizations/:organization_id/servers/:server_id/address_endpoints/:id
    def update
      @endpoint.update!(endpoint_params)
      render_success(address_endpoint: endpoint_json(@endpoint))
    end

    # DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/address_endpoints/:id
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
      @endpoint = @server.address_endpoints.find_by!(uuid: params[:id])
    end

    def endpoint_params
      params.permit(:address)
    end

    def endpoint_json(endpoint)
      {
        id: endpoint.id,
        uuid: endpoint.uuid,
        address: endpoint.address,
        created_at: endpoint.created_at&.iso8601,
        updated_at: endpoint.updated_at&.iso8601
      }
    end

  end
end
