# $Id$
#
# Nasal script to print errors to the screen when aircraft exceed design limits:
#  - extending flaps above maximum flap extension speed(s)
#  - extending gear above maximum gear extension speed
#  - exceeding Vna
#  - exceeding structural G limits
#
# To use, include this .nas file and define one or more of
# limits/max-flap-extension-speed/speed
# limits/max-flap-extension-speed/flaps
# limits/vne
# limits/max-gear-extension-speed
# limits/max-positive-g
# limits/max-negative-g (must be defined in max-positive-g defined)
#
# You can define multiple max-flap-extension-speed entries for max extension
# speeds for different flap settings.

checkFlaps = func {
  flapsetting = cmdarg().getValue();
  if (flapsetting == 0)
    return;

  airspeed = getprop("velocities/airspeed-kt");
  ltext = "";

  limits = props.globals.getNode("limits");

  if ((limits != nil) and (limits.getChildren("max-flap-extension-speed") != nil))
  {
    children = limits.getChildren("max-flap-extension-speed");
    foreach(c; children)
    {
      if ((c.getChild("flaps") != nil) and
          (c.getChild("speed") != nil)     )
      {
        flaps = c.getChild("flaps").getValue();
        speed = c.getChild("speed").getValue();

        if ((flaps != nil)        and
            (speed != nil)        and
            (flapsetting > flaps) and
            (airspeed > speed)       )
        {
          ltext = "Flaps extended above maximum flap extension speed!";
        }
      }
    }

    if (ltext != "")
    {
      screen.log.write(ltext);
    }
  }
}


checkGear = func {
  if (!cmdarg().getValue())
    return;

  airspeed = getprop("velocities/airspeed-kt");
  max_gear = getprop("limits/max-gear-extension-speed");

  if ((max_gear != nil) and (airspeed > max_gear))
  {
    screen.log.write("Gear extended above maximum extension speed!");
  }
}


# Set the listeners
setlistener("controls/flight/flaps", checkFlaps);
setlistener("controls/gear/gear-down", checkGear);

# =============================== Pilot G stuff (taken from hurricane.nas) =================================
pilot_g = props.globals.getNode("fdm/jsbsim/accelerations/a-pilot-z-ft_sec2", 1);
pilot_g.setDoubleValue(0);

var g_damp = 0;

updatePilotG = func {
  var g = pilot_g.getValue() ;
  #if (g == nil) { g = 0; }
  g_damp = ( g * 0.2) + (g_damp * 0.8);

  settimer(updatePilotG, 0.2);
}

updatePilotG();

checkGandVNE = func {
  if (getprop("/sim/freeze/replay-state"))
    return;

  max_positive = getprop("limits/max-positive-g");
  max_negative = getprop("limits/max-negative-g");
  msg = "";

  # Convert the ft/sec^2 into Gs - allowing for gravity.
  g = (- g_damp) / 32;

  if ((max_positive != nil) and (g > max_positive))
  {
    msg = "Airframe structural positive-g load limit exceeded!";
  }

  if ((max_negative != nil) and (g < max_negative))
  {
    msg = "Airframe structural negative-g load limit exceeded!";
  }

  # Now check VNE
  airspeed = getprop("velocities/airspeed-kt");
  vne      = getprop("limits/vne");

  if ((airspeed != nil) and (vne != nil) and (airspeed > vne))
  {
    msg = "Airspeed exceeds Vne!";
  }

  if (msg != "")
  {
    # If we have a message, display it, but don't bother checking for
    # any other errors for 10 seconds. Otherwise we're likely to get
    # repeated messages.
    screen.log.write(msg);
    settimer(checkGandVNE, 10);
  }
  else
  {
    settimer(checkGandVNE, 1);
  }
}

checkGandVNE();
