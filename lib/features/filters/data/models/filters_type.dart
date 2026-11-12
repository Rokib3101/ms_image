enum FiltersType {
  original('Original', 'অরিজিনাল'),
  magicColor('Magic Color', 'ম্যাজিক কালার'),
  magicSharp('Magic Sharp', 'ম্যাজিক শার্প'),
  auto('Auto', 'অটো'),
  shadow('Remove Shadow', 'শ্যাডো রিমুভ'),
  bw('B&W', 'ব্ল্যাক & হোয়াইট'),
  bwCrisp('B&W Crisp', 'বিঅ্যান্ডডব্লিউ ক্রিস্প'),
  grayscale('Grayscale', 'গ্রে-স্কেল'),
  lighten('Lighten', 'লাইটেন');

  final String labelEn;
  final String labelBn;
  const FiltersType(this.labelEn, this.labelBn);
}

class FiltersFineTuneSettings {
  final double brightness; // -100.0 to 100.0 (default 0.0)
  final double contrast; // -100.0 to 100.0 (default 0.0)
  final double saturation; // -100.0 to 100.0 (default 0.0)
  final double sharpness; // 0.0 to 100.0 (default 0.0)

  const FiltersFineTuneSettings({
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.sharpness = 0.0,
  });

  bool get isDefault =>
      brightness == 0.0 &&
      contrast == 0.0 &&
      saturation == 0.0 &&
      sharpness == 0.0;

  FiltersFineTuneSettings copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? sharpness,
  }) {
    return FiltersFineTuneSettings(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      sharpness: sharpness ?? this.sharpness,
    );
  }
}
