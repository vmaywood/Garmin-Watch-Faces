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
        
        var hrtIter = (Act has :getHeartRateHistory) ? Act.getHeartRateHistory(1, true) : null;      
        var activityInfo = Act.getInfo();
        var stepGoal = 10000;//activityInfo.stepGoal;
        var steps = 6000;//activityInfo.steps;
        var moveBarLevel = activityInfo.moveBarLevel;
        var moveBarLevelRange = activityInfo.MOVE_BAR_LEVEL_MAX-activityInfo.MOVE_BAR_LEVEL_MIN;
        var barLen = 65;	// Pixel width of steps and move bars
        var barSteps = stepGoal ? (barLen*(steps.toDouble()/stepGoal.toDouble())).toNumber() : 0;
        var barActivity = moveBarLevelRange ? (barLen*(moveBarLevel.toDouble()/moveBarLevelRange.toDouble())).toNumber() : 0;
               
        var timeStr = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);
        var dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.day, info.month]);
        var batteryStr = Lang.format("$1$%", [stats.battery.toNumber()]);
        var activityStr = Lang.format("$1$/$2$", [steps, stepGoal]);
        var halfWidth = dc.getWidth()/2;
        var halfHeight = dc.getHeight()/2;
        var offsetHeight = null;
        var timeFont = null;
          
        if (halfHeight <= 74) {
        	timeFont = Gfx.FONT_MEDIUM;
        	offsetHeight = 50;
        }
        else if (halfHeight <= 90) {
        	timeFont = Gfx.FONT_NUMBER_MEDIUM ;
        	offsetHeight = 70;
        }
        else {
        	timeFont = Gfx.FONT_NUMBER_HOT;
        	offsetHeight =70;
        }
        
    	if (barSteps > barLen) {		// Limit bar to 100%
    		barSteps = barLen;
    	}
    	if (barActivity > barLen) {		// Limit bar to 100%
    		barActivity = barLen;
    	}
        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
        
        dc.drawBitmap(0, offsetHeight, bmp); 
 		dc.drawBitmap(80, 5, hrt);  
 		
 		// Get most recent heart rate from history
        if (hrtIter != null) {
        	var hrtRate = "---";		// Default display if no heart rate available
        	if (hrtIter.getMax() != hrtIter.INVALID_HR_SAMPLE) {
        		hrtRate = hrtIter.getMax();
        	}       	 		
 			dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
 			dc.drawText (110, 10, Gfx.FONT_LARGE, hrtRate, Gfx.TEXT_JUSTIFY_CENTER);		
        }
        
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawText (50, offsetHeight-20, Gfx.FONT_TINY, batteryStr, Gfx.TEXT_JUSTIFY_CENTER);
		dc.drawText (50, offsetHeight, Gfx.FONT_TINY, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
		
		dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
        dc.drawText (halfWidth, offsetHeight+65, timeFont, timeStr, Gfx.TEXT_JUSTIFY_CENTER);                    

 		dc.setPenWidth(1);
 		
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);	// Black container for bars
 		dc.fillRectangle(3, offsetHeight+42, 67, 6);
		dc.fillRectangle(12, offsetHeight+59, 67, 6);
 		
 		dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_GREEN);	// % steps to goal bar
 		dc.fillRectangle(4, offsetHeight+43, barSteps, 4);
 		
 		dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_RED);		// Move bar
 		dc.fillRectangle(13, offsetHeight+60, barActivity, 4);
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
