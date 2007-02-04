##
# Bendix/King KAP140 Autopilot System
# Tries to behave like the Bendix/King KAP140 autopilot
# two axis w/altitude preselect.
#
# One would also need the autopilot configuration file
# KAP140.xml and the panel instrument configuration file
#
# Written by Roy Vegard Ovesen
# "Power-check" edits by Dave Perry
##

# Properties

locks = "/autopilot/KAP140/locks";
settings = "/autopilot/KAP140/settings";
annunciators = "/autopilot/KAP140/annunciators";
internal = "/autopilot/internal";
power="/systems/electrical/outputs/autopilot";

# locks
propLocks = props.globals.getNode(locks, 1);

lockAltHold   = propLocks.getNode("alt-hold", 1);
lockAprHold   = propLocks.getNode("apr-hold", 1);
lockGsHold    = propLocks.getNode("gs-hold", 1);
lockHdgHold   = propLocks.getNode("hdg-hold", 1);
lockNavHold   = propLocks.getNode("nav-hold", 1);
lockRevHold   = propLocks.getNode("rev-hold", 1);
lockRollAxis  = propLocks.getNode("roll-axis", 1);
lockRollMode  = propLocks.getNode("roll-mode", 1);
lockPitchAxis = propLocks.getNode("pitch-axis", 1);
lockPitchMode = propLocks.getNode("pitch-mode", 1);
lockRollArm   = propLocks.getNode("roll-arm", 1);
lockPitchArm  = propLocks.getNode("pitch-arm", 1);


rollModes     = { "OFF" : 0, "ROL" : 1, "HDG" : 2, "NAV" : 3, "REV" : 4, "APR" : 5 };
pitchModes    = { "OFF" : 0, "VS" : 1, "ALT" : 2, "GS" : 3 };
rollArmModes  = { "OFF" : 0, "NAV" : 1, "APR" : 2, "REV" : 3 };
pitchArmModes = { "OFF" : 0, "ALT" : 1, "GS" : 2 };

# settings
propSettings = props.globals.getNode(settings, 1);

settingTargetAltPressure    = propSettings.getNode("target-alt-pressure", 1);
settingTargetInterceptAngle = propSettings.getNode("target-intercept-angle", 1);
settingTargetPressureRate   = propSettings.getNode("target-pressure-rate", 1);
settingTargetTurnRate       = propSettings.getNode("target-turn-rate", 1);
settingTargetAltFt          = propSettings.getNode("target-alt-ft", 1);
settingBaroSettingInhg      = propSettings.getNode("baro-setting-inhg", 1);
settingBaroSettingHpa       = propSettings.getNode("baro-setting-hpa", 1);

#annunciators
propAnnunciators = props.globals.getNode(annunciators, 1);

annunciatorRol          = propAnnunciators.getNode("rol", 1);
annunciatorHdg          = propAnnunciators.getNode("hdg", 1);
annunciatorNav          = propAnnunciators.getNode("nav", 1);
annunciatorNavArm       = propAnnunciators.getNode("nav-arm", 1);
annunciatorApr          = propAnnunciators.getNode("apr", 1);
annunciatorAprArm       = propAnnunciators.getNode("apr-arm", 1);
annunciatorRev          = propAnnunciators.getNode("rev", 1);
annunciatorRevArm       = propAnnunciators.getNode("rev-arm", 1);
annunciatorVs           = propAnnunciators.getNode("vs", 1);
annunciatorVsNumber     = propAnnunciators.getNode("vs-number", 1);
annunciatorFpm          = propAnnunciators.getNode("fpm", 1);
annunciatorAlt          = propAnnunciators.getNode("alt", 1);
annunciatorAltArm       = propAnnunciators.getNode("alt-arm", 1);
annunciatorAltNumber    = propAnnunciators.getNode("alt-number", 1);
annunciatorAltAlert     = propAnnunciators.getNode("alt-alert", 1);
annunciatorApr          = propAnnunciators.getNode("apr", 1);
annunciatorGs           = propAnnunciators.getNode("gs", 1);
annunciatorGsArm        = propAnnunciators.getNode("gs-arm", 1);
annunciatorPtUp         = propAnnunciators.getNode("pt-up", 1);
annunciatorPtDn         = propAnnunciators.getNode("pt-dn", 1);
annunciatorBsHpaNumber  = propAnnunciators.getNode("bs-hpa-number", 1);
annunciatorBsInhgNumber = propAnnunciators.getNode("bs-inhg-number", 1);
annunciatorAp           = propAnnunciators.getNode("ap", 1);
annunciatorBeep         = propAnnunciators.getNode("beep", 1);

navRadio = "/instrumentation/nav";
encoder =  "/instrumentation/encoder";
staticPort = "/systems/static";

annunciator = annunciatorAp;
annunciatorState = 0;
flashInterval = 0.0;
flashCount = 0.0;
flashTimer = -1.0;

pressureUnits = { "inHg" : 0, "hPa" : 1 };
baroSettingUnit = pressureUnits["inHg"];
baroSettingInhg = 29.92;
baroSettingHpa = baroSettingInhg * 0.03386389;
baroSettingAdjusting = 0;
baroButtonDown = 0;
baroTimerRunning = 0;

altPreselect = 0;
altButtonTimerRunning = 0;
altButtonTimerIgnore = 0;
altAlertOn = 0;
altCaptured = 0;

valueTest = 0;
lastValue = 0;
newValue = 0;
minVoltageLimit = 8.0;

flasher = func {
  flashTimer = -1.0;
  annunciator = arg[0];
  flashInterval = arg[1];
  flashCount = arg[2] + 1;
  annunciatorState = arg[3];

  flashTimer = 0.0;

  flashAnnunciator();
}

flashAnnunciator = func {
  #print(annunciator.getName());
  #print("FI:", flashInterval);
  #print("FC:", flashCount);
  #print("FT:", flashTimer);

  ##
  # If flashTimer is set to -1 then flashing is aborted
  if (flashTimer < -0.5)
  {
    ##print ("flash abort ", annunciator);
    annunciator.setBoolValue(0);
    return;
  }

  if (flashTimer < flashCount)
  {
    #flashTimer = flashTimer + 1.0;
    if (annunciator.getValue() == 1)
    {
      annunciator.setBoolValue(0);
      settimer(flashAnnunciator, flashInterval / 2.0);
    }
    else
    {
      flashTimer = flashTimer + 1.0;
      annunciator.setBoolValue(1);
      settimer(flashAnnunciator, flashInterval);
    }
  }
  else
  {
    flashTimer = -1.0;
    annunciator.setBoolValue(annunciatorState);
  }
}


ptCheck = func {
  ##print("pitch trim check");

  if (lockPitchMode.getValue() == pitchModes["OFF"])
  {
    annunciatorPtUp.setBoolValue(0);
    annunciatorPtDn.setBoolValue(0);
    return;
  }

  else
  {
    elevatorControl = getprop("/controls/flight/elevator");
    ##print(elevatorControl);

    # Flash the pitch trim up annunciator
    if (elevatorControl < -0.01)
    {
      if (annunciatorPtUp.getValue() == 0)
      {
        annunciatorPtUp.setBoolValue(1);
      }
      elsif (annunciatorPtUp.getValue() == 1)
      {
        annunciatorPtUp.setBoolValue(0);
      }
    }
    # Flash the pitch trim down annunciator
    elsif (elevatorControl > 0.01)
    {
      if (annunciatorPtDn.getValue() == 0)
      {
        annunciatorPtDn.setBoolValue(1);
      }
      elsif (annunciatorPtDn.getValue() == 1)
      {
        annunciatorPtDn.setBoolValue(0);
      }
    }

    else
    {
      annunciatorPtUp.setBoolValue(0);
      annunciatorPtDn.setBoolValue(0);
    }
  }

  settimer(ptCheck, 0.5);
}


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
  lockRevHold.setBoolValue(0);
  lockRollAxis.setBoolValue(0);
  lockRollMode.setIntValue(rollModes["OFF"]);
  lockPitchAxis.setBoolValue(0);
  lockPitchMode.setIntValue(pitchModes["OFF"]);
  lockRollArm.setIntValue(rollArmModes["OFF"]);
  lockPitchArm.setIntValue(pitchArmModes["OFF"]);
#  Reset the memory for power down or power up
  altPreselect = 0;
  baroSettingInhg = 29.92;
  settingBaroSettingInhg.setDoubleValue(baroSettingInhg);
  settingBaroSettingHpa.setDoubleValue(baroSettingInhg * 0.03386389);
  settingTargetAltFt.setDoubleValue(altPreselect);
  settingTargetAltPressure.setDoubleValue(0.0);
  settingTargetInterceptAngle.setDoubleValue(0.0);
  settingTargetPressureRate.setDoubleValue(0.0);
  settingTargetTurnRate.setDoubleValue(0.0);

  annunciatorRol.setBoolValue(0);
  annunciatorHdg.setBoolValue(0);
  annunciatorNav.setBoolValue(0);
  annunciatorNavArm.setBoolValue(0);
  annunciatorApr.setBoolValue(0);
  annunciatorAprArm.setBoolValue(0);
  annunciatorRev.setBoolValue(0);
  annunciatorRevArm.setBoolValue(0);
  annunciatorVs.setBoolValue(0);
  annunciatorVsNumber.setBoolValue(0);
  annunciatorFpm.setBoolValue(0);
  annunciatorAlt.setBoolValue(0);
  annunciatorAltArm.setBoolValue(0);
  annunciatorAltNumber.setBoolValue(0);
  annunciatorGs.setBoolValue(0);
  annunciatorGsArm.setBoolValue(0);
  annunciatorPtUp.setBoolValue(0);
  annunciatorPtDn.setBoolValue(0);
  annunciatorBsHpaNumber.setBoolValue(0);
  annunciatorBsInhgNumber.setBoolValue(0);
  annunciatorAp.setBoolValue(0);
  annunciatorBeep.setBoolValue(0);

#  settimer(altAlert, 5.0);
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
  if (valueTest > 0.5){
    # autopilot just powered up
    print("power up");
    apInit();
    altAlert();
  } elsif (valueTest < -0.5) {
    # autopilot just lost power
    print("power lost");
    apInit();
    annunciatorAltAlert.setBoolValue(0);
    # note: all button and knobs disabled in functions below
  }
  lastValue = newValue;
  settimer(apPower, 0.5);
}

apButton = func {
  ##print("apButton");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  ##
  # Engages the autopilot in Wings level mode (ROL) and Vertical speed hold
  # mode (VS).
  ##
  if (lockRollMode.getValue() == rollModes["OFF"] and
      lockPitchMode.getValue() == pitchModes["OFF"])
  {
    flashTimer = -1.0;

    lockAltHold.setBoolValue(0);
    lockAprHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockHdgHold.setBoolValue(0);
    lockNavHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollMode.setIntValue(rollModes["ROL"]);
    lockPitchAxis.setBoolValue(1);
    lockPitchMode.setIntValue(pitchModes["VS"]);
    lockRollArm.setIntValue(rollArmModes["OFF"]);
    lockPitchArm.setIntValue(pitchArmModes["OFF"]);

    annunciatorRol.setBoolValue(1);
    annunciatorVs.setBoolValue(1);
    annunciatorVsNumber.setBoolValue(1);

    settingTargetTurnRate.setDoubleValue(0.0);

    ptCheck();

    pressureRate = getprop(internal, "pressure-rate");
    #print(pressureRate);
    fpm = -pressureRate * 58000;
    #print(fpm);
    if (fpm > 0.0)
    {
      fpm = int(fpm/100 + 0.5) * 100;
    }
    else
    {
      fpm = int(fpm/100 - 0.5) * 100;
    }
    #print(fpm);

    settingTargetPressureRate.setDoubleValue(-fpm / 58000);

    if (altButtonTimerRunning == 0)
    {
      settimer(altButtonTimer, 3.0);
      altButtonTimerRunning = 1;
      altButtonTimerIgnore = 0;
      annunciatorAltNumber.setBoolValue(0);
    }
  }
  ##
  # Disengages all modes.
  ##
  elsif (lockRollMode.getValue() != rollModes["OFF"] and
         lockPitchMode.getValue() != pitchModes["OFF"])
  {
    flashTimer = -1.0;

    lockAltHold.setBoolValue(0);
    lockAprHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockHdgHold.setBoolValue(0);
    lockNavHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockRollAxis.setBoolValue(0);
    lockRollMode.setIntValue(rollModes["OFF"]);
    lockPitchAxis.setBoolValue(0);
    lockPitchMode.setIntValue(pitchModes["OFF"]);
    lockRollArm.setIntValue(rollArmModes["OFF"]);
    lockPitchArm.setIntValue(pitchArmModes["OFF"]);

    settingTargetAltPressure.setDoubleValue(0.0);
    settingTargetInterceptAngle.setDoubleValue(0.0);
    settingTargetPressureRate.setDoubleValue(0.0);
    settingTargetTurnRate.setDoubleValue(0.0);

    annunciatorRol.setBoolValue(0);
    annunciatorHdg.setBoolValue(0);
    annunciatorNav.setBoolValue(0);
    annunciatorNavArm.setBoolValue(0);
    annunciatorApr.setBoolValue(0);
    annunciatorAprArm.setBoolValue(0);
    annunciatorRev.setBoolValue(0);
    annunciatorRevArm.setBoolValue(0);
    annunciatorVs.setBoolValue(0);
    annunciatorVsNumber.setBoolValue(0);
    annunciatorAlt.setBoolValue(0);
    annunciatorAltArm.setBoolValue(0);
    annunciatorAltNumber.setBoolValue(0);
    annunciatorApr.setBoolValue(0);
    annunciatorGs.setBoolValue(0);
    annunciatorGsArm.setBoolValue(0);
    annunciatorPtUp.setBoolValue(0);
    annunciatorPtDn.setBoolValue(0);

    flasher(annunciatorAp, 1.0, 5, 0);
  }
}


hdgButton = func {
  ##print("hdgButton");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  ##
  # Engages the heading mode (HDG) and vertical speed hold mode (VS). The
  # commanded vertical speed is set to the vertical speed present at button
  # press.
  ##
  if (lockRollMode.getValue() == rollModes["OFF"] and
      lockPitchMode.getValue() == pitchModes["OFF"])
  {
    flashTimer = -1.0;

    lockAltHold.setBoolValue(0);
    lockAprHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollMode.setIntValue(rollModes["HDG"]);
    lockPitchAxis.setBoolValue(1);
    lockPitchMode.setIntValue(pitchModes["VS"]);
    lockRollArm.setIntValue(rollArmModes["OFF"]);
    lockPitchArm.setIntValue(pitchArmModes["OFF"]);

    annunciatorHdg.setBoolValue(1);
    annunciatorAlt.setBoolValue(0);
    annunciatorApr.setBoolValue(0);
    annunciatorGs.setBoolValue(0);
    annunciatorNav.setBoolValue(0);
    annunciatorVs.setBoolValue(1);
    annunciatorVsNumber.setBoolValue(1);

    settingTargetInterceptAngle.setDoubleValue(0.0);

    ptCheck();

    pressureRate = getprop(internal, "pressure-rate");
    fpm = -pressureRate * 58000;
    #print(fpm);
    if (fpm > 0.0)
    {
      fpm = int(fpm/100 + 0.5) * 100;
    }
    else
    {
      fpm = int(fpm/100 - 0.5) * 100;
    }
    #print(fpm);

    settingTargetPressureRate.setDoubleValue(-fpm / 58000);

    if (altButtonTimerRunning == 0)
    {
      settimer(altButtonTimer, 3.0);
      altButtonTimerRunning = 1;
      altButtonTimerIgnore = 0;
      annunciatorAltNumber.setBoolValue(0);
    }
  }
  ##
  # Switch from ROL to HDG mode, but don't change pitch mode.
  ##
  elsif (lockRollMode.getValue() == rollModes["ROL"])
  {
    lockAprHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollMode.setIntValue(rollModes["HDG"]);
    lockRollArm.setIntValue(rollArmModes["OFF"]);

    annunciatorApr.setBoolValue(0);
    annunciatorGs.setBoolValue(0);
    annunciatorHdg.setBoolValue(1);
    annunciatorNav.setBoolValue(0);
    annunciatorRol.setBoolValue(0);
    annunciatorRev.setBoolValue(0);

    settingTargetInterceptAngle.setDoubleValue(0.0);
  }
  ##
  # Switch to HDG mode, but don't change pitch mode.
  ##
  elsif ( (lockRollMode.getValue() == rollModes["NAV"] or
         lockRollArm.getValue() == rollArmModes["NAV"] or
         lockRollMode.getValue() == rollModes["REV"] or
         lockRollArm.getValue() == rollArmModes["REV"]) and
         flashTimer < -0.5)
  {
    lockAprHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollMode.setIntValue(rollModes["HDG"]);
    lockRollArm.setIntValue(rollArmModes["OFF"]);

    annunciatorApr.setBoolValue(0);
    annunciatorGs.setBoolValue(0);
    annunciatorHdg.setBoolValue(1);
    annunciatorNav.setBoolValue(0);
    annunciatorRol.setBoolValue(0);
    annunciatorRev.setBoolValue(0);
    annunciatorNavArm.setBoolValue(0);

    settingTargetInterceptAngle.setDoubleValue(0.0);
  }
  ##
  # If we already are in HDG mode switch to ROL mode. Again don't touch pitch
  # mode.
  ##
  elsif (lockRollMode.getValue() == rollModes["HDG"])
  {
    lockAprHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockHdgHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollMode.setIntValue(rollModes["ROL"]);

    annunciatorApr.setBoolValue(0);
    annunciatorGs.setBoolValue(0);
    annunciatorHdg.setBoolValue(0);
    annunciatorNav.setBoolValue(0);
    annunciatorRol.setBoolValue(1);

    settingTargetTurnRate.setDoubleValue(0.0);
  }
  ##
  # If we are in APR mode we also have to change pitch mode.
  # TODO: Should we switch to VS or ALT mode? (currently VS)
  ##
  elsif ( (lockRollMode.getValue() == rollModes["APR"] or
         lockRollArm.getValue() == rollArmModes["APR"] or
         lockPitchMode.getValue() == pitchModes["GS"] or
         lockPitchArm.getValue() == pitchArmModes["GS"]) and
         flashTimer < -0.5)
  {
    lockAltHold.setBoolValue(0);
    lockAprHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollMode.setIntValue(rollModes["HDG"]);
    lockPitchAxis.setBoolValue(1);
    lockPitchMode.setIntValue(pitchModes["VS"]);
    lockRollArm.setIntValue(rollArmModes["OFF"]);
    lockPitchArm.setIntValue(pitchArmModes["OFF"]);

    annunciatorAlt.setBoolValue(0);
    annunciatorAltArm.setBoolValue(0);
    annunciatorHdg.setBoolValue(1);
    annunciatorRol.setBoolValue(0);
    annunciatorNav.setBoolValue(0);
    annunciatorApr.setBoolValue(0);
    annunciatorAprArm.setBoolValue(0);
    annunciatorGs.setBoolValue(0);
    annunciatorGsArm.setBoolValue(0);
    annunciatorVs.setBoolValue(1);
    annunciatorVsNumber.setBoolValue(1);

    settingTargetInterceptAngle.setDoubleValue(0.0);

    pressureRate = getprop(internal, "pressure-rate");
    #print(pressureRate);
    fpm = -pressureRate * 58000;
    #print(fpm);
    if (fpm > 0.0)
    {
      fpm = int(fpm/100 + 0.5) * 100;
    }
    else
    {
      fpm = int(fpm/100 - 0.5) * 100;
    }
    #print(fpm);

    settingTargetPressureRate.setDoubleValue(-fpm / 58000);

    if (altButtonTimerRunning == 0)
    {
      settimer(altButtonTimer, 3.0);
      altButtonTimerRunning = 1;
      altButtonTimerIgnore = 0;
      annunciatorAltNumber.setBoolValue(0);
    }
  }
}


navButton = func {
  ##print("navButton");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  ##
  # If we are in HDG mode we switch to the 45 degree angle intercept NAV mode
  ##
  if (lockRollMode.getValue() == rollModes["HDG"])
  {
    flasher(annunciatorHdg, 0.5, 8, 0);

    lockAprHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollArm.setIntValue(rollArmModes["NAV"]);
    lockRollMode.setIntValue(rollModes["NAV"]);

    annunciatorNavArm.setBoolValue(1);

    navArmFromHdg();
  }
  ##
  # If we are in ROL mode we switch to the all angle intercept NAV mode.
  ##
  elsif (lockRollMode.getValue() == rollModes["ROL"])
  {
    flasher(annunciatorHdg, 0.5, 8, 0);

    lockAprHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockHdgHold.setBoolValue(0);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollArm.setIntValue(rollArmModes["NAV"]);
    lockRollMode.setIntValue(rollModes["NAV"]);

    annunciatorNavArm.setBoolValue(1);

    navArmFromRol();
  }
  ##
  # TODO:
  # NAV mode can only be armed if we are in HDG or ROL mode.
  # Can anyone verify that this is correct?
  ##
}

navArmFromHdg = func
{
  ##
  # Abort the NAV-ARM mode if something has changed the arm mode to something
  # else than NAV-ARM.
  ##
  if (lockRollArm.getValue() != rollArmModes["NAV"])
  {
    annunciatorNavArm.setBoolValue(0);
    return;
  }

  #annunciatorNavArm.setBoolValue(1);
  ##
  # Wait for the HDG annunciator flashing to finish.
  ##
  if (flashTimer > -0.5)
  {
    #print("flashing...");
    settimer(navArmFromHdg, 2.5);
    return;
  }
  ##
  # Activate the nav-hold controller and check the needle deviation.
  ##
  lockNavHold.setBoolValue(1);
  deviation = getprop(navRadio, "heading-needle-deflection");
  ##
  # If the deflection is more than 3 degrees wait 5 seconds and check again.
  ##
  if (abs(deviation) > 3.0)
  {
    #print("deviation");
    settimer(navArmFromHdg, 5);
    return;
  }
  ##
  # If the deviation is less than 3 degrees turn of the NAV-ARM annunciator
  # and show the NAV annunciator. End of NAV-ARM sequence.
  ##
  elsif (abs(deviation) < 3.1)
  {
    #print("capture");
    lockRollArm.setIntValue(rollArmModes["OFF"]);
    annunciatorNavArm.setBoolValue(0);
    annunciatorNav.setBoolValue(1);
  }
}

navArmFromRol = func
{
  ##
  # Abort the NAV-ARM mode if something has changed the arm mode to something
  # else than NAV-ARM.
  ##
  if (lockRollArm.getValue() != rollArmModes["NAV"])
  {
    annunciatorNavArm.setBoolValue(0);
    return;
  }
  ##
  # Wait for the HDG annunciator flashing to finish.
  ##
  #annunciatorNavArm.setBoolValue(1);
  if (flashTimer > -0.5)
  {
    #print("flashing...");
    annunciatorRol.setBoolValue(0);
    settimer(navArmFromRol, 2.5);
    return;
  }
  ##
  # Turn the ROL annunciator back on and activate the ROL mode.
  ##
  annunciatorRol.setBoolValue(1);
  lockRollAxis.setBoolValue(1);
  settingTargetTurnRate.setDoubleValue(0.0);
  deviation = getprop(navRadio, "heading-needle-deflection");
  ##
  # If the deflection is more than 3 degrees wait 5 seconds and check again.
  ##
  if (abs(deviation) > 3.0)
  {
    #print("deviation");
    settimer(navArmFromRol, 5);
    return;
  }
  ##
  # If the deviation is less than 3 degrees turn of the NAV-ARM annunciator
  # and show the NAV annunciator. End of NAV-ARM sequence.
  ##
  elsif (abs(deviation) < 3.1)
  {
    #print("capture");
    annunciatorRol.setBoolValue(0);
    annunciatorNavArm.setBoolValue(0);
    annunciatorNav.setBoolValue(1);

    lockAprHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(1);
    lockRollAxis.setBoolValue(1);
    lockRollMode.setIntValue(rollModes["NAV"]);
    lockRollArm.setIntValue(rollArmModes["OFF"]);
  }
}

aprButton = func {
  ##print("aprButton");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  ##
  # If we are in HDG mode we switch to the 45 degree intercept angle APR mode
  ##
  if (lockRollMode.getValue() == rollModes["HDG"])
  {
    flasher(annunciatorHdg, 0.5, 8, 0);

    lockAprHold.setBoolValue(1);
    lockGsHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollArm.setIntValue(rollArmModes["APR"]);
    lockRollMode.setIntValue(rollModes["APR"]);

    annunciatorAprArm.setBoolValue(1);

    aprArmFromHdg();
  }
  elsif (lockRollMode.getValue() == rollModes["ROL"])
  {
    flasher(annunciatorHdg, 0.5, 8, 0);

    lockAprHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockHdgHold.setBoolValue(0);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollArm.setIntValue(rollArmModes["APR"]);
    lockRollMode.setIntValue(rollModes["APR"]);

    annunciatorAprArm.setBoolValue(1);

    aprArmFromRol();
  }
}

aprArmFromHdg = func
{
  ##
  # Abort the APR-ARM mode if something has changed the arm mode to something
  # else than APR-ARM.
  ##
  if (lockRollArm.getValue() != rollArmModes["APR"])
  {
    annunciatorAprArm.setBoolValue(0);
    return;
  }

  #annunciatorAprArm.setBoolValue(1);
  ##
  # Wait for the HDG annunciator flashing to finish.
  ##
  if (flashTimer > -0.5)
  {
    #print("flashing...");
    settimer(aprArmFromHdg, 2.5);
    return;
  }
  ##
  # Activate the apr-hold controller and check the needle deviation.
  ##
  lockAprHold.setBoolValue(1);
  deviation = getprop(navRadio, "heading-needle-deflection");
  ##
  # If the deflection is more than 3 degrees wait 5 seconds and check again.
  ##
  if (abs(deviation) > 3.0)
  {
    #print("deviation");
    settimer(aprArmFromHdg, 5);
    return;
  }
  ##
  # If the deviation is less than 3 degrees turn of the APR-ARM annunciator
  # and show the APR annunciator. End of APR-ARM sequence. Start the GS-ARM
  # sequence.
  ##
  elsif (abs(deviation) < 3.1)
  {
    #print("capture");
    annunciatorAprArm.setBoolValue(0);
    annunciatorApr.setBoolValue(1);
    lockPitchArm.setIntValue(pitchArmModes["GS"]);

    gsArm();
  }
}

aprArmFromRol = func
{
  ##
  # Abort the APR-ARM mode if something has changed the roll mode to something
  # else than APR-ARM.
  ##
  if (lockRollArm.getValue() != rollArmModes["APR"])
  {
    annunciatorAprArm.setBoolValue(0);
    return;
  }

  #annunciatorAprArm.setBoolValue(1);
  ##
  # Wait for the HDG annunciator flashing to finish.
  ##
  if (flashTimer > -0.5)
  {
    #print("flashing...");
    annunciatorRol.setBoolValue(0);
    settimer(aprArmFromRol, 2.5);
    return;
  }
  ##
  # Turn the ROL annunciator back on and activate the ROL mode.
  ##
  annunciatorRol.setBoolValue(1);
  lockRollAxis.setBoolValue(1);
  settingTargetTurnRate.setDoubleValue(0.0);
  deviation = getprop(navRadio, "heading-needle-deflection");
  ##
  # If the deflection is more than 3 degrees wait 5 seconds and check again.
  ##
  if (abs(deviation) > 3.0)
  {
    #print("deviation");
    settimer(aprArmFromRol, 5);
    return;
  }
  ##
  # If the deviation is less than 3 degrees turn of the APR-ARM annunciator
  # and show the APR annunciator. End of APR-ARM sequence. Start the GS-ARM
  # sequence.
  ##
  elsif (abs(deviation) < 3.1)
  {
    #print("capture");
    annunciatorRol.setBoolValue(0);
    annunciatorAprArm.setBoolValue(0);
    annunciatorApr.setBoolValue(1);

    lockAprHold.setBoolValue(1);
    lockGsHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollMode.setIntValue(rollModes["APR"]);
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
    annunciatorGsArm.setBoolValue(0);
    return;
  }

  annunciatorGsArm.setBoolValue(1);

  deviation = getprop(navRadio, "gs-needle-deflection");
  ##
  # If the deflection is more than 1 degrees wait 5 seconds and check again.
  ##
  if (abs(deviation) > 1.0)
  {
    #print("deviation");
    settimer(gsArm, 5);
    return;
  }
  ##
  # If the deviation is less than 1 degrees turn off the GS-ARM annunciator
  # and show the GS annunciator. Activate the GS pitch mode.
  ##
  elsif (abs(deviation) < 1.1)
  {
    #print("capture");
    annunciatorAlt.setBoolValue(0);
    annunciatorVs.setBoolValue(0);
    annunciatorVsNumber.setBoolValue(0);
    annunciatorGsArm.setBoolValue(0);
    annunciatorGs.setBoolValue(1);

    lockAltHold.setBoolValue(0);
    lockGsHold.setBoolValue(1);
    lockPitchMode.setIntValue(pitchModes["GS"]);
    lockPitchArm.setIntValue(pitchArmModes["OFF"]);
  }

}


revButton = func {
  ##print("revButton");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  ##
  # If we are in HDG mode we switch to the 45 degree intercept angle REV mode
  ##
  if (lockRollMode.getValue() == rollModes["HDG"])
  {
    flasher(annunciatorHdg, 0.5, 8, 0);

    lockAprHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollArm.setIntValue(rollArmModes["REV"]);

    annunciatorRevArm.setBoolValue(1);

    revArmFromHdg();
  }
  elsif (lockRollMode.getValue() == rollModes["ROL"])
  {
    flasher(annunciatorHdg, 0.5, 8, 0);

    lockAprHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockRevHold.setBoolValue(0);
    lockHdgHold.setBoolValue(0);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollArm.setIntValue(rollArmModes["REV"]);

    annunciatorRevArm.setBoolValue(1);

    revArmFromRol();
  }
}


revArmFromHdg = func
{
  ##
  # Abort the REV-ARM mode if something has changed the arm mode to something
  # else than REV-ARM.
  ##
  if (lockRollArm.getValue() != rollArmModes["REV"])
  {
    annunciatorRevArm.setBoolValue(0);
    return;
  }

  #annunciatorRevArm.setBoolValue(1);
  ##
  # Wait for the HDG annunciator flashing to finish.
  ##
  if (flashTimer > -0.5)
  {
    #print("flashing...");
    settimer(revArmFromHdg, 2.5);
    return;
  }
  ##
  # Activate the rev-hold controller and check the needle deviation.
  ##
  lockRevHold.setBoolValue(1);
  deviation = getprop(navRadio, "heading-needle-deflection");
  ##
  # If the deflection is more than 3 degrees wait 5 seconds and check again.
  ##
  if (abs(deviation) > 3.0)
  {
    #print("deviation");
    settimer(revArmFromHdg, 5);
    return;
  }
  ##
  # If the deviation is less than 3 degrees turn of the REV-ARM annunciator
  # and show the REV annunciator. End of REV-ARM sequence.
  ##
  elsif (abs(deviation) < 3.1)
  {
    #print("capture");
    annunciatorRevArm.setBoolValue(0);
    annunciatorRev.setBoolValue(1);
    lockRollArm.setIntValue(rollArmModes["OFF"]);
    annunciatorRol.setBoolValue(0);
    annunciatorRevArm.setBoolValue(0);
    annunciatorRev.setBoolValue(1);

    lockAprHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockRevHold.setBoolValue(1);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollMode.setIntValue(rollModes["REV"]);
    lockRollArm.setIntValue(rollArmModes["OFF"]);
  }
}


revArmFromRol = func
{
  ##
  # Abort the REV-ARM mode if something has changed the arm mode to something
  # else than REV-ARM.
  ##
  if (lockRollArm.getValue() != rollArmModes["REV"])
  {
    annunciatorRevArm.setBoolValue(0);
    return;
  }

  #annunciatorRevArm.setBoolValue(1);
  ##
  # Wait for the HDG annunciator flashing to finish.
  ##
  if (flashTimer > -0.5)
  {
    #print("flashing...");
    annunciatorRol.setBoolValue(0);
    settimer(revArmFromRol, 2.5);
    return;
  }
  ##
  # Turn the ROL annunciator back on and activate the ROL mode.
  ##
  annunciatorRol.setBoolValue(1);
  lockRollAxis.setBoolValue(1);
  settingTargetTurnRate.setDoubleValue(0.0);
  deviation = getprop(navRadio, "heading-needle-deflection");
  ##
  # If the deflection is more than 3 degrees wait 5 seconds and check again.
  ##
  if (abs(deviation) > 3.0)
  {
    #print("deviation");
    settimer(revArmFromRol, 5);
    return;
  }
  ##
  # If the deviation is less than 3 degrees turn of the REV-ARM annunciator
  # and show the REV annunciator. End of REV-ARM sequence.
  ##
  elsif (abs(deviation) < 3.1)
  {
    #print("capture");
    annunciatorRol.setBoolValue(0);
    annunciatorRevArm.setBoolValue(0);
    annunciatorRev.setBoolValue(1);

    lockAprHold.setBoolValue(0);
    lockGsHold.setBoolValue(0);
    lockRevHold.setBoolValue(1);
    lockHdgHold.setBoolValue(1);
    lockNavHold.setBoolValue(0);
    lockRollAxis.setBoolValue(1);
    lockRollMode.setIntValue(rollModes["REV"]);
    lockRollArm.setIntValue(rollArmModes["OFF"]);
  }
}


altButtonTimer = func {
  #print("alt button timer");
  #print(altButtonTimerIgnore);

  if (altButtonTimerIgnore == 0)
  {
      annunciatorVsNumber.setBoolValue(0);
      annunciatorAltNumber.setBoolValue(1);

      altButtonTimerRunning = 0;
  }
  elsif (altButtonTimerIgnore > 0)
  {
      altButtonTimerIgnore = altButtonTimerIgnore - 1;
  }
}


altButton = func {
  ##print("altButton");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }


  if (lockPitchMode.getValue() == pitchModes["ALT"])
  {
    if (altButtonTimerRunning == 0)
    {
      settimer(altButtonTimer, 3.0);
      altButtonTimerRunning = 1;
      altButtonTimerIgnore = 0;
    }
    lockAltHold.setBoolValue(0);

    lockPitchAxis.setBoolValue(1);
    lockPitchMode.setIntValue(pitchModes["VS"]);

    annunciatorAlt.setBoolValue(0);
    annunciatorAltNumber.setBoolValue(0);
    annunciatorVs.setBoolValue(1);
    annunciatorVsNumber.setBoolValue(1);

    pressureRate = getprop(internal, "pressure-rate");
    fpm = -pressureRate * 58000;
    #print(fpm);
    if (fpm > 0.0)
    {
      fpm = int(fpm/100 + 0.5) * 100;
    }
    else
    {
      fpm = int(fpm/100 - 0.5) * 100;
    }
    #print(fpm);

    settingTargetPressureRate.setDoubleValue(-fpm / 58000);

  }
  elsif (lockPitchMode.getValue() == pitchModes["VS"])
  {
    lockAltHold.setBoolValue(1);
    lockPitchAxis.setBoolValue(1);
    lockPitchMode.setIntValue(pitchModes["ALT"]);

    annunciatorAlt.setBoolValue(1);
    annunciatorVs.setBoolValue(0);
    annunciatorVsNumber.setBoolValue(0);
    annunciatorAltNumber.setBoolValue(1);

    altPressure = getprop(staticPort, "pressure-inhg");
    altFt = (baroSettingInhg - altPressure) / 0.00103;
    if (altFt > 0.0)
    {
      altFt = int(altFt/20 + 0.5) * 20;
    }
    else
    {
      altFt = int(altFt/20 - 0.5) * 20;
    }
    #print(altFt);

    altPressure = baroSettingInhg - altFt * 0.00103;
    settingTargetAltPressure.setDoubleValue(altPressure);

  }
}


downButton = func {
  ##print("downButton");#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  if (baroTimerRunning == 0)
  {
    if (lockPitchMode.getValue() == pitchModes["VS"])
    {
      if (altButtonTimerRunning == 0)
      {
        settimer(altButtonTimer, 3.0);
        altButtonTimerRunning = 1;
        altButtonTimerIgnore = 0;
      }
      elsif (altButtonTimerRunning == 1)
      {
          settimer(altButtonTimer, 3.0);
          altButtonTimerIgnore = altButtonTimerIgnore + 1;
      }
      targetVS = getprop(settings, "target-pressure-rate");
      settingTargetPressureRate.setDoubleValue(targetVS +
                                               0.0017241379310345);
      annunciatorAltNumber.setBoolValue(0);
      annunciatorVsNumber.setBoolValue(1);
    }
    elsif (lockPitchMode.getValue() == pitchModes["ALT"])
    {
      targetPressure = getprop(settings, "target-alt-pressure");
      settingTargetAltPressure.setDoubleValue(targetPressure + 0.0206);
    }
  }
}

upButton = func {
  ##print("upButton");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  if (baroTimerRunning == 0)
  {
    if (lockPitchMode.getValue() == pitchModes["VS"])
    {
      if (altButtonTimerRunning == 0)
      {
        settimer(altButtonTimer, 3.0);
        altButtonTimerRunning = 1;
        altButtonTimerIgnore = 0;
      }
      elsif (altButtonTimerRunning == 1)
      {
          settimer(altButtonTimer, 3.0);
          altButtonTimerIgnore = altButtonTimerIgnore + 1;
      }
      targetVS = getprop(settings, "target-pressure-rate");
      settingTargetPressureRate.setDoubleValue(targetVS -
                                               0.0017241379310345);
      annunciatorAltNumber.setBoolValue(0);
      annunciatorVsNumber.setBoolValue(1);
    }
    elsif (lockPitchMode.getValue() == pitchModes["ALT"])
    {
      targetPressure = getprop(settings, "target-alt-pressure");
      settingTargetAltPressure.setDoubleValue(targetPressure - 0.0206);
    }
  }
}

armButton = func {
  #print("arm button");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  pitchArm = lockPitchArm.getValue();

  if (pitchArm == pitchArmModes["OFF"])
  {
    lockPitchArm.setIntValue(pitchArmModes["ALT"]);

    annunciatorAltArm.setBoolValue(1);
  }
  elsif (pitchArm == pitchArmModes["ALT"])
  {
    lockPitchArm.setIntValue(pitchArmModes["OFF"]);

    annunciatorAltArm.setBoolValue(0);
  }
}


baroButtonTimer = func {
  #print("baro button timer");

  baroTimerRunning = 0;
  if (baroButtonDown == 1)
  {
    baroSettingUnit = !baroSettingUnit;
    baroButtonDown = 0;
    baroButtonPress();
  }
  elsif (baroButtonDown == 0 and
         baroSettingAdjusting == 0)
  {
    annunciatorBsHpaNumber.setBoolValue(0);
    annunciatorBsInhgNumber.setBoolValue(0);
    annunciatorAltNumber.setBoolValue(1);
  }
  elsif (baroSettingAdjusting == 1)
  {
    baroTimerRunning = 1;
    baroSettingAdjusting = 0;
    settimer(baroButtonTimer, 3.0);
  }
}

baroButtonPress = func {
  #print("baro putton press");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  if (baroButtonDown == 0 and
      baroTimerRunning == 0 and
      altButtonTimerRunning == 0)
  {
    baroButtonDown = 1;
    baroTimerRunning = 1;
    settimer(baroButtonTimer, 3.0);
    annunciatorAltNumber.setBoolValue(0);

    if (baroSettingUnit == pressureUnits["inHg"])
    {
      settingBaroSettingInhg.setDoubleValue(baroSettingInhg);

      annunciatorBsInhgNumber.setBoolValue(1);
      annunciatorBsHpaNumber.setBoolValue(0);
    }
    elsif (baroSettingUnit == pressureUnits["hPa"])
    {
      settingBaroSettingHpa.setDoubleValue(
              baroSettingInhg * 0.03386389);

      annunciatorBsHpaNumber.setBoolValue(1);
      annunciatorBsInhgNumber.setBoolValue(0);
    }
  }
}


baroButtonRelease = func {
  #print("baro button release");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  baroButtonDown = 0;
}


pow = func {
  #print(arg[0],arg[1]);
  return math.exp(arg[1]*math.ln(arg[0]));
}


pressureToHeight = func {
  p0 = arg[1];    # [Pa]
  p = arg[0];     # [Pa]
  t0 = 288.15;    # [K]
  LR = -0.0065;    # [K/m]
  g = -9.80665;    # [m/s²]
  Rd = 287.05307; # [J/kg K]

  z = -(t0/LR) * (1.0-pow((p/p0),((Rd*LR)/g)));
  return z;
}


heightToPressure = func {
  p0 = arg[1];    # [Pa]
  z = arg[0];     # [m]
  t0 = 288.15;    # [K]
  LR = -0.0065;    # [K/m]
  g = -9.80665;    # [m/s²]
  Rd = 287.05307; # [J/kg K]

  p = p0 * pow(((t0+LR*z)/t0),(g/(Rd*LR)));
  return p;
}

hPartial = func {
  p0 = arg[1];    # Units of p0 must match units of delta p
  p = arg[0];     # Units of p must match units of delta p
  t0 = 288.15;    # [K]
  LR = -0.0065;    # [K/m]
  g = -9.80665;    # [m/s²]
  Rd = 287.05307; # [J/kg K]
  gamma = (Rd*LR)/g;

  z = -(t0/LR)*gamma*pow((p/p0),gamma)/p0;
  return z;
}

altAlert = func {
  #print("alt alert");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  pressureAltitude = getprop(encoder, "pressure-alt-ft");
  altPressure = getprop(staticPort, "pressure-inhg");
  hPartStat = hPartial(altPressure, 29.92) / 0.3048006;
  altFt = pressureAltitude + hPartStat * (baroSettingInhg - 29.92);
  altDifference = abs(altPreselect - altFt);
  #print(altDifference);

  if (altDifference > 1000)
  {
    annunciatorAltAlert.setBoolValue(0);
  }
  elsif (altDifference < 1000 and
         altCaptured == 0)
  {
    if (flashTimer < -0.5) {
      annunciatorAltAlert.setBoolValue(1); }
    if (altDifference < 200)
    {
      if (flashTimer < -0.5) {
        annunciatorAltAlert.setBoolValue(0); }
      if (altDifference < 20)
      {
        #print("altCapture()");
        altCaptured = 1;

        if (lockPitchArm.getValue() == pitchArmModes["ALT"])
        {
          lockAltHold.setBoolValue(1);
          lockPitchAxis.setBoolValue(1);
          lockPitchMode.setIntValue(pitchModes["ALT"]);
          lockPitchArm.setIntValue(pitchArmModes["OFF"]);

          annunciatorAlt.setBoolValue(1);
          annunciatorAltArm.setBoolValue(0);
          annunciatorVs.setBoolValue(0);
          annunciatorVsNumber.setBoolValue(0);
          annunciatorAltNumber.setBoolValue(1);

          #altPressure = baroSettingInhg - altPreselect * 0.00103;
          #altPressure = heightToPressure(altPreselect*0.3048006,
          #                                baroSettingInhg*3386.389)/3386.389;
          altPressure = getprop(staticPort, "pressure-inhg");
          settingTargetAltPressure.setDoubleValue(altPressure);
        }

        flasher(annunciatorAltAlert, 1.0, 0, 0);
      }
    }
  }
  elsif (altDifference < 1000 and
         altCaptured == 1)
  {
    if (altDifference > 200)
    {
      flasher(annunciatorAltAlert, 1.0, 5, 1);
      altCaptured = 0;
    }
  }
  settimer(altAlert, 2.0);
}


knobSmallUp = func {
  #print("knob small up");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  if (baroTimerRunning == 1)
  {
    baroSettingAdjusting = 1;
    if (baroSettingUnit == pressureUnits["inHg"])
    {
      baroSettingInhg = baroSettingInhg + 0.01;
      baroSettingHpa = baroSettingInhg * 0.03386389;

      settingBaroSettingInhg.setDoubleValue(baroSettingInhg);
    }
    elsif (baroSettingUnit == pressureUnits["hPa"])
    {
      baroSettingHpa = baroSettingInhg * 0.03386389;
      baroSettingHpa = baroSettingHpa + 0.001;
      baroSettingInhg = baroSettingHpa / 0.03386389;

      settingBaroSettingHpa.setDoubleValue(baroSettingHpa);
    }
  }
  elsif (baroTimerRunning == 0 and
         altButtonTimerRunning == 0)
  {
    altCaptured = 0;
    altPreselect = altPreselect + 20;
    settingTargetAltFt.setDoubleValue(altPreselect);

    if (lockRollMode.getValue() == rollModes["OFF"] and
        lockPitchMode.getValue() == pitchModes["OFF"])
    {
      annunciatorAltNumber.setBoolValue(1);
      if (altAlertOn == 0)
      {
        altAlertOn = 1;
      }
    }
    elsif (lockPitchArm.getValue() == pitchArmModes["OFF"])
    {
      lockPitchArm.setIntValue(pitchArmModes["ALT"]);
      annunciatorAltArm.setBoolValue(1);
    }
  }
}


knobLargeUp = func {
  #print("knob large up");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  if (baroTimerRunning == 1)
  {
    baroSettingAdjusting = 1;
    if (baroSettingUnit == pressureUnits["inHg"])
    {
      baroSettingInhg = baroSettingInhg + 1.0;
      baroSettingHpa = baroSettingInhg * 0.03386389;

      settingBaroSettingInhg.setDoubleValue(baroSettingInhg);
    }
    elsif (baroSettingUnit == pressureUnits["hPa"])
    {
      baroSettingHpa = baroSettingInhg * 0.03386389;
      baroSettingHpa = baroSettingHpa + 0.1;
      baroSettingInhg = baroSettingHpa / 0.03386389;

      settingBaroSettingHpa.setDoubleValue(baroSettingHpa);
    }
  }
  elsif (baroTimerRunning == 0 and
         altButtonTimerRunning == 0)
  {
    altCaptured = 0;
    altPreselect = altPreselect + 100;
    settingTargetAltFt.setDoubleValue(altPreselect);

    if (lockRollMode.getValue() == rollModes["OFF"] and
        lockPitchMode.getValue() == pitchModes["OFF"])
    {
      annunciatorAltNumber.setBoolValue(1);
      if (altAlertOn == 0)
      {
        altAlertOn = 1;
      }
    }
    elsif (lockPitchArm.getValue() == pitchArmModes["OFF"])
    {
      lockPitchArm.setIntValue(pitchArmModes["ALT"]);
      annunciatorAltArm.setBoolValue(1);
    }
  }
}


knobSmallDown = func {
  #print("knob small down");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  if (baroTimerRunning == 1)
  {
    baroSettingAdjusting = 1;
    if (baroSettingUnit == pressureUnits["inHg"])
    {
      baroSettingInhg = baroSettingInhg - 0.01;
      baroSettingHpa = baroSettingInhg * 0.03386389;

      settingBaroSettingInhg.setDoubleValue(baroSettingInhg);
    }
    elsif (baroSettingUnit == pressureUnits["hPa"])
    {
      baroSettingHpa = baroSettingInhg * 0.03386389;
      baroSettingHpa = baroSettingHpa - 0.001;
      baroSettingInhg = baroSettingHpa / 0.03386389;

      settingBaroSettingHpa.setDoubleValue(baroSettingHpa);
    }
  }
  elsif (baroTimerRunning == 0 and
         altButtonTimerRunning == 0)
  {
    altCaptured = 0;
    altPreselect = altPreselect - 20;
    settingTargetAltFt.setDoubleValue(altPreselect);

    if (lockRollMode.getValue() == rollModes["OFF"] and
        lockPitchMode.getValue() == pitchModes["OFF"])
    {
      annunciatorAltNumber.setBoolValue(1);
      if (altAlertOn == 0)
      {
        altAlertOn = 1;
      }
    }
    elsif (lockPitchArm.getValue() == pitchArmModes["OFF"])
    {
      lockPitchArm.setIntValue(pitchArmModes["ALT"]);
      annunciatorAltArm.setBoolValue(1);
    }
  }
}


knobLargeDown = func {
  #print("knob large down");
#  Disable button if too little power
  if (getprop(power) < minVoltageLimit) { return; }

  if (baroTimerRunning == 1)
  {
    baroSettingAdjusting = 1;
    if (baroSettingUnit == pressureUnits["inHg"])
    {
      baroSettingInhg = baroSettingInhg - 1.0;
      baroSettingHpa = baroSettingInhg * 0.03386389;

      settingBaroSettingInhg.setDoubleValue(baroSettingInhg);
    }
    elsif (baroSettingUnit == pressureUnits["hPa"])
    {
      baroSettingHpa = baroSettingInhg * 0.03386389;
      baroSettingHpa = baroSettingHpa - 0.1;
      baroSettingInhg = baroSettingHpa / 0.03386389;

      settingBaroSettingHpa.setDoubleValue(baroSettingHpa);
    }
  }
  elsif (baroTimerRunning == 0 and
         altButtonTimerRunning == 0)
  {
    altCaptured = 0;
    altPreselect = altPreselect - 100;
    settingTargetAltFt.setDoubleValue(altPreselect);

    if (lockRollMode.getValue() == rollModes["OFF"] and
        lockPitchMode.getValue() == pitchModes["OFF"])
    {
      annunciatorAltNumber.setBoolValue(1);
      if (altAlertOn == 0)
      {
        altAlertOn = 1;
      }
    }
    elsif (lockPitchArm.getValue() == pitchArmModes["OFF"])
    {
      lockPitchArm.setIntValue(pitchArmModes["ALT"]);
      annunciatorAltArm.setBoolValue(1);
    }
  }
}

var L = setlistener(power, func {
  apPower();
  removelistener(L);
});


