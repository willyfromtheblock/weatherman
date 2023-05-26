enum PricePeriod { peak, offPeak, superOffPeak }

// get String for price period
String getPricePeriodName(PricePeriod period) {
  return period.toString().split('.').last;
}

PricePeriod getPricePeriod(int hour) {
  return pricePeriods[hour]!;
}

final Map<int, PricePeriod> pricePeriods = {
  //0-7 super off peak
  0: PricePeriod.superOffPeak,
  1: PricePeriod.superOffPeak,
  2: PricePeriod.superOffPeak,
  3: PricePeriod.superOffPeak,
  4: PricePeriod.superOffPeak,
  5: PricePeriod.superOffPeak,
  6: PricePeriod.superOffPeak,
  7: PricePeriod.superOffPeak,
  //8-9 off peak
  8: PricePeriod.offPeak,
  9: PricePeriod.offPeak,
  //10-13 peak
  10: PricePeriod.peak,
  11: PricePeriod.peak,
  12: PricePeriod.peak,
  13: PricePeriod.peak,
  //14-17 off peak
  14: PricePeriod.offPeak,
  15: PricePeriod.offPeak,
  16: PricePeriod.offPeak,
  17: PricePeriod.offPeak,
  //18-21 peak
  18: PricePeriod.peak,
  19: PricePeriod.peak,
  20: PricePeriod.peak,
  21: PricePeriod.peak,
  //22-23 off peak
  22: PricePeriod.offPeak,
  23: PricePeriod.offPeak,
};
