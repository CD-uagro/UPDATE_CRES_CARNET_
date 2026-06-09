import 'package:flutter/material.dart';

const double kMobileMax = 600;
const double kTabletMax = 1024;

bool isMobile(BuildContext c) => MediaQuery.sizeOf(c).width < kMobileMax;
bool isTablet(BuildContext c) =>
    MediaQuery.sizeOf(c).width >= kMobileMax &&
    MediaQuery.sizeOf(c).width < kTabletMax;
bool isDesktop(BuildContext c) => MediaQuery.sizeOf(c).width >= kTabletMax;
