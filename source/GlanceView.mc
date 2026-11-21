import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// 抬腕 Glance：今日公历 / 农历 + 最近一个节气或节日
(:glance)
class GlanceView extends WatchUi.GlanceView {

    const COLOR_BG      = 0x000000;
    const COLOR_FG      = 0xFFFFFF;
    const COLOR_DIM     = 0x8B929C;
    const COLOR_LUNAR   = 0xB9C0CA;
    const COLOR_REG     = 0xFF6A4F;
    const COLOR_TRAD    = 0xFFB13B;
    const COLOR_TERM    = 0x64B5FF;

    public function initialize() {
        GlanceView.initialize();
    }

    private function colorOfKind(kind as Number) as Number {
        switch (kind) {
            case LunarCal.KIND_REG:
                return COLOR_REG;
            case LunarCal.KIND_TRAD:
                return COLOR_TRAD;
            case LunarCal.KIND_TERM:
                return COLOR_TERM;
        }
        return COLOR_DIM;
    }

    private function drawCenter(dc as Graphics.Dc, x as Number, y as Number,
                                font as Graphics.FontType, text as String, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var y = info.year as Number;
        var m = info.month as Number;
        var d = info.day as Number;
        var todayDay = LunarCal.ymdToDay(y, m, d);
        var dow = LunarCal.weekdayOf(todayDay);

        var dateText = m.toString() + "月" + d.toString() + "日 周" +
                       (LunarCal.WEEKDAY_NAMES[dow] as String);
        drawCenter(dc, w / 2, h * 26 / 100, Graphics.FONT_SMALL, dateText, COLOR_FG);

        var lunar = LunarCal.solarToLunar(todayDay);
        if (lunar != null) {
            var ly = lunar[0] as Number;
            var lm = lunar[1] as Number;
            var ld = lunar[2] as Number;
            var inLeap = lunar[3] as Boolean;
            var lunarText = LunarCal.ganzhiYear(ly) + "年 " +
                            LunarCal.lunarMonthName(lm, inLeap) +
                            LunarCal.lunarDayName(ld);
            drawCenter(dc, w / 2, h * 54 / 100, Graphics.FONT_XTINY, lunarText, COLOR_LUNAR);
        }

        var ev = LunarCal.nearestEvent(todayDay);
        if (ev != null) {
            var name = ev[0] as String;
            var kind = ev[2] as Number;
            var diff = ev[3] as Number;
            var text;
            if (diff == 0) {
                text = "今日 " + name;
            } else if (diff > 0) {
                text = "距" + name + " " + diff.toString() + "天";
            } else {
                text = "已过" + name + " " + (-diff).toString() + "天";
            }
            drawCenter(dc, w / 2, h * 80 / 100, Graphics.FONT_XTINY, text, colorOfKind(kind));
        }
    }
}
