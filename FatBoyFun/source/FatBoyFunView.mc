using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.ActivityMonitor as Act;
using Toybox.UserProfile as User;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Lang as Lang;

class FatBoyFunView extends Ui.WatchFace {

	const square = 148;
	const semiround = 180;
	const rectangle = 205;
	const round = 218;
	
	var bmp;
	var hrt;
	
	// Calculate as follows:  Activity level from 0-100; 20 is low activity, 50 is medium, 80 is high (athlete)
	function calculatePA (activityClass, gender) {
		var pa = null;		
		if (gender == 1) {	// Male
	    	if (activityClass < 20)			{ pa = 1.0; }
        	else if (activityClass < 50)	{ pa = 1.11; }
        	else if (activityClass < 80)	{ pa = 1.25; }
        	else							{ pa  =1.48; }  
        }
        else if (gender == 2) {	// Female
            if (activityClass < 20)			{ pa = 1.0; }
        	else if (activityClass < 50)	{ pa = 1.12; }
        	else if (activityClass < 80)	{ pa = 1.27; }
        	else							{ pa  =1.45; }   
        }
        else {	// Unknown gender so take average
            if (activityClass < 20)			{ pa = 1.0; }
        	else if (activityClass < 50)	{ pa = 1.115; }
        	else if (activityClass < 80)	{ pa = 1.26; }
        	else							{ pa  =1.465; }   
        }
        return pa;
    }
    
    function getAge (year, birthYear) {
    	var age = null;
    	if (birthYear) {
    		age = year - birthYear;
    	}
    	else {
    		age = 35; // Average US age
    	}
    	return (age);
    }
    
    function getHeight (heightCm, gender) { // Averages sourced from cdc.gov
    	var heightM = null;
    	if (heightCm) {
    		heightM = heightCm.toDouble() / 100;	// height is returned in centimeters so divide by 100 for meters
    	}
    	else if (gender == 1) {
    		heightM = 1.76;	// Average male height in US
    	}
    	else if (gender == 2) {
    		heightM = 1.62;	// Average female height in US
    	}
    	else {
    		heightM = 1.69;	// Average between male and female
    	}
    	return (heightM);
    }
    
    function getWeight (weightG, gender) {
    	var weightKg = null;
    	if (weightG) {
    		weightKg = weightG / 1000;	// weight is in grams so divide by 1000 for Kg
    	}
    	else if (gender == 1) {
    		weightKg = 88.7;	// Average male weight in US
    	}
    	else if (gender == 2) {
    		weightKg = 75.4;	// Average female weight in US
    	}
    	else {
    		weightKg = 82.0;	// Average between male and female
    	}
    	return (weightKg);
    }
    function maleEER (pa, age, gender, height, weight) {
    	return ((662 - 9.53*age) + pa*(15.91*weight + 539.6*height)).toNumber();
    }
    function femaleEER (pa, age, gender, height, weight) { 
    	return ((354 - 6.91*age) + pa*(9.36*weight + 726*height)).toNumber();
    }   
        
    // Estimated Energy Requirements formula for adults
    // Basically EER measures average dietary energy intake thay is predicted to maintain energy balance (weight)
    // Put another way, EER is your predicted daily energy expenditure - actual (the yellow bar) will vary
	function calculateEER (pa, age, gender, height, weight) {
		var eer = null;
		if (gender == 1) {	// Male 
        	eer = maleEER(pa, age, gender, height, weight);
        }
        else if (gender == 2)	// Female
        {       	
        	eer = femaleEER(pa, age, gender, height, weight);
        }
        else {	// Unknown gender so take average
        	eer = (maleEER(pa, age, gender, height, weight)+femaleEER(pa, age, gender, height, weight))/2;
        }
        return eer;
    }


    function initialize() {
        WatchFace.initialize();
    }

    //! Load your resources here
    function onLayout(dc) {
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
        var infoShort = Calendar.info(now, Time.FORMAT_SHORT);
        var clockTime = Sys.getClockTime();
        var stats = Sys.getSystemStats();       
        var hrtIter = (Act has :getHeartRateHistory) ? Act.getHeartRateHistory(1, true) : null;      
        var activityInfo = Act.getInfo();
        var userProfile = User.getProfile();       
                               
        var activityClass = userProfile.activityClass ? userProfile.activityClass : 20;	// Default to low activity
        var gender = userProfile.gender ? userProfile.gender : 0;	// 0=Unknown 1=Male 2=Female
        var age = getAge(info.year, userProfile.birthYear);
        var height = getHeight(userProfile.height, gender);
        var weight = getWeight(userProfile.weight, gender);
        var pa = calculatePA(activityClass, gender);
        var eer = calculateEER(pa, age, gender, height, weight);
        
        var stepGoal = activityInfo.stepGoal;
        var steps = activityInfo.steps; 
        var Calories = activityInfo.calories;
        var moveBarLevel = activityInfo.moveBarLevel;
        var moveBarLevelRange = activityInfo.MOVE_BAR_LEVEL_MAX-activityInfo.MOVE_BAR_LEVEL_MIN;
        var progressBarLen = 65;	// Pixel screenWidth of steps and Calories bars
        var stepsBarLen = stepGoal ? (progressBarLen*(steps.toDouble()/stepGoal.toDouble())).toNumber() : 0;
        var caloriesBarLen = eer ? (progressBarLen*(Calories.toDouble()/eer.toDouble())).toNumber() : 0;
        
        var hour = clockTime.hour;
        var hourDisplay = (!Sys.getDeviceSettings().is24Hour && hour > 12) ? hour%12 : hour;
        var timeStr = Lang.format("$1$:$2$", [hourDisplay, clockTime.min.format("%02d")]);
        var dateStr = null;	// Check user setting further down and set accordingly
        var batteryStr = Lang.format("$1$%", [stats.battery.toNumber()]);
        var activityStr = Lang.format("$1$/$2$", [steps, stepGoal]);
        var eerStr = Lang.format("eer $1$", [eer]);
        
        var screenWidth = dc.getWidth();
        var halfScreenWidth = screenWidth/2;
        var screenHeight = dc.getHeight();
        var halfScreenHeight = screenHeight/2;
        var offsetHeight = null;
        var offsetHeightActivity = null;
        var offsetWidthActivity = null;
        var activityBarLen = null;       
        var activityLen = null;
        var offsetTime = null;
        var offsetHeart = null;
        var timeFont = null;
                 
        if (screenHeight <= square) {					// Epix, Forerunner 920XT
        	timeFont = Gfx.FONT_MEDIUM;
        	offsetTime = screenHeight - 28;
        	offsetHeight = 50;
        	offsetHeightActivity = screenHeight-5;
        	offsetWidthActivity = screenWidth-125;
        	activityLen = 45;
        	offsetHeart = screenWidth-130;
        }
        else if (screenHeight <= semiround) {				// Forerunner
        	timeFont = Gfx.FONT_NUMBER_MEDIUM ;
        	offsetTime = screenHeight - 50;
        	offsetHeight = 55;
        	offsetHeightActivity = screenHeight-5;
        	offsetWidthActivity = screenWidth-145;
        	activityLen = 75;
        	offsetHeart = screenWidth-140;
        }
        else if (screenHeight <= rectangle) {				// vivoactive HR
        	timeFont = Gfx.FONT_NUMBER_MEDIUM ;
        	offsetTime = screenHeight - 50;
        	offsetHeight = 75;
        	offsetHeightActivity = screenHeight-5;
        	offsetWidthActivity = screenWidth-115;
        	activityLen = 80;
        	offsetHeart = screenWidth-100;
        }
        else {									// fenix, D2 Bravo
        	timeFont = Gfx.FONT_NUMBER_HOT;
        	offsetTime = screenHeight - 90;
        	offsetHeight = 65;
        	offsetHeightActivity = screenHeight-15;
        	offsetWidthActivity = screenWidth-155;
        	activityLen = 90;
        	offsetHeart = screenWidth-140;
        }
        
        var dateProp = App.getApp().getProperty("PROP_DATE_FORMAT");
		if (dateProp == null || dateProp.equals("")) {
			dateProp = 0;
		}
		dateProp = dateProp.toNumber();
		if (dateProp == 0) {
			dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.day, info.month]);
		}
		if (dateProp == 1) {
			dateStr = Lang.format("$1$.$2$", [info.day, infoShort.month]);
		}
		if (dateProp == 2) {
			dateStr = Lang.format("$1$.$2$.$3$", [info.day, infoShort.month, info.year]);
		}
		if (dateProp == 3) {
			dateStr = Lang.format("$2$/$1$", [info.day, infoShort.month]);
		}
		if (dateProp == 4) {
			dateStr = Lang.format("$2$/$1$/$3$", [info.day, infoShort.month, info.year]);
		}
		
        activityBarLen = moveBarLevelRange ? (activityLen*(moveBarLevel.toDouble()/moveBarLevelRange.toDouble())).toNumber() : 0;
        
    	if (stepsBarLen > progressBarLen) {		// Limit bar to 100%
    		stepsBarLen = progressBarLen;
    	}
      	if (caloriesBarLen > progressBarLen) {		// Limit bar to 100%
      		caloriesBarLen = progressBarLen;
      	}
    	if (activityBarLen > activityLen) {		// Limit bar to 100%
    		activityBarLen = activityLen;
    	}
        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
        
        dc.drawBitmap(offsetHeart, 5, hrt);
        dc.drawBitmap(0, offsetHeight, bmp); 
   		
   		dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);	
   		dc.drawText (10, offsetHeight+65, Gfx.FONT_SYSTEM_XTINY, eerStr, Gfx.TEXT_JUSTIFY_LEFT);
   	  		
   		/*
   		* For on-screen runtime debugging
   		*
   		dc.drawText (20, offsetHeight+80, Gfx.FONT_SYSTEM_XTINY, activityClass, Gfx.TEXT_JUSTIFY_LEFT);
   		dc.drawText (40, offsetHeight+80, Gfx.FONT_SYSTEM_XTINY, age, Gfx.TEXT_JUSTIFY_LEFT);
   		dc.drawText (60, offsetHeight+80, Gfx.FONT_SYSTEM_XTINY, gender, Gfx.TEXT_JUSTIFY_LEFT);
   		dc.drawText (30, offsetHeight+95, Gfx.FONT_SYSTEM_XTINY, weight, Gfx.TEXT_JUSTIFY_LEFT);
   		dc.drawText (50, offsetHeight+95, Gfx.FONT_SYSTEM_XTINY, height, Gfx.TEXT_JUSTIFY_LEFT);
   		*/
   		
   		
 		// Get most recent heart rate from history
        if (hrtIter != null) {
        	var hrtRate = "---";		// Default display if no heart rate available
        	if (hrtIter.getMax() != hrtIter.INVALID_HR_SAMPLE) {
        		hrtRate = hrtIter.getMax();
        	}       	 		
 			dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);	
 			dc.drawText (offsetHeart+30, 10, Gfx.FONT_LARGE, hrtRate, Gfx.TEXT_JUSTIFY_CENTER);		
        }
        
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawText (50, offsetHeight-20, Gfx.FONT_TINY, batteryStr, Gfx.TEXT_JUSTIFY_CENTER);
		dc.drawText (50, offsetHeight, Gfx.FONT_TINY, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
		
		dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);             
        dc.drawText (halfScreenWidth, offsetTime, timeFont, timeStr, Gfx.TEXT_JUSTIFY_CENTER);         

 		dc.setPenWidth(1);
 		
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);	// Black container for bars
 		dc.fillRectangle(3, offsetHeight+42, 67, 6);
		dc.fillRectangle(12, offsetHeight+59, 67, 6);
 		
 		dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_GREEN);	// % steps to goal bar
 		dc.fillRectangle(4, offsetHeight+43, stepsBarLen, 4);
 		
 		dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_YELLOW);		// Calories to goal bar
 		dc.fillRectangle(13, offsetHeight+60, caloriesBarLen, 4);
 		
 		dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_RED);		// Move bar
 		dc.fillRectangle(offsetWidthActivity, offsetHeightActivity, activityBarLen, 4);
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
