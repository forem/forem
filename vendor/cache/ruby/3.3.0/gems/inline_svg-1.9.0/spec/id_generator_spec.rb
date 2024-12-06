require_relative '../lib/inline_svg/id_generator'

describe InlineSvg::IdGenerator do
  it "generates a hexencoded ID based on a salt and a random value" do
    randomizer = -> { "some-random-value" }

    expect(InlineSvg::IdGenerator.generate("some-base", "some-salt", randomness: randomizer)).
      to eq("at2c17mkqnvopy36iccxspura7wnreqf")
  end
end
