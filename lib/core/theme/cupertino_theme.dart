import 'package:flutter/cupertino.dart';
import 'app_theme.dart';

class TorrentFlowCupertinoTheme {
  static CupertinoThemeData darkTheme() {
    return CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: TorrentFlowTheme.accent,
      primaryContrastingColor: TorrentFlowTheme.darkText,
      scaffoldBackgroundColor: TorrentFlowTheme.darkBackground,
      barBackgroundColor: TorrentFlowTheme.darkSurface.withValues(alpha: 0.85),
      textTheme: CupertinoTextThemeData(
        primaryColor: TorrentFlowTheme.darkText,
        textStyle: TorrentFlowTheme.body.copyWith(color: TorrentFlowTheme.darkText),
        navTitleTextStyle: TorrentFlowTheme.headline.copyWith(color: TorrentFlowTheme.darkText),
        navLargeTitleTextStyle: TorrentFlowTheme.largeTitle.copyWith(color: TorrentFlowTheme.darkText),
        actionTextStyle: TorrentFlowTheme.body.copyWith(color: TorrentFlowTheme.accent),
        tabLabelTextStyle: TorrentFlowTheme.caption1.copyWith(color: TorrentFlowTheme.darkTextSecondary),
        dateTimePickerTextStyle: TorrentFlowTheme.body.copyWith(color: TorrentFlowTheme.darkText),
        pickerTextStyle: TorrentFlowTheme.headline.copyWith(color: TorrentFlowTheme.darkText),
      ),
    );
  }

  static CupertinoThemeData lightTheme() {
    return CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: TorrentFlowTheme.accent,
      primaryContrastingColor: TorrentFlowTheme.lightText,
      scaffoldBackgroundColor: TorrentFlowTheme.lightBackground,
      barBackgroundColor: TorrentFlowTheme.lightSurface.withValues(alpha: 0.85),
      textTheme: CupertinoTextThemeData(
        primaryColor: TorrentFlowTheme.lightText,
        textStyle: TorrentFlowTheme.body.copyWith(color: TorrentFlowTheme.lightText),
        navTitleTextStyle: TorrentFlowTheme.headline.copyWith(color: TorrentFlowTheme.lightText),
        navLargeTitleTextStyle: TorrentFlowTheme.largeTitle.copyWith(color: TorrentFlowTheme.lightText),
        actionTextStyle: TorrentFlowTheme.body.copyWith(color: TorrentFlowTheme.accent),
        tabLabelTextStyle: TorrentFlowTheme.caption1.copyWith(color: TorrentFlowTheme.lightTextSecondary),
        dateTimePickerTextStyle: TorrentFlowTheme.body.copyWith(color: TorrentFlowTheme.lightText),
        pickerTextStyle: TorrentFlowTheme.headline.copyWith(color: TorrentFlowTheme.lightText),
      ),
    );
  }
}
