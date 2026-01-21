# frozen_string_literal: true

module AdminAPI
  class IpAddressesController < BaseController

    before_action :find_ip_pool
    before_action :find_ip_address, only: [:show, :update, :destroy]

    # GET /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses
    def index
      ip_addresses = @ip_pool.ip_addresses.order(:ipv4)
      result = paginate(ip_addresses)

      render_success(
        ip_addresses: result[:items].map { |ip| ip_address_json(ip) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses/:id
    def show
      render_success(ip_address: ip_address_json(@ip_address))
    end

    # POST /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses
    def create
      ip_address = @ip_pool.ip_addresses.build(ip_address_params)
      ip_address.save!
      render_created(ip_address: ip_address_json(ip_address))
    end

    # PATCH /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses/:id
    def update
      @ip_address.update!(ip_address_params)
      render_success(ip_address: ip_address_json(@ip_address))
    end

    # DELETE /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses/:id
    def destroy
      @ip_address.destroy!
      render_deleted
    end

    private

    def find_ip_pool
      @ip_pool = IPPool.find_by!(uuid: params[:ip_pool_id])
    end

    def find_ip_address
      @ip_address = @ip_pool.ip_addresses.find(params[:id])
    end

    def ip_address_params
      params.permit(:ipv4, :ipv6, :hostname, :priority)
    end

    def ip_address_json(ip_address)
      {
        id: ip_address.id,
        ipv4: ip_address.ipv4,
        ipv6: ip_address.ipv6,
        hostname: ip_address.hostname,
        priority: ip_address.priority,
        created_at: ip_address.created_at&.iso8601,
        updated_at: ip_address.updated_at&.iso8601
      }
    end

  end
end
