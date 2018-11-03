import 'dart:math';

import 'package:intl/intl.dart';
import 'package:nightscout_reporter/src/globals.dart';
import 'package:nightscout_reporter/src/jsonData.dart';

import 'base-print.dart';

class PrintDailyStatistics extends BasePrint
{
  @override
  String id = "daystats";

  bool showHbA1c, showStdabw, showCount, showPercentile;

  @override
  FormConfig config = FormConfig("daystats", false, [
    ParamInfo("Spalte Messwerte", boolValue: true),
    ParamInfo("Spalte Standardabweichung", boolValue: true),
    ParamInfo("Spalte Perzentile", boolValue: true),
    ParamInfo("Spalte HbA1c", boolValue: true),
  ]);

  @override
  prepareData_(ReportData data)
  {
    showCount = config.params[0].boolValue;
    showStdabw = config.params[1].boolValue;
    showPercentile = config.params[2].boolValue;
    showHbA1c = config.params[3].boolValue;
    return data;
  }

  @override
  String name = Intl.message("Tagesstatistik");

  @override
  String title = Intl.message("Tagesstatistik");

  @override
  bool get isPortrait
  => false;

  PrintDailyStatistics()
  {
    init();
  }

  msgLow(value)
  {
    value = "\n<${glucFromData(value)}";
    return Intl.message("Tief${value}", args: [value], name: "msgLow");
  }

  get msgNormal
  => "${Intl.message("Normal")}\n${getGlucInfo()["unit"]}";

  msgHigh(value)
  {
    value = "\n>=${glucFromData(value)}";
    return Intl.message("Hoch${value}", args: [value], name: "msgHigh");
  }

  String colHbA1c = "#505050";

  get msgDate
  => Intl.message("Datum");
  get msgDistribution
  => Intl.message("Verteilung");
  get msgValues
  => Intl.message("Mess-\nwerte");
  get msgMin
  => Intl.message("Min");
  get msgMax
  => Intl.message("Max");
  get msgAverage
  => Intl.message("Mittel-\nwert");
  get msgDeviation
  => Intl.message("Std.\nAbw.");
  get msg25
  => Intl.message("25%");
  get msg75
  => Intl.message("75%");
  String msgDaySum(int value)
  => Intl.message("$value Tage", args: [value], name: "msgDaySum");
  String get msgHbA1c
  => Intl.message("gesch.\nHbA1c");

  headLine(SettingsData settings)
  {
    var ret = [];
    ret.add({"text": msgDate, "style": "total", "alignment": "center"});
    ret.add({"text": msgDistribution, "style": "total", "alignment": "center"});
    ret.add({
      "text": msgLow(settings.thresholds.bgTargetBottom),
      "style": "total",
      "alignment": "center",
      "fillColor": colLow
    });
    ret.add({"text": msgNormal, "style": "total", "alignment": "center", "fillColor": colNorm});
    ret.add({
      "text": msgHigh(settings.thresholds.bgTargetTop),
      "style": "total",
      "alignment": "center",
      "fillColor": colHigh
    });
    if (showCount)ret.add({"text": msgValues, "style": "total", "alignment": "center"});
    ret.add({"text": msgMin, "style": "total", "alignment": "center"});
    ret.add({"text": msgMax, "style": "total", "alignment": "center"});
    ret.add({"text": msgAverage, "style": "total", "alignment": "center"});
    if (showStdabw)ret.add({"text": msgDeviation, "style": "total", "alignment": "center"});
    if (showPercentile)
    {
      ret.add({"text": msg25, "style": "total", "alignment": "center"});
      ret.add({"text": msgMedian, "style": "total", "alignment": "center"});
      ret.add({"text": msg75, "style": "total", "alignment": "center"});
    }
    if (showHbA1c)ret.add({"text": msgHbA1c, "style": "total", "alignment": "center", "color": colHbA1c});

    return ret;
  }

  @override
  getFormData_(ReportData src)
  {
    titleInfo = titleInfoBegEnd(src);

    double f = 3.3;
    var body = [];
    var widths = ["auto", cm(f), "*", "*", "*"];
    if (showCount)widths.add("auto");
    widths.add("auto");
    widths.add("auto");
    widths.add("auto");
    if (showStdabw)widths.add("auto");
    if (showPercentile)
    {
      widths.add(cm(1.5));
      widths.add(cm(1.5));
      widths.add(cm(1.5));
    }
    if (showHbA1c)widths.add(cm(1.5));

    f /= 100;

    ProfileGlucData prevProfile = null;int lineCount = 0;var ret = [header];int totalCount = 0;double totalMin =
      100000;double totalMax = 0;int totalLow = 0;int totalHigh = 0;int totalNorm =
      0;double totalStdAbw = 0.0;double total25 = 0.0;double total50 = 0.0;double total75 =
      0.0;for (DayData day in src.ns.days)
    {
      day.init();
      ProfileGlucData profile = src.profile(DateTime(day.date.year, day.date.month, day.date.day));
      if (prevProfile == null || profile.targetLow != prevProfile.targetLow || profile.targetHigh != prevProfile
        .targetHigh)
      {
        body.add(headLine(src.status.settings));
        lineCount += 2;
      }
      prevProfile = profile;

      var row = [];
      row.add({"text": fmtDate(day.date)});
      row.add({
        "canvas": [
          {"type": "rect", "color": colLow, "x": cm(0), "y": cm(0), "w": cm(day.lowPrz * f), "h": cm(0.5)},
          {
            "type": "rect",
            "color": colNorm,
            "x": cm(day.lowPrz * f),
            "y": cm(0),
            "w": cm(day.normPrz * f),
            "h": cm(0.5)
          },
          {
            "type": "rect",
            "color": colHigh,
            "x": cm((day.lowPrz + day.normPrz) * f),
            "y": cm(0),
            "w": cm(day.highPrz * f),
            "h": cm(0.5)
          }
        ]
      });
      row.add({"text": "${fmtNumber(day.lowPrz, 0)} %", "alignment": "right"});
      row.add({"text": "${fmtNumber(day.normPrz, 0)} %", "alignment": "right"});
      row.add({"text": "${fmtNumber(day.highPrz, 0)} %", "alignment": "right"});
      if (showCount)row.add({"text": "${fmtNumber(day.entryCount, 0)}", "alignment": "right"});
      row.add({"text": "${glucFromData(day.min)}", "alignment": "right"});
      row.add({"text": "${glucFromData(day.max)}", "alignment": "right"});
      row.add({"text": "${glucFromData(day.mid, 1)}", "alignment": "right"});
      if (showStdabw)row.add({"text": "${glucFromData(day.stdAbw, 1)}", "alignment": "right"});
      if (showPercentile)
      {
        row.add({"text": "${glucFromData(Globals.percentile(day.entries, 25), 1)}", "alignment": "right"});
        row.add({"text": "${glucFromData(Globals.percentile(day.entries, 50), 1)}", "alignment": "right"});
        row.add({"text": "${glucFromData(Globals.percentile(day.entries, 75), 1)}", "alignment": "right"});
      }
      if (showHbA1c)row.add({"text": "${hba1c(day.mid)} %", "alignment": "right", "color": colHbA1c});
      body.add(row);
      totalStdAbw += day.stdAbw;
      total25 += Globals.percentile(day.entries, 25);
      total50 += Globals.percentile(day.entries, 50);
      total75 += Globals.percentile(day.entries, 75);
      totalCount += day.entryCount;
      totalMin = min(day.min, totalMin);
      totalMax = max(day.max, totalMax);
      totalLow += day.lowCount;
      totalHigh += day.highCount;
      totalNorm += day.normCount;
      lineCount ++;
      if (lineCount == 21 && day != src.ns.days.last)
      {
        ret.add({"margin": [cm(2.2), cm(2.5), cm(2.2), cm(0.0)], "table": {"widths": widths, "body": body}});
        lineCount = 0;
        if (day != src.ns.days.last)
        {
          ret.add(footer(addPageBreak: true));
          ret.add(header);
        }
        else
        {
          ret.add(footer());
        }
        body = [];
        prevProfile = null;
      }
    }

    double lowPrz = totalCount == 0 ? 0 : totalLow / totalCount * 100;
    double normPrz = totalCount == 0 ? 0 : totalNorm / totalCount * 100;
    double highPrz = totalCount == 0 ? 0 : totalHigh / totalCount * 100;
    var row = [];
    row.add({"text": msgDaySum(src.ns.days.length), "style": "total", "alignment": "center"});
    row.add({
      "canvas": [
        {"type": "rect", "color": colLow, "x": cm(0), "y": cm(0), "w": cm(lowPrz * f), "h": cm(0.5)},
        {"type": "rect", "color": colNorm, "x": cm(lowPrz * f), "y": cm(0), "w": cm(normPrz * f), "h": cm(0.5)},
        {
          "type": "rect",
          "color": colHigh,
          "x": cm((lowPrz + normPrz) * f),
          "y": cm(0),
          "w": cm(highPrz * f),
          "h": cm(0.5)
        }
      ],
      "style": "total"
    });
    row.add({"text": "${fmtNumber(lowPrz, 0)} %", "alignment": "right", "style": "total", "fillColor": colLow});
    row.add({"text": "${fmtNumber(normPrz, 0)} %", "alignment": "right", "style": "total", "fillColor": colNorm});
    row.add({"text": "${fmtNumber(highPrz, 0)} %", "alignment": "right", "style": "total", "fillColor": colHigh});
    if (showCount)row.add({"text": "${fmtNumber(totalCount, 0)}", "alignment": "right", "style": "total"});
    row.add({"text": "${glucFromData(totalMin)}", "alignment": "right", "style": "total"});
    row.add({"text": "${glucFromData(totalMax)}", "alignment": "right", "style": "total"});
    row.add({"text": "${fmtNumber(src.ns.avgGluc / src.ns.days.length, 1)}", "alignment": "right", "style": "total"});
    if (showStdabw)row.add(
      {"text": "${fmtNumber(totalStdAbw / src.ns.days.length, 1)}", "alignment": "right", "style": "total"});
    if (showPercentile)
    {
      row.add({"text": "${fmtNumber(total25 / src.ns.days.length, 1)}", "alignment": "right", "style": "total"});
      row.add({"text": "${fmtNumber(total50 / src.ns.days.length, 1)}", "alignment": "right", "style": "total"});
      row.add({"text": "${fmtNumber(total75 / src.ns.days.length, 1)}", "alignment": "right", "style": "total"});
    }
    if (showHbA1c)row.add(
      {"text": "${hba1c(src.ns.avgGluc)} %", "alignment": "right", "style": "total", "color": colHbA1c});
    body.add(row);

    if (prevProfile != null)
    {
      ret.add({"margin": [cm(2.2), cm(2.5), cm(2.2), cm(0.0)], "table": {"widths": widths, "body": body}});
      ret.add(footer());
    }

    return ret;
  }
}