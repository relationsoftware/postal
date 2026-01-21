# frozen_string_literal: true

module AdminAPI
  class IpPoolsController < BaseController

    before_action :find_ip_pool, only: [:show, :update, :destroy]

    # GET /api/v2/admin/ip_pools
    def index
      ip_pools = IPPool.order(:name)
      result = paginate(ip_pools)

      render_success(
        ip_pools: result[:items].map { |p| ip_pool_json(p) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/ip_pools/:id
    def show
      render_success(ip_pool: ip_pool_json(@ip_pool, include_details: true))
    end

    # POST /api/v2/admin/ip_pools
    def create
      ip_pool = IPPool.new(ip_pool_params)
      ip_pool.save!
      render_created(ip_pool: ip_pool_json(ip_pool))
    end

    # PATCH /api/v2/admin/ip_pools/:id
    def update
      @ip_pool.update!(ip_pool_params)
      render_success(ip_pool: ip_pool_json(@ip_pool))
    end

    # DELETE /api/v2/admin/ip_pools/:id
    def destroy
      @ip_pool.destroy!
      render_deleted
    end

    private

    def find_ip_pool
      @ip_pool = IPPool.find_by!(uuid: params[:id])
    end

    def ip_pool_params
      params.permit(:name, :default)
    end

    def ip_pool_json(ip_pool, include_details: false)
      json = {
        id: ip_pool.id,
        uuid: ip_pool.uuid,
        name: ip_pool.name,
        default: ip_pool.default,
        created_at: ip_pool.created_at&.iso8601,
        updated_at: ip_pool.updated_at&.iso8601
      }

      if include_details
        json[:ip_addresses] = ip_pool.ip_addresses.map do |ip|
          {
            id: ip.id,
            ipv4: ip.ipv4,
            ipv6: ip.ipv6,
            hostname: ip.hostname,
            priority: ip.priority
          }
        end

        json[:organizations] = ip_pool.organizations.map do |org|
          {
            id: org.id,
            uuid: org.uuid,
            name: org.name,
            permalink: org.permalink
          }
        end
      end

      json
    end

  end
end
