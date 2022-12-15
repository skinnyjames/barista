module Support::Cacher
  def self.fetch_cache(info)
    url = "#{fixture_url}/cache/#{info.filename}"
    tempdir = Dir.tempdir
    dest = File.join(tempdir, info.filename)

    begin
      HTTP::Client.get(url) do |res|
        raise "Could not fetch cache: #{res.status_code}" if res.status_code != 200
        File.write(dest, res.body_io)
      end

      info.unpack(dest)
    rescue ex
      false
    end
  end

  def self.update_cache(task, filepath)
    IO.pipe do |reader, writer|
      channel = Channel(String).new(1)
      spawn do
        HTTP::FormData.build(writer) do |formdata|
          channel.send(formdata.content_type)

          formdata.field("tag", task.tag)
          File.open(filepath) do |file|
            metadata = HTTP::FormData::FileMetadata.new
            headers = HTTP::Headers{ "Content-Type" => "application/tar+gzip" }
            formdata.file("file", file, metadata, headers)
          end
        end

        writer.close
      end

      begin
        headers = HTTP::Headers{"Content-Type" => channel.receive }
        res = HTTP::Client.post("#{fixture_url}/cache", body: reader, headers: headers)
        Barista::Log.info(task.name) { "POST: #{fixture_url}/cache - #{res.status_code}" }
        true
      end
    end
  end
end
