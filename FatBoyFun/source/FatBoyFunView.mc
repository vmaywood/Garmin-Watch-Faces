using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.ActivityMonitor as Act;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Lang as Lang;

class FatBoyFunView extends Ui.WatchFace {

	var bmp;
	var hrt;

    function initialize() {
        WatchFace.initialize();
    }

    //! Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
        bmp = Ui.loadResource(Rez.Drawables.FatBoy);
        hrt = Ui.loadResource(Rez.Drawables.Heart);
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
        // Get and show the current time
        var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_LONG);
        var clockTime = Sys.getClockTime();
        var stats = Sys.getSystemStats();
        
        var activityInfo = Act.getInfo();
        var stepGoal = activityInfo.stepGoal;
        var steps = activityInfo.steps;
        var moveBarLevel = activityInfo.moveBarLevel;
        var moveBarLevelRange = activityInfo.MOVE_BAR_LEVEL_MAX-activityInfo.MOVE_BAR_LEVEL_MIN;
        
        var hrtIter = Act.getHeartRateHistory(1, true);
        var hrtNext = hrtIter.next;
        var hrtRate = "---";       
        
        var timeStr = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);
        var dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.day, info.month]);
        var batteryStr = Lang.format("$1$%", [stats.battery.toNumber()]);
        var activityStr = Lang.format("$1$/$2$", [steps, stepGoal]);
        var barSteps = stepGoal ? (65*(steps.toDouble()/stepGoal.toDouble())).toNumber() : 0;
        var barActivity = moveBarLevelRange ? (65*(moveBarLevel.toDouble()/moveBarLevelRange.toDouble())).toNumber() : 0;

        
        if (hrtIter != null) {
        		if (hrtIter.getMax() != hrtIter.INVALID_HR_SAMPLE) {
        			hrtRate = hrtIter.getMax();
        		}
        }
    
    	if (barSteps > 65) {
    		barSteps = 65;
    	}
    	if (barActivity > 65) {
    		barActivity = 65;
    	}

        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawText (135, 0, Gfx.FONT_TINY, batteryStr, Gfx.TEXT_JUSTIFY_CENTER);
		dc.drawText (135, 20, Gfx.FONT_TINY, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
		
		dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
        dc.drawText (105, 135, Gfx.FONT_NUMBER_HOT, timeStr, Gfx.TEXT_JUSTIFY_CENTER);
                      
 		dc.drawBitmap(0, 70, bmp); 
 		dc.drawBitmap(20,40, hrt);   
 		
 		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
 		dc.drawText (50, 40, Gfx.FONT_LARGE, hrtRate, Gfx.TEXT_JUSTIFY_CENTER);

 		dc.setPenWidth(1);
 		
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
 		dc.fillRectangle(3, 112, 67, 6);
		dc.fillRectangle(12, 129, 67, 6);
 		
 		dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_GREEN);
 		dc.fillRectangle(4, 113, barSteps, 4);
 		
 		dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_RED);		
 		dc.fillRectangle(13, 130, barActivity, 4);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }

}
