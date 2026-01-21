# frozen_string_literal: true

module AdminAPI
  class DomainsController < BaseController

    before_action :find_organization
    before_action :find_server
    before_action :find_domain, only: [:show, :update, :destroy, :verify, :check]

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/domains
    def index
      domains = @server.domains.order(:name)
      result = paginate(domains)

      render_success(
        domains: result[:items].map { |d| domain_json(d) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id
    def show
      render_success(domain: domain_json(@domain, include_details: true))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/domains
    def create
      domain = @server.domains.build(domain_params)
      domain.save!
      render_created(domain: domain_json(domain, include_details: true))
    end

    # PATCH /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id
    def update
      @domain.update!(domain_params)
      render_success(domain: domain_json(@domain))
    end

    # DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id
    def destroy
      @domain.destroy!
      render_deleted
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id/verify
    def verify
      @domain.check_dns(:all)
      render_success(domain: domain_json(@domain, include_details: true))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id/check
    def check
      @domain.check_dns(:all)
      render_success(domain: domain_json(@domain, include_details: true))
    end

    private

    def find_organization
      @organization = Organization.present.find_by!(permalink: params[:organization_id])
    end

    def find_server
      @server = @organization.servers.present.find_by!(permalink: params[:server_id])
    end

    def find_domain
      @domain = @server.domains.find_by!(uuid: params[:id]) rescue @server.domains.find_by!(name: params[:id])
    end

    def domain_params
      params.permit(:name)
    end

    def domain_json(domain, include_details: false)
      json = {
        id: domain.id,
        uuid: domain.uuid,
        name: domain.name,
        verified: domain.verified?,
        verification_method: domain.verification_method,
        created_at: domain.created_at&.iso8601,
        updated_at: domain.updated_at&.iso8601
      }

      if include_details
        json[:dns] = {
          spf: {
            status: domain.spf_status,
            error: domain.spf_error,
            record: domain.spf_record
          },
          dkim: {
            status: domain.dkim_status,
            error: domain.dkim_error,
            record: domain.dkim_record,
            record_name: domain.dkim_record_name
          },
          mx: {
            status: domain.mx_status,
            error: domain.mx_error
          },
          return_path: {
            status: domain.return_path_status,
            error: domain.return_path_error,
            domain: domain.return_path_domain
          }
        }

        json[:dkim_identifier] = domain.dkim_identifier
        json[:dkim_identifier_string] = domain.dkim_identifier_string
      end

      json
    end

  end
end
