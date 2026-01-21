# frozen_string_literal: true

module AdminAPI
  # The Admin API provides full administrative control over Postal.
  # It allows external applications to manage organizations, servers,
  # domains, credentials, routes, and all other resources.
  #
  # Authentication is performed using an X-Admin-API-Key header.
  # Admin API keys can be created by admin users in the Postal UI
  # or via the postal admin:api_key:create command.
  class BaseController < ActionController::Base

    skip_before_action :set_browser_id
    skip_before_action :verify_authenticity_token

    before_action :start_timer
    before_action :authenticate

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_validation_error
    rescue_from ActionController::ParameterMissing, with: :render_parameter_missing

    private

    def start_timer
      @start_time = Time.now.to_f
    end

    def authenticate
      key = request.headers["X-Admin-API-Key"]
      if key.blank?
        render_error "Unauthorized", message: "Missing X-Admin-API-Key header", status: 401
        return
      end

      # Check if the key matches the configured admin API key
      configured_key = Postal::Config.postal.admin_api_key
      if configured_key.blank?
        render_error "Unauthorized", message: "Admin API is not configured", status: 401
        return
      end

      unless ActiveSupport::SecurityUtils.secure_compare(key, configured_key)
        render_error "Unauthorized", message: "Invalid API key", status: 401
        return
      end

      @authenticated = true
    end

    def render_success(data, status: 200)
      render json: {
        status: "success",
        time: elapsed_time,
        data: data
      }, status: status
    end

    def render_created(data)
      render_success(data, status: 201)
    end

    def render_deleted
      render json: {
        status: "success",
        time: elapsed_time,
        data: { deleted: true }
      }, status: 200
    end

    def render_error(code, message: nil, errors: nil, status: 400)
      response = {
        status: "error",
        time: elapsed_time,
        error: {
          code: code,
          message: message
        }
      }
      response[:error][:errors] = errors if errors.present?
      render json: response, status: status
    end

    def render_not_found
      render_error "NotFound", message: "Resource not found", status: 404
    end

    def render_validation_error(exception)
      render_error "ValidationError",
                   message: "Validation failed",
                   errors: exception.record.errors.full_messages,
                   status: 422
    end

    def render_parameter_missing(exception)
      render_error "ParameterMissing",
                   message: exception.message,
                   status: 400
    end

    def elapsed_time
      (Time.now.to_f - @start_time).round(3)
    end

    def pagination_params
      {
        page: params[:page]&.to_i || 1,
        per_page: [params[:per_page]&.to_i || 25, 100].min
      }
    end

    def paginate(collection)
      page = pagination_params[:page]
      per_page = pagination_params[:per_page]
      total = collection.count
      items = collection.limit(per_page).offset((page - 1) * per_page)

      {
        items: items,
        pagination: {
          page: page,
          per_page: per_page,
          total: total,
          total_pages: (total.to_f / per_page).ceil
        }
      }
    end

  end
end
