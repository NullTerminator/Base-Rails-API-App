class ApplicationController < ActionController::API

  before_action :set_resource, only: [:show, :update, :destroy]

  def index
    response = interactor_scope::List.call(**filtered_params)
    if response.success?
      json_response response.public_send(resource_name.pluralize)
    else
      json_response({ message: response.message }, :not_found)
    end
  end

  def create
    response = interactor_scope::Create.call(resource_params)
    if response.success?
      json_response response.public_send(resource_name), :created
    else
      json_response({ message: response.message }, :unprocessable_entity)
    end
  end

  def show
    json_response get_resource
  end

  def update
    resource = get_resource
    response = interactor_scope::Update.call(resource_params.merge(resource_name => resource))
    if response.success?
      json_response resource, :ok
    else
      json_response({ message: response.message }, :unprocessable_entity)
    end
  end

  def destroy
    response = interactor_scope::Delete.call(resource_name => get_resource)
    if response.success?
      head :no_content
    else
      json_response({ message: response.message }, :unprocessable_entity)
    end
  end

  private

  def json_response(object, status = :ok)
    #render json: object, status: status
    #render json: Array(object), status: status, root: resource_name.pluralize
    render json: object, status: status, adapter: :json_api
  end

  def set_resource
    response = interactor_scope::Find.call(id: params[:id])
    if response.success?
      instance_variable_set("@#{resource_name}", response.public_send(resource_name))
    else
      json_response({ message: response.message }, :not_found)
      false
    end
  end

  def get_resource
    instance_variable_get("@#{resource_name}")
  end

  def resource_name
    @resource_name ||= self.controller_name.singularize
  end

  def resource_class
    @resource_class ||= resource_name.classify.constantize
  end

  def interactor_scope
    @interactor_scope ||= resource_name.classify.pluralize.constantize
  end

  def resource_params
    self.public_send("#{resource_name}_params")
  end

  def filter_params
    []
  end

  def filtered_params
    params.slice(*filter_params).to_unsafe_hash
  end
end
