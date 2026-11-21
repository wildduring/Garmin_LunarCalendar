import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// 万年历 Widget：主界面 + Glance
class WanNianLiApp extends Application.AppBase {

    public function initialize() {
        AppBase.initialize();
    }

    public function onStart(state as Dictionary?) as Void {
    }

    public function onStop(state as Dictionary?) as Void {
    }

    public function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new CalendarView();
        return [view, new CalendarDelegate(view)];
    }

    public function getGlanceView() as [WatchUi.GlanceView] or
        [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new GlanceView()];
    }
}
