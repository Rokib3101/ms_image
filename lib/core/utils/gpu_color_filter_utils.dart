import 'package:flutter/material.dart';
import '../../features/filters/data/models/filters_type.dart';

class GpuColorFilterUtils {
  /// Returns a GPU-accelerated ColorFilter for live preview without CPU decoding lag.
  static ColorFilter getFilter(FiltersType type) {
    switch (type) {
      case FiltersType.original:
        return const ColorFilter.matrix(<double>[
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case FiltersType.grayscale:
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]);
      case FiltersType.bw:
      case FiltersType.bwCrisp:
        return const ColorFilter.matrix(<double>[
          0.33, 0.59, 0.11, 0, -30,
          0.33, 0.59, 0.11, 0, -30,
          0.33, 0.59, 0.11, 0, -30,
          0,    0,    0,    1,   0,
        ]);
      case FiltersType.lighten:
        return const ColorFilter.matrix(<double>[
          1.15, 0,    0,    0, 20,
          0,    1.15, 0,    0, 20,
          0,    0,    1.15, 0, 20,
          0,    0,    0,    1,  0,
        ]);
      case FiltersType.magicColor:
      case FiltersType.magicSharp:
      case FiltersType.auto:
        return const ColorFilter.matrix(<double>[
          1.1,  0.05, 0,    0, 10,
          0.05, 1.1,  0.0,  0, 10,
          0,    0.05, 1.15, 0, 10,
          0,    0,    0,    1,  0,
        ]);
      case FiltersType.shadow:
        return const ColorFilter.matrix(<double>[
          1.2, 0,   0,   0, 35,
          0,   1.2, 0,   0, 35,
          0,   0,   1.2, 0, 35,
          0,   0,   0,   1,  0,
        ]);
    }
  }
}
