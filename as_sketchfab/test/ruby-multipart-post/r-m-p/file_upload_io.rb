module FileUploadIO
  def self.new(file_path, content_type)
    raise ArgumentError, "File content type required" unless content_type
    file_io = File.open(file_path, "rb")
    file_io.instance_eval(<<-EOS, __FILE__, __LINE__)
      def content_type
        "#{content_type}"
      end

      def file_name
        "#{File.basename(file_path)}"
      end

      def file_size
        "#{File.size(file_path)}".to_i
      end
    EOS
    file_io
  end
end
