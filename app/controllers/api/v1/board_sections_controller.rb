class Api::V1::BoardSectionsController < Api::ApiController
  before_filter :login_required

  resource_description do
    name 'Subcontinuities'
    description 'Viewing and editing subcontinuities'
  end

  api! 'Update the order of subcontinuities (or, confusingly, posts). This may be moved or renamed and should not be trusted.'
  error 401, "You must be logged in"
  param :changes, Hash do
    param :number, Hash do
      param :id, :number
      param :type, ['Post', 'BoardSection']
      param :order, :number
    end
  end
  def reorder
    valid_types = ['Post', 'BoardSection']

    BoardSection.transaction do
      params[:changes].each do |_, changeset|
        section_id = changeset[:id]
        section_type = changeset[:type]
        section_order = changeset[:order]
        next unless valid_types.include?(section_type)

        section = section_type.constantize.find_by_id(section_id)
        next unless section && section.board.editable_by?(current_user)

        section.update_attributes(section_order: section_order)
      end
    end

    render json: {}
  end
end
