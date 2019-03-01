class RandomGif
  def initialize(_action = "congratulations")
    @random_gifs = {
      "xjZtu4qi1biIo" => { aspect_ratio: 1.000 },
      "12P29BwtrvsbbW" => { aspect_ratio: 0.760 },
      "9PyhoXey73EpW" => { aspect_ratio: 0.753 },
      "OcZp0maz6ALok" => { aspect_ratio: 1.000 },
      "Is1O1TWV0LEJi" => { aspect_ratio: 0.565 },
      "xjZtu4qi1biIo" => { aspect_ratio: 1.0000 },
      "lz24Z42jLcTa8" => { aspect_ratio: 0.776 },
      "g9582DNuQppxC" => { aspect_ratio: 0.562 },
      "l4HodBpDmoMA5p9bG" => { aspect_ratio: 1.000 },
      "3oxOCfV7z28QtXXAtO" => { aspect_ratio: 0.750 },
      "y8Mz1yj13s3kI" => { aspect_ratio: 0.750 },
      "111ebonMs90YLu" => { aspect_ratio: 0.750 },
      "Sk5uipPXyBjfW" => { aspect_ratio: 0.422 }
    }
  end

  def random_id
    @random_gifs.keys.sample
  end

  def get_aspect_ratio(id)
    (@random_gifs[id] || "xjZtu4qi1biIo")[:aspect_ratio]
  end
end
