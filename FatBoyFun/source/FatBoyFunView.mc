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
	const zones = [	'Y','X','W','V','U','T','S','R','Q','P','O','N',
					'Z',
					'A','B','C','D','E','F','G','H','I','K','L','M'
	];
	var bmp = null;
	var hrt = null;	
    var deviceSpecs = null;  

    function initialize() {
        WatchFace.initialize();
    }

    //! Load your resources here
    function onLayout(dc) {
        bmp = Ui.loadResource(Rez.Drawables.FatBoy);
        hrt = Ui.loadResource(Rez.Drawables.Heart);
        deviceSpecs = getDeviceSpecs(dc);   
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
        var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_LONG);
        var infoShort = Calendar.info(now, Time.FORMAT_SHORT);
        var clockTime = Sys.getClockTime();
        var stats = Sys.getSystemStats();         
        var activityInfo = Act.getInfo();
        var userProfile = User.getProfile();   
                  
        var hrtIter = (Act has :getHeartRateHistory) ? Act.getHeartRateHistory(1, true) : null;                            
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

        var dateStr = getDateStr(info, infoShort);	
        var batteryStr = Lang.format("$1$%", [stats.battery.toNumber()]);
        var activityStr = Lang.format("$1$/$2$", [steps, stepGoal]);
        var eerStr = Lang.format("eer $1$", [eer]);  
		
		var progressBarLen = deviceSpecs["progressBarLen"];
		var activityLen = deviceSpecs["activityLen"];
        var stepsBarLen = stepGoal ? (progressBarLen*(steps.toDouble()/stepGoal.toDouble())).toNumber() : 0;
        var caloriesBarLen = eer ? (progressBarLen*(Calories.toDouble()/eer.toDouble())).toNumber() : 0; 	
        var activityBarLen = moveBarLevelRange ? (activityLen*(moveBarLevel.toDouble()/moveBarLevelRange.toDouble())).toNumber() : 0;
        
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
        
        dc.drawBitmap(deviceSpecs["offsetHeart"], 5, hrt);
        dc.drawBitmap(0, deviceSpecs["offsetHeight"], bmp); 
   		
   		dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);	
   		dc.drawText (10, deviceSpecs["offsetHeight"]+65, Gfx.FONT_SYSTEM_XTINY, eerStr, Gfx.TEXT_JUSTIFY_LEFT);  	  		
   		
 		// Get most recent heart rate from history
        if (hrtIter != null) {
        	var hrtRate = "---";		// Default display if no heart rate available
        	if (hrtIter.getMax() != hrtIter.INVALID_HR_SAMPLE) {
        		hrtRate = hrtIter.getMax();
        	}       	 		
 			dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);	
 			dc.drawText (deviceSpecs["offsetHeart"]+30, 10, Gfx.FONT_LARGE, hrtRate, Gfx.TEXT_JUSTIFY_CENTER);		
        }
        
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawText (50, deviceSpecs["offsetHeight"]-20, Gfx.FONT_TINY, batteryStr, Gfx.TEXT_JUSTIFY_CENTER);
		dc.drawText (50, deviceSpecs["offsetHeight"], Gfx.FONT_TINY, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
		
		dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);   
		var timeElements = getTimeStr();          
        dc.drawText (deviceSpecs["screenWidth"]/2, deviceSpecs["offsetTime"], deviceSpecs["timeFont"], timeElements[0], Gfx.TEXT_JUSTIFY_CENTER);         
		if (timeElements[1]) {
		        dc.drawText (deviceSpecs["offsetWidthZone"], deviceSpecs["offsetHeightZone"], Gfx.FONT_MEDIUM, timeElements[1], Gfx.TEXT_JUSTIFY_CENTER);         
		}

 		dc.setPenWidth(1);
 		
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);	// Black container for bars
 		dc.fillRectangle(3, deviceSpecs["offsetHeight"]+42, 67, 6);
		dc.fillRectangle(12, deviceSpecs["offsetHeight"]+59, 67, 6);
 		
 		dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_GREEN);	// % steps to goal bar
 		dc.fillRectangle(4, deviceSpecs["offsetHeight"]+43, stepsBarLen, 4);
 		
 		dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_YELLOW);		// Calories to goal bar
 		dc.fillRectangle(13, deviceSpecs["offsetHeight"]+60, caloriesBarLen, 4);
 		
 		dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_RED);		// Move bar
 		dc.fillRectangle(deviceSpecs["offsetWidthActivity"], deviceSpecs["offsetHeightActivity"], activityBarLen, 4);
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
    
    /*
     * Custom functions below to be moved to classes later
     */
    
    /*
     * Note on Activity level from 0-100; 
     * 0-19 couch potato
     * 20-49 low activity
     * 50-79 mediumn activity
     * 80-100 high (athlete)
     */
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
    
    function getTimeStr () {
    	var timeProp = App.getApp().getProperty("PROP_TIME_FORMAT");
        var clockTime = Sys.getClockTime();
        var hour = clockTime.hour;       
        var min = clockTime.min; 
        var timeStr = null;
        var utcOffset = null;
        var zone = null;

    	if (timeProp == null || timeProp.equals("")) {
			timeProp = 0;
		}
		else {
			timeProp = timeProp.toNumber();
		}
		Sys.print ("Time property = " + timeProp);
        
		
		if (timeProp == 1) {
        	timeStr = Lang.format("$1$$2$", [hour.format("%02d"), min.format("%02d")]);
        }
        else if (timeProp == 2) {
            utcOffset = 12 + (clockTime.timeZoneOffset / 3600);
            zone = zones[utcOffset];
        	timeStr = Lang.format("$1$$2$", [hour.format("%02d"), min.format("%02d")]);
        }
		else { // Default to 0
			if (!Sys.getDeviceSettings().is24Hour) {
        		timeStr = Lang.format("$1$:$2$", [(hour%12), min.format("%02d")]);
        	}
        	else {
        	    timeStr = Lang.format("$1$:$2$", [hour.format("%02d"), min.format("%02d")]);
        	}
        }
        
        return [timeStr, zone];
    }
    
    function getDateStr (info, infoShort) {
    	var dateProp = App.getApp().getProperty("PROP_DATE_FORMAT");
    	var dateStr = null;
    	
    	if (dateProp == null || dateProp.equals("")) {
			dateProp = 0;
		}
		else {
			dateProp = dateProp.toNumber();
		}
		Sys.print ("Date property = " + dateProp);

		if (dateProp == 1) {
			dateStr = Lang.format("$1$.$2$", [info.day, infoShort.month]);
		}
		else if (dateProp == 2) {
			dateStr = Lang.format("$1$.$2$.$3$", [info.day, infoShort.month, info.year]);
		}
		else if (dateProp == 3) {
			dateStr = Lang.format("$2$/$1$", [info.day, infoShort.month]);
		}
		else if (dateProp == 4) {
			dateStr = Lang.format("$2$/$1$/$3$", [info.day, infoShort.month, info.year]);
		}
		else { // Default to 0
			dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.day, info.month]);
		}
		return dateStr;
	}
	
	function getDeviceSpecs(dc) {		
		var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        
		var deviceSpecs = {};
		deviceSpecs["progressBarLen"] = 65;
		deviceSpecs["screenWidth"] = screenWidth;
		deviceSpecs["screenHeight"] = screenHeight;
		
	    if (screenHeight <= square) {					// Epix, Forerunner 920XT
        	deviceSpecs["timeFont"] = Gfx.FONT_MEDIUM;
        	deviceSpecs["offsetTime"] = screenHeight - 28;
        	deviceSpecs["offsetWidthZone"] = screenWidth - 70;
        	deviceSpecs["offsetHeightZone"] = screenHeight - 28;
        	deviceSpecs["offsetHeight"] = 50;
        	deviceSpecs["offsetHeightActivity"] = screenHeight-5;
        	deviceSpecs["offsetWidthActivity"] = screenWidth-125;
        	deviceSpecs["activityLen"] = 45;
        	deviceSpecs["offsetHeart"] = screenWidth-130;
        }
        else if (screenHeight <= semiround) {				// Forerunner
        	deviceSpecs["timeFont"] = Gfx.FONT_NUMBER_MEDIUM ;
        	deviceSpecs["offsetTime"] = screenHeight - 50;
        	deviceSpecs["offsetWidthZone"] = screenWidth - 60;
        	deviceSpecs["offsetHeightZone"] = screenHeight - 45;
        	deviceSpecs["offsetHeight"] = 55;
        	deviceSpecs["offsetHeightActivity"] = screenHeight-5;
        	deviceSpecs["offsetWidthActivity"] = screenWidth-145;
        	deviceSpecs["activityLen"] = 75;
        	deviceSpecs["offsetHeart"] = screenWidth-140;
        }
        else if (screenHeight <= rectangle) {				// vivoactive HR
        	deviceSpecs["timeFont"] = Gfx.FONT_NUMBER_MEDIUM ;
        	deviceSpecs["offsetTime"] = screenHeight - 50;
        	deviceSpecs["offsetWidthZone"] = screenWidth - 28;
        	deviceSpecs["offsetHeightZone"] = screenHeight - 45;
        	deviceSpecs["offsetHeight"] = 75;
        	deviceSpecs["offsetHeightActivity"] = screenHeight-5;
        	deviceSpecs["offsetWidthActivity"] = screenWidth-115;
        	deviceSpecs["activityLen"] = 80;
        	deviceSpecs["offsetHeart"] = screenWidth-100;
        }
        else {									// fenix, D2 Bravo
        	deviceSpecs["timeFont"] = Gfx.FONT_NUMBER_HOT;
        	deviceSpecs["offsetTime"] = screenHeight - 90;
        	deviceSpecs["offsetWidthZone"] = screenWidth - 50;
        	deviceSpecs["offsetHeightZone"] = screenHeight - 75;
        	deviceSpecs["offsetHeight"] = 65;
        	deviceSpecs["offsetHeightActivity"] = screenHeight-15;
        	deviceSpecs["offsetWidthActivity"] = screenWidth-155;
        	deviceSpecs["activityLen"] = 90;
        	deviceSpecs["offsetHeart"] = screenWidth-140;
        }
        return deviceSpecs;
	}
}
