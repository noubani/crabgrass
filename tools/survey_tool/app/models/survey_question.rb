class SurveyQuestion < ActiveRecord::Base
  belongs_to :survey
  serialize :choices, Array
  serialize_default :choices, []

  has_many(:answers, :dependent => :destroy, :class_name => 'SurveyAnswer',
           :foreign_key => 'question_id')
  
  acts_as_list :scope => :survey
  
  def answer!(response, value)
    SurveyAnswer.new(:question => self, :response => response, :value => value).save!
  end
  
  def add_question_link_text
    self.class.to_s
  end

  def newline_delimited_choices=(text)
    self.choices = text.split(/\r?\n/)
  end

  def newline_delimited_choices
    self.choices.join("\n")
  end
end


######### SHORT TEXT ###################
class ShortTextQuestion < SurveyQuestion
  def add_question_link_text
    "Short Answer"[:add_short_text_question_link]
  end
end


######### LONG TEXT ###################
class LongTextQuestion < SurveyQuestion
  def add_question_link_text
    "Long Answer"[:add_long_text_question_link]
  end
end


######### SELECT ONE ###################
class SelectOneQuestion < SurveyQuestion
  def add_question_link_text
    "Select One Answer"[:add_select_one_question_link]
  end
  # def description
  #   :question_description_select_one.t
  # end
  #
  # def partial ; 'surveys/select_one';  end
end


######### SELECT MANY ###################
class SelectManyQuestion < SurveyQuestion
  def add_question_link_text
    "Select Multiple Answers"[:add_select_many_question_link]
  end
  # def description
  #   :question_description_select_many.t
  # end
  # def partial ; 'surveys/select_many';  end
end

######### IMAGE UPLOAD ###################
class ImageUploadQuestion < SurveyQuestion
  def add_question_link_text
    "Upload Image"[:upload_image_question_link]
  end
end

######### VIDEO LINK ###################
class VideoLinkQuestion < SurveyQuestion
  def add_question_link_text
    "Video Link"[:video_link_question_link]
  end
end


######### BOOLEAN ###################
class BooleanQuestion < SurveyQuestion
  # def description
  #   :question_description_boolean.t
  # end

  # def partial ; 'surveys/boolean' ; end
end
