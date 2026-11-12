enum ScannerFilterType {
  original('Original', 'Original'),
  auto('Auto', 'Auto'),
  shadow('Shadow Reduction', 'Shadow Reduction'),
  enhanced('Enhanced', 'Enhanced'),
  grayscale('Grayscale', 'Grayscale');

  final String labelEn;
  final String labelBn;
  const ScannerFilterType(this.labelEn, this.labelBn);
}
