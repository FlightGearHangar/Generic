# $Id$

#
# Nasal script to print errors to the screen when aircraft exceed design limits:
#  - extending flaps above maximum flap extension speed
#  - extending gear above maximum gear extension speed
#  - exceeding Vna
#  - exceeding structural G limits
#
#
# to use, define one or more of 
# limits/max-flap-extension-speed
# limits/vne
# limits/max-gear-extension-speed
# limits/max-positive-g
# limits/max-negative-g (must be defined in max-positive-g defined)
#
# then include this .nas file in the aircraft XML. Note that .nas file must be
# included _after_ limits have been defined.
#


# ==================================== timer stuff ===========================================

# set the update period

UPDATE_PERIOD = 0.3;

# set the timer for the selected function

registerTimer = func {
	
    settimer(arg[0], UPDATE_PERIOD);

} # end function 

# =============================== end timer stuff ===========================================

# =============================== Pilot G stuff (taken from hurricane.nas) =================================

pilot_g = props.globals.getNode("fdm/jsbsim/accelerations/a-pilot-z-ft_sec2", 1);
timeratio = props.globals.getNode("accelerations/timeratio", 1);
pilot_g_damped = props.globals.getNode("fdm/jsbsim/accelerations/damped-a-pilot-z-ft_sec2", 1);
pilot_g.setDoubleValue(0);
pilot_g_damped.setDoubleValue(0); 
timeratio.setDoubleValue(0.03); 

g_damp = 0;

updatePilotG = func {
        var n = timeratio.getValue(); 
	var g = pilot_g.getValue() ;
	#if (g == nil) { g = 0; }
	g_damp = ( g * n) + (g_damp * (1 - n));

	pilot_g_damped.setDoubleValue(g_damp);

        settimer(updatePilotG, 0.1);

} #end updatePilotG()

updatePilotG();

# ======================= Load/Speed limits =========================

if ((getprop("limits/max-flap-extension-speed") != nil) or
    (getprop("limits/vne") != nil) or
    (getprop("limits/max-gear-extension-speed") != nil) or
    (getprop("limits/max-positive-g") != nil))
{
  setprop("/accelerations/pilot/z-accel-fps_sec",0);
  
  checkLimits = func {

    # Flaps extension speed check
    if (getprop("limits/max-flap-extension-speed") != nil)
    {
      if ((getprop("surface-positions/flap-pos-norm") > 0)    and
          (getprop("velocities/airspeed-kt") > getprop("limits/max-flap-extension-speed")) and
	  (getprop("limits/flap-warning-displayed") != 1))
      {
        # display a warning once
        screenPrint("Flaps extended above maximum flap extension speed!");
	setprop("limits/flap-warning-displayed", 1);	
      }
      
      if ((getprop("surface-positions/flap-pos-norm") == 0)    or
          (getprop("velocities/airspeed-kt") < getprop("limits/max-flap-extension-speed")))
      {
        #reset warning message
	setprop("limits/flap-warning-displayed", 0);	      
      }
    }

    # G-loads check - both limits must be defined
    if (getprop("limits/max-positive-g") != nil)
    {
      # Convert the ft/sec^2 into Gs - allowing for gravity.
      g = (- getprop("/fdm/jsbsim/accelerations/damped-a-pilot-z-ft_sec2")) / 32;
      
      setprop("limits/current-g", g);

      if (g < getprop("limits/max-negative-g"))
      {
	screenPrint("Airframe structural negative-g load limit exceeded!");
      }

      if (g > getprop("limits/max-positive-g"))
      {
	screenPrint("Airframe structural positive-g load limit exceeded!");
      }
    }

    # Vne speed check
    if (getprop("limits/vne") != nil)
    {
      # Simply check we haven't exceeded the maximum speed for the aircraft
      if (getprop("velocities/airspeed-kt") > getprop("limits/vne"))
      {
	screenPrint("Airspeed exceeds Vne!");
      }
    }
    
    # Gear extension speed check. We check whether the gear is being extended or retracted.
    if (getprop("limits/max-gear-extension-speed") != nil)
    {
      if ((getprop("gear/gear[0]/position-norm") != getprop("/controls/gear/gear-down"))    and
          (getprop("velocities/airspeed-kt") > getprop("limits/max-gear-extension-speed")) and
	  (getprop("limits/gear-warning-displayed") != 1))
      {
        # display a warning once
        screenPrint("Gear extended above maximum gear extension speed!");
	setprop("limits/gear-warning-displayed", 1);	
      }
      
      if ((getprop("gear/gear[0]/position-norm") == getprop("/controls/gear/gear-down"))    or
          (getprop("velocities/airspeed-kt") < getprop("limits/max-gear-extension-speed")))
      {
        #reset warning message
	setprop("limits/gear-warning-displayed", 0);	      
      }
    }
    
    registerTimer(checkLimits);
  }  
}

checkLimits();


