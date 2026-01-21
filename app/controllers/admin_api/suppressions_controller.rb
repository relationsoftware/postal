# frozen_string_literal: true

module AdminAPI
  class SuppressionsController < BaseController

    before_action :find_organization
    before_action :find_server

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/suppressions
    def index
      page = params[:page]&.to_i || 1
      result = @server.message_db.suppression_list.all_with_pagination(page)

      render_success(
        suppressions: result[:records].map { |s| suppression_json(s) },
        pagination: {
          page: page,
          total: result[:total],
          total_pages: result[:total_pages],
          per_page: result[:per_page]
        }
      )
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/suppressions
    def create
      type = params[:type]&.to_sym || :recipient
      address = params[:address]
      reason = params[:reason] || "Added via Admin API"
      days = params[:days]&.to_i

      unless address.present?
        render_error "ValidationError", message: "Address is required", status: 422
        return
      end

      options = { reason: reason }
      options[:days] = days if days.present?

      @server.message_db.suppression_list.add(type, address, options)

      render_created(
        suppression: {
          type: type,
          address: address,
          reason: reason
        }
      )
    end

    # DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/suppressions/:address
    def destroy
      type = params[:type]&.to_sym || :recipient
      address = params[:id]

      removed = @server.message_db.suppression_list.remove(type, address)

      if removed
        render_deleted
      else
        render_error "NotFound", message: "Suppression not found", status: 404
      end
    end

    private

    def find_organization
      @organization = Organization.present.find_by!(permalink: params[:organization_id])
    end

    def find_server
      @server = @organization.servers.present.find_by!(permalink: params[:server_id])
    end

    def suppression_json(suppression)
      {
        id: suppression["id"],
        type: suppression["type"],
        address: suppression["address"],
        reason: suppression["reason"],
        timestamp: suppression["timestamp"] ? Time.at(suppression["timestamp"]).iso8601 : nil,
        keep_until: suppression["keep_until"] ? Time.at(suppression["keep_until"]).iso8601 : nil
      }
    end

  end
end
