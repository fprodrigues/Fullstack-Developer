class UserImportJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError
  discard_on ActiveRecord::RecordNotFound

  def perform(user_import_id)
    user_import = UserImport.find(user_import_id)
    UserImports::Processor.call(user_import)
  end
end
