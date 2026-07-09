# frozen_string_literal: true

module AdminAPI
  class UsersController < BaseController

    before_action :find_user, only: [:show, :update, :destroy]

    # GET /api/v2/admin/users
    def index
      users = User.where(admin: false).order(:email_address)
      result = paginate(users)

      render_success(
        users: result[:items].map { |u| serialize_user(u) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/users/:id
    def show
      render_success(user: serialize_user(@user, include_details: true))
    end

    # GET /api/v2/admin/users/find/:lookup
    # Find by UUID or email address
    def find
      user = User.find_by(uuid: params[:lookup]) || User.find_by(email_address: params[:lookup])
      raise ActiveRecord::RecordNotFound unless user

      render_success(user: serialize_user(user, include_details: true))
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    # POST /api/v2/admin/users
    def create
      user = User.new(user_params)
      user.password = params[:password].presence || generate_password
      user.save!
      render_created(user: serialize_user(user, include_password: true))
    rescue ActiveRecord::RecordInvalid => e
      render_validation_error(e.record)
    end

    # PATCH /api/v2/admin/users/:id
    def update
      @user.assign_attributes(user_params)
      @user.password = params[:password] if params[:password].present?
      @user.save!
      render_success(user: serialize_user(@user))
    rescue ActiveRecord::RecordInvalid => e
      render_validation_error(e.record)
    end

    # DELETE /api/v2/admin/users/:id
    def destroy
      @user.destroy!
      render_deleted
    end

    private

    def find_user
      @user = User.find_by(uuid: params[:id]) || User.find_by(email_address: params[:id])
      render_not_found unless @user
    end

    def user_params
      params.permit(:email_address, :first_name, :last_name)
    end

    def generate_password
      # Generate a random 16-character password
      SecureRandom.alphanumeric(16)
    end

    def serialize_user(user, include_details: false, include_password: false)
      json = {
        id: user.id,
        uuid: user.uuid,
        email_address: user.email_address,
        first_name: user.first_name,
        last_name: user.last_name,
        name: user.name,
        admin: user.admin,
        created_at: user.created_at&.iso8601,
        updated_at: user.updated_at&.iso8601
      }

      if include_password && user.password_digest.present?
        json[:password_digest] = user.password_digest
      end

      if include_details
        json[:organization_users] = user.organization_users.map do |ou|
          {
            id: ou.id,
            uuid: ou.uuid,
            organization_id: ou.organization_id,
            organization_name: ou.organization.name,
            role: ou.role
          }
        end
      end

      json
    end

  end
end
