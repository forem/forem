class RandomGif
  RANDOM_GIFS = {
    "xjZtu4qi1biIo" => { aspect_ratio: 1.000 },
    "12P29BwtrvsbbW" => { aspect_ratio: 0.760 },
    "9PyhoXey73EpW" => { aspect_ratio: 0.753 },
    "OcZp0maz6ALok" => { aspect_ratio: 1.000 },
    "Is1O1TWV0LEJi" => { aspect_ratio: 0.565 },
    "lz24Z42jLcTa8" => { aspect_ratio: 0.776 },
    "g9582DNuQppxC" => { aspect_ratio: 0.562 },
    "l4HodBpDmoMA5p9bG" => { aspect_ratio: 1.000 },
    "3oxOCfV7z28QtXXAtO" => { aspect_ratio: 0.750 },
    "y8Mz1yj13s3kI" => { aspect_ratio: 0.750 },
    "111ebonMs90YLu" => { aspect_ratio: 0.750 },
    "Sk5uipPXyBjfW" => { aspect_ratio: 0.422 },
    "l0K48FkLfeSCzRA4M" => { aspect_ratio: 0.573 },
    "3o7qDRd1DlF7P2TP3O" => { aspect_ratio: 0.517 },
    "26h0qt6UOumsbJkyI" => { aspect_ratio: 0.442 },
    "l0K4glBiv82lZ0Zuo" => { aspect_ratio: 0.563 },
    "Gf3fU0qPtI6uk" => { aspect_ratio: 0.750 },
    "5GoVLqeAOo6PK" => { aspect_ratio: 0.780 }
  }.freeze

  DEFAULT_RATIO = 1.000

  def self.random_id
    RANDOM_GIFS.keys.sample
  end

  def self.get_aspect_ratio(id)
    RANDOM_GIFS.dig(id, :aspect_ratio) || DEFAULT_RATIO
  end
end
