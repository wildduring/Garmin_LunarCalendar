import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// 月历主界面：当月公历 + 农历，上/下键切换月份
class CalendarView extends WatchUi.View {

    const COLOR_BG      = 0x000000;
    const COLOR_FG      = 0xFFFFFF;
    const COLOR_DIM     = 0x8B929C;
    const COLOR_LUNAR   = 0xA8AFB9;
    const COLOR_LUNAR_1 = 0xDFE4EA;
    const COLOR_REG     = 0xFF6A4F;   // 法定节假日
    const COLOR_TRAD    = 0xFFB13B;   // 传统节日
    const COLOR_TERM    = 0x64B5FF;   // 节气
    const COLOR_WEEKEND = 0xE98872;
    const COLOR_HINT    = 0x565C66;
    const COLOR_RULE    = 0x22262C;

    const MIN_YEAR = 1901;
    const MAX_YEAR = 2100;

    private var _year as Number;
    private var _month as Number;
    private var _todayDay as Number;

    private var _fTitle as Graphics.FontType?;
    private var _fSub as Graphics.FontType?;
    private var _fNum as Graphics.FontType?;
    private var _fLunar as Graphics.FontType?;
    private var _fSmall as Graphics.FontType?;

    public function initialize() {
        View.initialize();
        var now = Time.now();
        var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        _year = info.year as Number;
        _month = info.month as Number;
        _todayDay = LunarCal.ymdToDay(_year, _month, info.day as Number);

        // 矢量字体（Noto Sans SC）可按需缩放并跟随 setColor 着色
        if (Graphics has :VectorFont) {
            var face = "NotoSansSCMedium";
            _fTitle = Graphics.getVectorFont({:face => face, :size => 26});
            _fSub = Graphics.getVectorFont({:face => face, :size => 14});
            _fNum = Graphics.getVectorFont({:face => face, :size => 19});
            _fLunar = Graphics.getVectorFont({:face => face, :size => 13});
            _fSmall = Graphics.getVectorFont({:face => face, :size => 12});
        }
        if (_fTitle == null) {
            _fTitle = Graphics.FONT_MEDIUM;
        }
        if (_fSub == null) {
            _fSub = Graphics.FONT_XTINY;
        }
        if (_fNum == null) {
            _fNum = Graphics.FONT_SMALL;
        }
        if (_fLunar == null) {
            _fLunar = Graphics.FONT_XTINY;
        }
        if (_fSmall == null) {
            _fSmall = Graphics.FONT_XTINY;
        }
    }

    public function prevMonth() as Void {
        if (_month == 1) {
            if (_year <= MIN_YEAR) {
                return;
            }
            _year -= 1;
            _month = 12;
        } else {
            _month -= 1;
        }
        WatchUi.requestUpdate();
    }

    public function nextMonth() as Void {
        if (_month == 12) {
            if (_year >= MAX_YEAR) {
                return;
            }
            _year += 1;
            _month = 1;
        } else {
            _month += 1;
        }
        WatchUi.requestUpdate();
    }

    private function drawCenter(dc as Graphics.Dc, x as Number, y as Number,
                                font as Graphics.FontType, text as String, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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

    public function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        // ---- 标题 ----
        drawCenter(dc, w / 2, h * 78 / 1000, _fTitle as Graphics.FontType,
                   _year.toString() + "年" + _month.toString() + "月", COLOR_FG);

        var midDay = LunarCal.ymdToDay(_year, _month, 15);
        var mLunar = LunarCal.solarToLunar(midDay);
        if (mLunar != null) {
            var ly = mLunar[0] as Number;
            var lm = mLunar[1] as Number;
            var inLeap = mLunar[3] as Boolean;
            var sub = LunarCal.ganzhiYear(ly) + "年 " + LunarCal.zodiacOf(ly) + " · " +
                      LunarCal.lunarMonthName(lm, inLeap);
            drawCenter(dc, w / 2, h * 155 / 1000, _fSub as Graphics.FontType, sub, COLOR_DIM);
        }

        // ---- 星期栏 + 网格 ----
        var gridW = w * 84 / 100;
        var cellW = gridW / 7;
        var x0 = (w - gridW) / 2;
        var gridTop = h * 220 / 1000;
        var gridBottom = h * 800 / 1000;

        var firstWeekday = LunarCal.weekdayOf(LunarCal.ymdToDay(_year, _month, 1));
        var nDays = LunarCal.daysInMonth(_year, _month);
        var rows = LunarCal.idiv(firstWeekday + nDays - 1, 7) + 1;
        var cellH = (gridBottom - gridTop) / rows;

        for (var c = 0; c < 7; c++) {
            var cxHeader = x0 + cellW * c + cellW / 2;
            var hColor = (c == 0 || c == 6) ? COLOR_WEEKEND : COLOR_DIM;
            drawCenter(dc, cxHeader, h * 198 / 1000, _fSub as Graphics.FontType,
                       LunarCal.WEEKDAY_NAMES[c] as String, hColor);
        }

        for (var i = 0; i < rows * 7; i++) {
            var dayNum = i - firstWeekday + 1;
            if (dayNum < 1 || dayNum > nDays) {
                continue;
            }
            var col = i % 7;
            var row = LunarCal.idiv(i, 7);
            var cx = x0 + cellW * col + cellW / 2;
            var rowTop = gridTop + cellH * row;
            var numY = rowTop + cellH * 32 / 100;
            var lunarY = rowTop + cellH * 76 / 100;

            var dayVal = LunarCal.ymdToDay(_year, _month, dayNum);
            var lunar = LunarCal.solarToLunar(dayVal);
            var event = LunarCal.eventOf(_year, _month, dayNum, lunar);

            // 农历文字：节日 > 初一（月名）> 日名
            var lunarText = "";
            var lunarColor = COLOR_LUNAR;
            if (event != null) {
                lunarText = event[1] as String;
                lunarColor = colorOfKind(event[2] as Number);
            } else if (lunar != null) {
                var lm = lunar[1] as Number;
                var ld = lunar[2] as Number;
                var inLeap = lunar[3] as Boolean;
                if (ld == 1) {
                    lunarText = LunarCal.lunarMonthName(lm, inLeap);
                    lunarColor = COLOR_LUNAR_1;
                } else {
                    lunarText = LunarCal.lunarDayName(ld);
                    lunarColor = COLOR_LUNAR;
                }
            }

            var isToday = (dayVal == _todayDay);
            var numColor = (col == 0 || col == 6) ? COLOR_WEEKEND : COLOR_FG;
            if (isToday) {
                dc.setColor(COLOR_FG, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(cx, numY, cellH * 24 / 100);
                numColor = COLOR_BG;
            }
            drawCenter(dc, cx, numY, _fNum as Graphics.FontType, dayNum.toString(), numColor);
            drawCenter(dc, cx, lunarY, _fLunar as Graphics.FontType, lunarText, lunarColor);
        }

        // ---- 图例 + 提示 ----
        var legendY = h * 862 / 1000;
        drawCenter(dc, w * 22 / 100, legendY, _fSmall as Graphics.FontType, "法定", COLOR_REG);
        drawCenter(dc, w * 43 / 100, legendY, _fSmall as Graphics.FontType, "传统", COLOR_TRAD);
        drawCenter(dc, w * 64 / 100, legendY, _fSmall as Graphics.FontType, "节气", COLOR_TERM);
        drawCenter(dc, w * 83 / 100, legendY, _fSmall as Graphics.FontType, "今日", COLOR_LUNAR_1);

        drawCenter(dc, w / 2, h * 925 / 1000, _fSmall as Graphics.FontType,
                   "上下键切换月份", COLOR_HINT);
    }
}

class CalendarDelegate extends WatchUi.InputDelegate {

    private var _view as CalendarView;

    public function initialize(view as CalendarView) {
        InputDelegate.initialize();
        _view = view;
    }

    public function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == WatchUi.KEY_UP) {
            _view.prevMonth();
            return true;
        }
        if (key == WatchUi.KEY_DOWN) {
            _view.nextMonth();
            return true;
        }
        return false;
    }
}
