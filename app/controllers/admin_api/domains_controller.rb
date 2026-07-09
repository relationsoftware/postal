# frozen_string_literal: true

module AdminAPI
  class DomainsController < BaseController

    before_action :find_organization
    before_action :find_server
    before_action :find_domain, only: [:show, :update, :destroy, :verify]

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/domains
    def index
      domains = @server.domains.order(:name)
      result = paginate(domains)

      render_success(
        domains: result[:items].map { |d| serialize_domain(d) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id
    # Supports lookup by UUID or domain name
    def show
      render_success(domain: serialize_domain(@domain, include_details: true))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/domains
    def create
      # Keep the domain server-owned (via @server.domains, owner_type=Server) so
      # that show/index/verify — which all scope through @server.domains — can
      # find it afterwards. Previously this was overridden to the organization,
      # which made created domains unreadable/unverifiable via this API.
      domain = @server.domains.build(domain_params)
      domain.verification_method = "DNS"
      domain.save!
      render_created(domain: serialize_domain(domain, include_details: true))
    rescue ActiveRecord::RecordInvalid => e
      render_validation_error(e.record)
    end

    # PATCH /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id
    def update
      @domain.update!(domain_params)
      render_success(domain: serialize_domain(@domain))
    rescue ActiveRecord::RecordInvalid => e
      render_validation_error(e.record)
    end

    # DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id
    def destroy
      @domain.destroy!
      render_deleted
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id/verify
    def verify
      # Flip ownership (verified_at) via the postal-verification TXT — check_dns
      # only refreshes the SPF/DKIM/MX/return-path statuses and never sets
      # verified_at, so without this the domain stays unverified via the API.
      @domain.verify_with_dns
      @domain.check_dns(:all)
      render_success(domain: serialize_domain(@domain, include_details: true))
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

    def find_domain
      @domain = begin
        @server.domains.find_by!(uuid: params[:id])
      rescue StandardError
        @server.domains.find_by!(name: params[:id])
      end
      render_not_found("Domain not found") if @domain.nil?
    end

    def domain_params
      params.permit(:name)
    end

    def serialize_domain(domain, include_details: false)
      json = {
        id: domain.id,
        uuid: domain.uuid,
        name: domain.name,
        verified: domain.verified?,
        verification_method: domain.verification_method,
        # Exposed so an external DNS automation tool can
        # publish the ownership-verification TXT record before calling verify.
        verification_token: domain.verification_token,
        verification_string: domain.dns_verification_string,
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
            identifier: domain.dkim_identifier
          },
          mx: {
            status: domain.mx_status,
            error: domain.mx_error,
            # Advertise the configured incoming MX hosts — these are what the UI
            # shows and what verification (check_mx_records) checks against. The
            # old domain.mx_record ("mx.<web_hostname>") didn't match dns.mx_records,
            # so MX never verified for API-created domains.
            record: Postal::Config.dns.mx_records.first,
            records: Postal::Config.dns.mx_records
          },
          return_path: {
            status: domain.return_path_status,
            error: domain.return_path_error,
            record: domain.return_path_record
          }
        }
        json[:dkim_identifier] = domain.dkim_identifier
      end

      json
    end

  end
end
