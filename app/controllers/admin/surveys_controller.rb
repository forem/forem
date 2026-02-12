module Admin
  class SurveysController < Admin::ApplicationController
    layout "admin"

    def index
      @surveys = Survey.order(created_at: :desc).page(params[:page]).per(25)
    end

    def show
      @survey = Survey.find(params[:id])
    end

    def new
      @survey = Survey.new
      @survey.polls.build
    end

    def edit
      @survey = Survey.find(params[:id])
    end

    def create
      @survey = Survey.new(survey_params)

      if @survey.save
        flash[:success] = I18n.t("admin.surveys_controller.created")
        redirect_to admin_surveys_path
      else
        flash.now[:danger] = @survey.errors_as_sentence
        render :new
      end
    end

    def update
      @survey = Survey.find(params[:id])

      if @survey.update(survey_params)
        flash[:success] = I18n.t("admin.surveys_controller.updated")
        redirect_to admin_surveys_path
      else
        flash.now[:danger] = @survey.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @survey = Survey.find(params[:id])

      if @survey.destroy
        flash[:success] = I18n.t("admin.surveys_controller.deleted")
      else
        flash[:danger] = @survey.errors_as_sentence
      end
      redirect_to admin_surveys_path
    end

    private

    def survey_params
      params.require(:survey).permit(
        :title, :active, :display_title, :allow_resubmission,
        polls_attributes: [
          :id, :prompt_markdown, :type_of, :position, :scale_min, :scale_max, :_destroy,
          poll_options_attributes: %i[id markdown supplementary_text position _destroy]
        ]
      )
    end
  end
end
