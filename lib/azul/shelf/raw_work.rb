module Azul
  class Shelf
    class RawWork
      COLUMNS = [:person_id, :person_name, :work_id, :work_title,
        :kana_type, :translator, :typist, :corrector, :status,
        :created_at, :copytext, :publisher, :version_input,
        :version_calibration]
      attr_accessor *COLUMNS
      attr_reader :record
      
      def initialize(record)
        @record = record.split(/[\s"]?,[\s"]?/)
        COLUMNS.each_with_index do |column, i|
          __send__ column.to_s+'=', @record[i]
        end
      end
    end

  end
end
