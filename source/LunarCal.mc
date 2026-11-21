// 农历 / 二十四节气 / 节日计算
// 数据来自 Data.mc（1901-2100，已用 .NET 农历与香港天文台节气时间核对）

import Toybox.Lang;

(:glance)
module LunarCal {

    const KIND_NONE = 0;
    const KIND_REG  = 1;   // 法定节假日
    const KIND_TRAD = 2;   // 传统节日
    const KIND_TERM = 3;   // 二十四节气

    // 1901-02-19 是农历 1901 年正月初一（相对 1970-01-01 的天数）
    const EPOCH_DAY = -25153;

    const MONTH_NAMES = ["正月", "二月", "三月", "四月", "五月", "六月",
                         "七月", "八月", "九月", "十月", "冬月", "腊月"];
    const DAY_NAMES = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
                       "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
                       "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"];
    const STEMS = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"];
    const BRANCHES = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"];
    const ZODIAC = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"];
    const TERM_NAMES = ["小寒", "大寒", "立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
                        "立夏", "小满", "芒种", "夏至", "小暑", "大暑", "立秋", "处暑",
                        "白露", "秋分", "寒露", "霜降", "立冬", "小雪", "大雪", "冬至"];
    const WEEKDAY_NAMES = ["日", "一", "二", "三", "四", "五", "六"];

    const MONTH_LENGTHS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    // ---------- 公历日期计算 ----------

    // 正数情况下等价于向下取整的整数除法
    function idiv(a as Number, b as Number) as Number {
        return (a - (a % b)) / b;
    }

    function isLeapYear(y as Number) as Boolean {
        return ((y % 4 == 0) && (y % 100 != 0)) || (y % 400 == 0);
    }

    function daysInMonth(y as Number, m as Number) as Number {
        if (m == 2 && isLeapYear(y)) {
            return 29;
        }
        return MONTH_LENGTHS[m - 1] as Number;
    }

    // 公历 -> 相对 1970-01-01 的天数
    function ymdToDay(y as Number, m as Number, d as Number) as Number {
        var yy = (m <= 2) ? y - 1 : y;
        var era = idiv(yy, 400);
        var yoe = yy - era * 400;
        var mp = (m > 2) ? m - 3 : m + 9;
        var doy = idiv(153 * mp + 2, 5) + d - 1;
        var doe = yoe * 365 + idiv(yoe, 4) - idiv(yoe, 100) + doy;
        return era * 146097 + doe - 719468;
    }

    // 天数 -> 公历 [年, 月, 日]
    function dayToYmd(day as Number) as Array<Number> {
        var z = day + 719468;
        var era = idiv(z, 146097);
        var doe = z - era * 146097;
        var yoe = idiv(doe - idiv(doe, 1460) + idiv(doe, 36524) - idiv(doe, 146096), 365);
        var y = yoe + era * 400;
        var doy = doe - (365 * yoe + idiv(yoe, 4) - idiv(yoe, 100));
        var mp = idiv(5 * doy + 2, 153);
        var d = doy - idiv(153 * mp + 2, 5) + 1;
        var m = (mp < 10) ? mp + 3 : mp - 9;
        var yy = (m <= 2) ? y + 1 : y;
        return [yy, m, d];
    }

    // 0 = 周日
    function weekdayOf(day as Number) as Number {
        var w = (day + 4) % 7;
        return (w < 0) ? w + 7 : w;
    }

    // ---------- 农历 ----------

    function lunarInfo(y as Number) as Number {
        return LunarCalData.LUNAR_INFO[y - LunarCalData.LUNAR_START_YEAR] as Number;
    }

    function leapMonth(y as Number) as Number {
        return lunarInfo(y) & 0xF;
    }

    function leapDays(y as Number) as Number {
        if (leapMonth(y) == 0) {
            return 0;
        }
        return ((lunarInfo(y) & 0x10000) != 0) ? 30 : 29;
    }

    function lunarMonthDays(y as Number, m as Number) as Number {
        return ((lunarInfo(y) & (0x10000 >> m)) != 0) ? 30 : 29;
    }

    // 找到包含第 off 天（相对农历纪元）的农历年索引
    function lunarYearIndex(off as Number) as Number {
        var lo = 0;
        var hi = (LunarCalData.LUNAR_INFO.size() as Number) - 1;
        while (lo < hi) {
            var mid = idiv(lo + hi + 1, 2);
            if ((LunarCalData.LUNAR_YEAR_START[mid] as Number) <= off) {
                lo = mid;
            } else {
                hi = mid - 1;
            }
        }
        return lo;
    }

    // 返回 [农历年, 月, 日, 是否闰月]，超出 1901-2100 返回 null
    function solarToLunar(day as Number) as Array? {
        var off = day - EPOCH_DAY;
        if (off < 0) {
            return null;
        }
        if (off >= (LunarCalData.LUNAR_YEAR_START[LunarCalData.LUNAR_INFO.size()] as Number)) {
            return null;
        }
        var yi = lunarYearIndex(off);
        var y = LunarCalData.LUNAR_START_YEAR + yi;
        var info = LunarCalData.LUNAR_INFO[yi] as Number;
        var rest = off - (LunarCalData.LUNAR_YEAR_START[yi] as Number);
        var lp = info & 0xF;
        var m = 1;
        var inLeap = false;
        while (m <= 12) {
            var days;
            if (inLeap) {
                days = ((info & 0x10000) != 0) ? 30 : 29;
            } else {
                days = ((info & (0x10000 >> m)) != 0) ? 30 : 29;
            }
            if (rest < days) {
                break;
            }
            rest -= days;
            if (inLeap) {
                inLeap = false;
                m += 1;
            } else if (lp > 0 && m == lp) {
                inLeap = true;
            } else {
                m += 1;
            }
        }
        return [y, m, rest + 1, inLeap];
    }

    function lunarMonthName(m as Number, inLeap as Boolean) as String {
        var name = MONTH_NAMES[m - 1] as String;
        return inLeap ? ("闰" + name) : name;
    }

    function lunarDayName(d as Number) as String {
        return DAY_NAMES[d - 1] as String;
    }

    // 干支纪年，例如 2026 -> 丙午
    function ganzhiYear(ly as Number) as String {
        var idx = (ly - 4) % 60;
        if (idx < 0) {
            idx += 60;
        }
        return (STEMS[idx % 10] as String) + (BRANCHES[idx % 12] as String);
    }

    function zodiacOf(ly as Number) as String {
        var idx = (ly - 4) % 12;
        if (idx < 0) {
            idx += 12;
        }
        return ZODIAC[idx] as String;
    }

    // ---------- 节气 ----------

    function termDay(year as Number, month as Number, idx as Number) as Number {
        var row = LunarCalData.TERM_DAYS[year - LunarCalData.LUNAR_START_YEAR] as String;
        var pos = (month - 1) * 4 + idx * 2;
        return row.substring(pos, pos + 2).toNumber() as Number;
    }

    function termName(year as Number, month as Number, day as Number) as String? {
        if (day == termDay(year, month, 0)) {
            return TERM_NAMES[(month - 1) * 2] as String;
        }
        if (day == termDay(year, month, 1)) {
            return TERM_NAMES[(month - 1) * 2 + 1] as String;
        }
        return null;
    }

    // ---------- 节日 ----------

    // 返回 [完整名称, 网格用短名, 类型]
    function solarFestival(m as Number, d as Number) as Array? {
        if (m == 1 && d == 1) {
            return ["元旦", "元旦", KIND_REG];
        }
        if (m == 5 && d == 1) {
            return ["劳动节", "五一", KIND_REG];
        }
        if (m == 10 && d == 1) {
            return ["国庆节", "十一", KIND_REG];
        }
        return null;
    }

    function lunarFestival(lm as Number, ld as Number, lastDayOfLunarMonth as Number,
                           inLeap as Boolean) as Array? {
        if (inLeap) {
            return null;   // 闰月不重复过节
        }
        switch (lm) {
            case 1:
                if (ld == 1) {
                    return ["春节", "春节", KIND_REG];
                }
                if (ld == 15) {
                    return ["元宵节", "元宵", KIND_TRAD];
                }
                break;
            case 2:
                if (ld == 2) {
                    return ["龙抬头", "龙头", KIND_TRAD];
                }
                break;
            case 5:
                if (ld == 5) {
                    return ["端午节", "端午", KIND_REG];
                }
                break;
            case 7:
                if (ld == 7) {
                    return ["七夕", "七夕", KIND_TRAD];
                }
                if (ld == 15) {
                    return ["中元节", "中元", KIND_TRAD];
                }
                break;
            case 8:
                if (ld == 15) {
                    return ["中秋节", "中秋", KIND_REG];
                }
                break;
            case 9:
                if (ld == 9) {
                    return ["重阳节", "重阳", KIND_TRAD];
                }
                break;
            case 12:
                if (ld == 8) {
                    return ["腊八节", "腊八", KIND_TRAD];
                }
                if (ld == 23) {
                    return ["小年", "小年", KIND_TRAD];
                }
                if (ld == lastDayOfLunarMonth) {
                    return ["除夕", "除夕", KIND_TRAD];
                }
                break;
        }
        return null;
    }

    function termFestival(year as Number, m as Number, d as Number) as Array? {
        var name = termName(year, m, d);
        if (name == null) {
            return null;
        }
        if (name.equals("清明")) {
            return ["清明", "清明", KIND_REG];
        }
        return [name, name, KIND_TERM];
    }

    // 当天的节庆：法定 > 传统 > 节气，返回 [完整名称, 短名, 类型] 或 null
    function eventOf(y as Number, m as Number, d as Number, lunar as Array?) as Array? {
        var sf = solarFestival(m, d);
        if (sf != null) {
            return sf;
        }
        if (lunar != null) {
            var ly = lunar[0] as Number;
            var lm = lunar[1] as Number;
            var ld = lunar[2] as Number;
            var inLeap = lunar[3] as Boolean;
            var lastDay = 30;
            if (lm == 12) {
                lastDay = lunarMonthDays(ly, 12);
            }
            var lf = lunarFestival(lm, ld, lastDay, inLeap);
            if (lf != null) {
                return lf;
            }
        }
        return termFestival(y, m, d);
    }

    function eventOfDay(day as Number) as Array? {
        var ymd = dayToYmd(day);
        var y = ymd[0] as Number;
        var m = ymd[1] as Number;
        var d = ymd[2] as Number;
        return eventOf(y, m, d, solarToLunar(day));
    }

    // 距离 fromDay 最近的一次节气/节日：[完整名称, 短名, 类型, 相差天数]
    // 相差天数 >0 未来，<0 已经过去，0 今天
    function nearestEvent(fromDay as Number) as Array? {
        for (var off = 0; off <= 45; off++) {
            if (off == 0) {
                var e0 = eventOfDay(fromDay);
                if (e0 != null) {
                    return [e0[0], e0[1], e0[2], 0];
                }
                continue;
            }
            var next = eventOfDay(fromDay + off);
            if (next != null) {
                return [next[0], next[1], next[2], off];
            }
            var prev = eventOfDay(fromDay - off);
            if (prev != null) {
                return [prev[0], prev[1], prev[2], -off];
            }
        }
        return null;
    }
}
