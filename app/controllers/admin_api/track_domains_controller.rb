# frozen_string_literal: true

module AdminAPI
  class TrackDomainsController < BaseController

    before_action :find_organization
    before_action :find_server
    before_action :find_track_domain, only: [:show, :update, :destroy, :check]

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/track_domains
    def index
      track_domains = @server.track_domains.order(:name)
      result = paginate(track_domains)

      render_success(
        track_domains: result[:items].map { |td| track_domain_json(td) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/track_domains/:id
    def show
      render_success(track_domain: track_domain_json(@track_domain, include_details: true))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/track_domains
    def create
      track_domain = @server.track_domains.build(track_domain_params)
      track_domain.save!
      render_created(track_domain: track_domain_json(track_domain))
    end

    # PATCH /api/v2/admin/organizations/:organization_id/servers/:server_id/track_domains/:id
    def update
      @track_domain.update!(track_domain_params)
      render_success(track_domain: track_domain_json(@track_domain))
    end

    # DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/track_domains/:id
    def destroy
      @track_domain.destroy!
      render_deleted
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/track_domains/:id/check
    def check
      @track_domain.check_dns
      render_success(track_domain: track_domain_json(@track_domain, include_details: true))
    end

    private

    def find_organization
      @organization = Organization.present.find_by!(permalink: params[:organization_id])
    end

    def find_server
      @server = @organization.servers.present.find_by!(permalink: params[:server_id])
    end

    def find_track_domain
      @track_domain = @server.track_domains.find_by!(uuid: params[:id])
    end

    def track_domain_params
      params.permit(:name, :ssl_enabled, :track_clicks, :track_loads)
    end

    def track_domain_json(track_domain, include_details: false)
      json = {
        id: track_domain.id,
        uuid: track_domain.uuid,
        name: track_domain.name,
        ssl_enabled: track_domain.ssl_enabled,
        track_clicks: track_domain.track_clicks,
        track_loads: track_domain.track_loads,
        created_at: track_domain.created_at&.iso8601,
        updated_at: track_domain.updated_at&.iso8601
      }

      if include_details
        json[:dns] = {
          status: track_domain.dns_status,
          error: track_domain.dns_error,
          checked_at: track_domain.dns_checked_at&.iso8601
        }
        json[:ssl] = {
          enabled: track_domain.ssl_enabled,
          certificate_expires_at: track_domain.ssl_certificate_expires_at&.iso8601
        }
      end

      json
    end

  end
end
