##
# Century III Autopilot System
# Tries to behave like the Century III autopilot
# two axis 
#
# One would also need the autopilot configuration file
# CENTURYIII.xml and the panel instrument configuration file
#
# Written by Dave Perry to match functionality described in
#
#        CENTURY III
#  AUTOPILOT FLIGHT SYSTEM
# PILOT'S OPERATING HANDBOOK
#    NOVEMBER 1998 68S25
#
# Draws heavily from the kap140 system written by Roy Vegard Ovesen
##

# Properties

locks = "/autopilot/CENTURYIII/locks";
settings = "/autopilot/CENTURYIII/settings";
internal = "/autopilot/internal";
flightControls = "/controls/flight";
autopilotControls = "/autopilot/CENTURYIII/controls";

# locks
propLocks = props.globals.getNode(locks, 1);

lockAltHold   = propLocks.getNode("alt-hold", 1);
lockPitchHold = propLocks.getNode("pitch-hold", 1);
lockAprHold   = propLocks.getNode("apr-hold", 1);
lockGsHold    = propLocks.getNode("gs-hold", 1);
lockHdgHold   = propLocks.getNode("hdg-hold", 1);
lockNavHold   = propLocks.getNode("nav-hold", 1);
lockOmniHold  = propLocks.getNode("omni-hold", 1);
lockRevHold   = propLocks.getNode("rev-hold", 1);
lockRollAxis  = propLocks.getNode("roll-axis", 1);
lockRollMode  = propLocks.getNode("roll-mode", 1);
lockPitchAxis = propLocks.getNode("pitch-axis", 1);
lockPitchMode = propLocks.getNode("pitch-mode", 1);
lockRollArm   = propLocks.getNode("roll-arm", 1);
lockPitchArm  = propLocks.getNode("pitch-arm", 1);


rollModes     = { "OFF" : 0, "ROL" : 1, "HDG" : 2, "OMNI" : 3, "NAV" : 4, "REV" : 5, "APR" : 6 };
pitchModes    = { "OFF" : 0, "VS" : 1, "ALT" : 2, "GS" : 3, "AOA" : 4 };
rollArmModes  = { "OFF" : 0, "NAV" : 1, "OMNI" : 2, "APR" : 3, "REV" : 4 };
pitchArmModes = { "OFF" : 0, "ALT" : 1, "GS" : 2 };

# settings
propSettings = props.globals.getNode(settings, 1);

settingTargetAltPressure    = propSettings.getNode("target-alt-pressure", 1);
settingTargetInterceptAngle = propSettings.getNode("target-intercept-angle", 1);
settingTargetPressureRate   = propSettings.getNode("target-pressure-rate", 1);
settingTargetRollDeg        = propSettings.getNode("target-roll-deg", 1);
settingRollKnobDeg          = propSettings.getNode("roll-knob-deg", 1);
settingTargetPitchDeg       = propSettings.getNode("target-pitch-deg", 1);
settingPitchWheelDeg        = propSettings.getNode("pitch-wheel-deg", 1);
settingAutoPitchTrim        = propSettings.getNode("auto-pitch-trim", 1);
settingGScaptured           = propSettings.getNode("gs-captured", 1);
settingDeltaPitch           = propSettings.getNode("delta-pitch", 1);

#Flight controls
propFlightControls = props.globals.getNode(flightControls, 1);

elevatorControl         = propFlightControls.getNode("elevator", 1);
elevatorTrimControl     = propFlightControls.getNode("elevator-trim", 1);

#Autopilot controls
propAutopilotControls   = props.globals.getNode(autopilotControls, 1);

rollControl             = propAutopilotControls.getNode("roll", 1);
# values 0 (ROLL switch off) 1 (ROLL switch on)

hdgControl              = propAutopilotControls.getNode("hdg", 1);
# values 0 (HDG switch off)  1 (HDG switch on)

modeControl             = propAutopilotControls.getNode("mode", 1);

altControl              = propAutopilotControls.getNode("alt", 1);
# values 0 (ALT switch off)  1 (ALT switch on)

pitchControl            = propAutopilotControls.getNode("pitch", 1);
# values 0 (PITCH switch off)  1 (PITCH switch on)

headingNeedleDeflection = "/instrumentation/nav/heading-needle-deflection";
gsNeedleDeflection = "/instrumentation/nav/gs-needle-deflection";
indicatedPitchDeg =  "/instrumentation/attitude-indicator/indicated-pitch-deg";
staticPressure = "/systems/static/pressure-inhg";
altitudePressure = "/autopilot/CENTURYIII/settings/target-alt-pressure";
power="/systems/electrical/outputs/autopilot";
enableAutoTrim = "/sim/model/enable-auto-trim";
filteredHeadingNeedleDeflection = "/autopilot/internal/filtered-heading-needle-deflection";

pressureUnits = { "inHg" : 0, "hPa" : 1 };
altPressure = 0.0;
gsTimeCheck = 0.0;
valueTest = 0;
lastValue = 0;
newValue = 0;
minVoltageLimit = 8.0;
oldMode = 2;
rollControl.setDoubleValue(0.0);
hdgControl.setDoubleValue(0.0);
altControl.setDoubleValue(0.0);
pitchControl.setDoubleValue(0.0);
modeControl.setDoubleValue(2.0);
settingTargetPitchDeg.setDoubleValue(0.0);
settingPitchWheelDeg.setDoubleValue(0.0);
settingDeltaPitch.setDoubleValue(0.0);
settingTargetPressureRate.setDoubleValue(0.0);
settingGScaptured.setDoubleValue(0.0);
#  If you need to be able to enable/disable auto trim, make is a menue toggle.
#  Auto trim enabled by default
setprop(enableAutoTrim, 1);
autoPitchTrim = 0.0;

apInit = func {
  ##print("ap init");

  ##
  # Initialises the autopilot.
  ##

  lockAltHold.setBoolValue(0);
  lockAprHold.setBoolValue(0);
  lockGsHold.setBoolValue(0);
  lockHdgHold.setBoolValue(0);
  lockNavHold.setBoolValue(0);
  lockOmniHold.setBoolValue(0);
  lockRevHold.setBoolValue(0);
  lockRollAxis.setBoolValue(0);
  lockRollMode.setIntValue(rollModes["OFF"]);
  lockPitchAxis.setBoolValue(0);
  lockPitchHold.setBoolValue(0);
  lockPitchMode.setIntValue(pitchModes["OFF"]);
  lockRollArm.setIntValue(rollArmModes["OFF"]);
  lockPitchArm.setIntValue(pitchArmModes["OFF"]);
#  Reset the memory for power down or power up
  settingTargetAltPressure.setDoubleValue(0.0);
  settingTargetPitchDeg.setDoubleValue(0.0);
  settingTargetPressureRate.setDoubleValue(0.0);
  settingTargetInterceptAngle.setDoubleValue(0.0);
  settingTargetRollDeg.setDoubleValue(0.0);
  settingAutoPitchTrim.setDoubleValue(0.0);
  settingGScaptured.setDoubleValue(0.0);
  settingRollKnobDeg.setDoubleValue(0.0);

}

apPower = func {

## Monitor autopilot power
## Call apInit if the power is too low

  if (getprop(power) < minVoltageLimit) {
    newValue = 0;
  } else {
    newValue = 1;
  }

  valueTest = newValue - lastValue;
#  print("v_test = ", v_test);
  if (valueTest > 0.5) {
    # autopilot just powered up
    print("power up");
    apInit();
  } elsif (valueTest < -0.5) {
    # autopilot just lost power
    print("power lost");
    apInit();
    # note: all button and knobs disabled in functions below
  }
  lastValue = newValue;

  # Update difference between pitch wheel target and indicated pitch.
  # Used to animate the Pitch Trim meter to the left of pitch wheel
  if (rollControl.getValue() ) {
    settingDeltaPitch.setDoubleValue(settingPitchWheelDeg.getValue() 
                                      - getprop(indicatedPitchDeg));
  } else {
    settingDeltaPitch.setDoubleValue(0.0);
  }
  inrange0 = getprop("/instrumentation/nav[0]/in-range");
  # Shut off autopilot if HDG switch on and mode != 2 when NAV flag is on
  if ( !inrange0 ) {
     if ( hdgControl.getValue() and (modeControl.getValue() != 2)) {
        rollControl.setDoubleValue(0.0);
        apRollControl();
     }
  }
  settimer(apPower, 0.5);
}

apRollControl = func {

  if (rollControl.getValue() ) {
     rollButton(1);
  } else {
     #  A/P on/off switch was turned off, so turn off other AP switches
     hdgControl.setDoubleValue(0.0);   #hdgButton(0);
     altControl.setDoubleValue(0.0);   #altButton(0);
     pitchControl.setDoubleValue(0.0); #pitchButton(0);
#    rollButton(0);
     apInit();
  }
}

apHdgControl = func {

  if (hdgControl.getValue() ) {
     # hdg switch turned on sets roll
     rollControl.setDoubleValue(1.0);
     rollButton(1);
     ##
     # hdg switch is on so check which roll mode is set
     ##
     apModeControlsSet();
  } else {
     # hdg switch turned off resets alt and pitch
     hdgControl.setDoubleValue(0.0);   hdgButton(0);
     altControl.setDoubleValue(0.0);   altButton(0);
     pitchControl.setDoubleValue(0.0); pitchButton(0);
  }
}
 
apAltControl = func {

  if ( altControl.getValue() ){
     # Alt switch on so set ROLL, HDG, and PITCH
     rollControl.setDoubleValue(1.0);
     rollButton(1);
     hdgControl.setDoubleValue(1.0);
     # roll and hdg switches on so check which roll mode is set
     apModeControlsSet();
     pitchControl.setDoubleValue(1.0);
     pitchButton(1);     
     altButton(1);
  } else {
     altButton(0);
  }
}
      
apPitchControl = func {

  if ( pitchControl.getValue() ) {
     # Pitch switch on so set ROLL and HDG
     rollControl.setDoubleValue(1.0);
     rollButton(1); 
     hdgControl.setDoubleValue(1.0);
     # roll and hdg switches on so check which roll mode is set
     apModeControlsSet();
     pitchButton(1);
  } else {
     altControl.setDoubleValue(0.0);
     altButton(0);
     pitchButton(0);
  }
}

rollKnobUpdate = func {
  if ( rollControl.getValue() and !hdgControl.getValue() ) {
    settingTargetRollDeg.setDoubleValue( settingRollKnobDeg.getValue() );
  }
} 


pitchWheelUpdate = func {
  if ( rollControl.getValue() and !altControl.getValue() ) {
    settingTargetPitchDeg.setDoubleValue( settingPitchWheelDeg.getValue() );
  }
}


apModeControlsChange = func {
  ##
  #  Delay mode change to allow time for multi-mode rotation
  ##
  settimer(apModeControlsSet, 2);
}

apModeControlsSet = func {
  newMode = modeControl.getValue();

  ##
  # Decouple GS if the mode selector is switched from LOC NORM
  ##
  if (oldMode == rollModes["APR"] and newMode != rollModes["APR"])
  {
     if (lockPitchMode.getValue() == pitchModes["GS"])
     {
        lockPitchMode.setIntValue(pitchModes["OFF"]);
     }
     if (lockPitchArmModes.getValue() == pitchArmModes["GS"])
     {
        lockPitchArmMode.setIntValue(pitchModes["OFF"]);
     }
     lockGsHold.setBoolValue(0);
     settingGScoupled.setDoubleValue(0.0);
  }   

  oldMode = newMode;

  #All modes entered from hdg mode
  if ( hdgControl.getValue() ) {
     hdgButton(1);
     if (newMode == 0 ){
        navButton();
     } elsif (newMode == 1 ) { 
        omniButton();
     } elsif (newMode == 3 ) {
        aprButton();
     } elsif(newMode == 4 ) {
        revButton();
     }
  } else {
     return;
  }
}

rollButton = func(switch_on) {
  ##print("rollButton");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  if ( switch_on ) {
  ##
  # Engage the autopilot in Wings level mode (ROL) and set the turn rate
  # from the "ROLL Knob".
  ##

    lockAprHold.setBoolValue(0);
    lockHdgHold.setBoolValue(0);
    lockNavHold.setBoolValue(0);
    lockOmniHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollMode.setIntValue(rollModes["ROL"]);
    lockRollArm.setIntValue(rollArmModes["OFF"]);
  } else {
    lockAprHold.setBoolValue(0);
    lockHdgHold.setBoolValue(0);
    lockNavHold.setBoolValue(0);
    lockOmniHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockRollAxis.setBoolValue(0);
    lockRollMode.setIntValue(rollModes["OFF"]);
    lockRollArm.setIntValue(rollArmModes["OFF"]);
  }
}


hdgButton = func(switch_on) {
  ##print("hdgButton");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  if (switch_on) {
  ##
  # Engage the heading mode (HDG).
  ##
    lockAprHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockOmniHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollMode.setIntValue(rollModes["HDG"]);
    lockRollArm.setIntValue(rollArmModes["OFF"]);

    settingTargetInterceptAngle.setDoubleValue(0.0);

  } else {
    lockHdgHold.setBoolValue(0);
    rollKnobUpdate();
    if ( rollControl.getValue() ) {
       lockRollMode.setIntValue(rollModes["ROL"]);
    } else { 
       lockRollMode.setIntValue(rollModes["OFF"]);
    }
  }   
}

navButton = func {
  ##print("navButton");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  ##
  # The Mode Selector and DG Course Selector should be set before switching the HDG 
  # rocker switch to "on".  The DG Course Selector should be set to the OBS "to" or
  # "from" bearing.
  # Set up NAV mode and switch to the 45 degree angle intercept NAV mode
  ##
    lockAprHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockOmniHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollArm.setIntValue(rollArmModes["NAV"]);
    lockRollMode.setIntValue(rollModes["NAV"]);

    navArmFromHdg();
}

navArmFromHdg = func
{
  ##
  # Abort the NAV-ARM mode if something has changed the arm mode to something
  # else than NAV-ARM.
  ##
  if (lockRollArm.getValue() != rollArmModes["NAV"])
  {
    return;
  }

  ##
  # Activate the nav-hold controller and check the needle deviation.
  ##
  lockNavHold.setBoolValue(1);
  deviation = getprop(headingNeedleDeflection);
  ##
  # If the deflection is more than 9.95 degrees wait 5 seconds and check again.
  ##
  if (abs(deviation) > 9.95)
  {
    #print("deviation");
    settimer(navArmFromHdg, 5);
    return;
  }
  ##
  # If the deviation is less than 10 degrees turn off the NAV-ARM. End of NAV-ARM sequence.
  ##
  elsif (abs(deviation) < 10.0)
  {
    #print("capture");
    lockRollArm.setIntValue(rollArmModes["OFF"]);
  }
}

omniButton = func {
  ##print("navButton");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  ##
  # The Mode Selector and DG Course Selector should be set before switching the HDG 
  # rocker switch to "on".  The DG Course Selector should be set to the OBS "to" or
  # "from" bearing.
  # Set up OMNI mode and switch to the 45 degree angle intercept OMNI mode
  ##
    lockAprHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockOmniHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollArm.setIntValue(rollArmModes["OMNI"]);
    lockRollMode.setIntValue(rollModes["OMNI"]);

    omniArmFromHdg(); 
}


omniArmFromHdg = func
{
  ##
  # Abort the OMNI-ARM mode if something has changed the arm mode to something
  # else than OMNI-ARM.
  ##
  if (lockRollArm.getValue() != rollArmModes["OMNI"])
  {
    return;
  }

  ##
  # Activate the omni-hold controller and check the needle deviation.
  ##
  lockOmniHold.setBoolValue(1);
  deviation = getprop(filteredHeadingNeedleDeflection);
  ##
  # If the deflection is more than 9.95 degrees wait 5 seconds and check again.
  ##
  if (abs(deviation) > 9.95)
  {
    #print("deviation");
    settimer(omniArmFromHdg, 5);
    return;
  }
  ##
  # If the deviation is less than 10 degrees turn off the OMNI-ARM. End of OMNI-ARM sequence.
  ##
  elsif (abs(deviation) < 10.0)
  {
    #print("capture");
    lockRollArm.setIntValue(rollArmModes["OFF"]);
  }
}


aprButton = func {
  ##print("aprButton");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  ##
  # The Mode Selector and DG Course Selector should be set before switching the HDG 
  # rocker switch to "on". Set the DG Course Selector to the LOC inbound heading. 
  # Set up APR mode and switch to the 45 degree angle intercept APR mode
  ##
    lockAprHold.setBoolValue(1);
    lockRevHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockOmniHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollArm.setIntValue(rollArmModes["APR"]);
    lockRollMode.setIntValue(rollModes["APR"]);
    gsTimeCheck = -1;

    aprArmFromHdg();
}

aprArmFromHdg = func
{
  ##
  # Abort the APR-ARM mode if something has changed the arm mode to something
  # else than APR-ARM.
  ##
  if (lockRollArm.getValue() != rollArmModes["APR"]
      or !lockAltHold.getValue()
      or getprop(gsNeedleDeflection) < 0.0)
  {
    return;
  }
  gsTimeCheck = gsTimeCheck + 1;
  if (gsTimeCheck < 20)
  {
    settimer(aprArmFromHdg, 1.0);
  }

  ##
  # Activate the apr-hold controller and check the needle deviation.
  ##
  lockAprHold.setBoolValue(1);
  deviation = getprop(headingNeedleDeflection);
  ##
  # If the deflection is more than 2.5 degrees wait 5 seconds and check again.
  ##
  if (abs(deviation) > 2.495)
  {
    #print("deviation");
    settimer(aprArmFromHdg, 5);
    return;
  }
  ##
  # If the deviation is less than 2.5 degrees, start the GS-ARM sequence
  ##
  elsif (abs(deviation) < 2.5)
  {
    lockPitchArm.setIntValue(pitchArmModes["GS"]);
    gsArm();
  }
}

gsArm = func {
  ##
  # Abort the GS-ARM mode if something has changed the arm mode to something
  # else than GS-ARM.
  ##
  if (lockPitchArm.getValue() != pitchArmModes["GS"])
  {
    return;
  }

  deviation = getprop(gsNeedleDeflection);
  ##
  # If the deflection is more than 0.25 degrees wait 5 seconds and check again.
  ##
  if (abs(deviation) > 0.25)
  {
    #print("deviation");
    settimer(gsArm, 5);
    return;
  }
  ##
  # If the deviation is less than 1 then activate the GS pitch mode.
  ##
  elsif (abs(deviation) < 0.251)
  {
    #print("capture");
    lockAltHold.setBoolValue(0);
    lockGsHold.setBoolValue(1);
    lockPitchMode.setIntValue(pitchModes["GS"]);
    lockPitchArm.setIntValue(pitchArmModes["OFF"]);
    settingGScaptured.setDoubleValue(1.0);
  }
}


revButton = func {
  ##print("revButton");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  ##
  # The Mode Selector and DG Course Selector should be set before switching the HDG 
  # rocker switch to "on". Set the DG Course Selector to the LOC outbound
  # (or reverse) heading.  
  # Set up REV mode and switch to the 45 degree angle intercept REV mode
  ##
    lockAprHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockOmniHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollArm.setIntValue(rollArmModes["REV"]);

    revArmFromHdg(); 
}


revArmFromHdg = func
{
  ##
  # Abort the REV-ARM mode if something has changed the arm mode to something
  # else than REV-ARM.
  ##
  if (lockRollArm.getValue() != rollArmModes["REV"])
  {
    return;
  }

  ##
  # Activate the rev-hold controller and check the needle deviation.
  ##
  lockRevHold.setBoolValue(1);
  deviation = getprop(headingNeedleDeflection);
  ##
  # If the deflection is more than 2.5 degrees wait 5 seconds and check again.
  ##
  if (abs(deviation) > 2.495)
  {
    #print("deviation");
    settimer(revArmFromHdg, 5);
    return;
  }
  ##
  # If the deviation is less than 2.5 - End of REV-ARM sequence.
  ##
  elsif (abs(deviation) < 2.5)
  {
    #print("capture");
    lockRollArm.setIntValue(rollArmModes["OFF"]);
    lockAprHold.setBoolValue(0);
    lockRevHold.setBoolValue(1);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockOmniHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollMode.setIntValue(rollModes["REV"]);
    lockRollArm.setIntValue(rollArmModes["OFF"]);
  }
}


altButton = func(switch_on) {
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  if (switch_on) {
    lockAltHold.setBoolValue(1);
    lockPitchAxis.setBoolValue(1);
#    lockPitchMode.setIntValue(pitchModes["ALT"]);

    altPressure = getprop(staticPressure);
    settingTargetAltPressure.setDoubleValue(altPressure);
#    print("enableAutoTrim = ", getprop(enableAutoTrim));
    if ( getprop(enableAutoTrim) ) {
       settingAutoPitchTrim.setDoubleValue(1);
    }
  } else {
    lockAltHold.setBoolValue(0);
    lockPitchAxis.setBoolValue(0);
    lockPitchMode.setIntValue(pitchModes["OFF"]);
    lockPitchArm.setIntValue(pitchArmModes["OFF"]);
    pitchWheelUpdate();
    settingTargetPressureRate.setDoubleValue(0.0);
    # alt switch is off so make sure the glide slope is disabled
    settingGScaptured.setDoubleValue(0.0);
    lockGsHold.setBoolValue(0);
  }  
}

pitchButton = func(switch_on) {
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  if (switch_on) {
    lockPitchHold.setBoolValue(1);
#    lockPitchAxis.setBoolValue(1);
#    lockPitchMode.setIntValue(pitchModes["AOA"]);
#    print("enableAutoTrim = ", getprop(enableAutoTrim));
    if ( getprop(enableAutoTrim) ) {
       settingAutoPitchTrim.setDoubleValue(1);
    }
  } else {
    lockPitchHold.setBoolValue(0);
    lockPitchAxis.setBoolValue(0);
    lockPitchMode.setIntValue(pitchModes["OFF"]);
    settingAutoPitchTrim.setDoubleValue(0);
  }
}

touchPower = func{
   setprop(power,apVolts);
}

apVolts = getprop(power);

if ( apVolts == nil or apVolts < minVoltageLimit ) {
   # Wait for autopilot to be powered up
   var L = setlistener(power, func {
   apPower();
   removelistener(L);
   });
} else {
   # Skip the setlistener since autopilot is already powered up
   settimer(touchPower ,10);
   apPower();
}


