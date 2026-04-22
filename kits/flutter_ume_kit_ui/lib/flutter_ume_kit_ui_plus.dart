library flutter_ume_kit_ui_plus;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ume_plus/flutter_ume_plus.dart';
import 'package:image/image.dart' as img;
import 'package:touch_indicator/touch_indicator.dart' as ti;

import 'src/color_tools/color_utils.dart';
import 'src/color_tools/eyedrop/eye_dropper_layer.dart';
import 'src/color_tools/eyedrop/eyedropper_button.dart'
    if (dart.library.html) 'src/color_tools/eyedrop/eyedropper_button_web.dart';

part 'components/align_ruler/align_ruler.dart';
part 'components/align_ruler/icon.dart';
part 'components/color_picker/color_picker.dart';
part 'components/color_picker/icon.dart';
part 'components/color_sucker/color_sucker.dart';
part 'components/color_sucker/icon.dart';
part 'components/hit_test.dart';
part 'components/touch_indicator/icon.dart';
part 'components/touch_indicator/touch_indicator.dart';
part 'components/widget_detail_inspector/icon.dart';
part 'components/widget_detail_inspector/search_bar.dart';
part 'components/widget_detail_inspector/widget_detail_inspector.dart';
part 'components/widget_info_inspector/icon.dart';
part 'components/widget_info_inspector/widget_info_inspector.dart';
part 'util/binding_ambiguate.dart';
