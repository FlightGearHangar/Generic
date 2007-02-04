# Properties under /consumables/fuel/tank[n]:
# + level-gal_us    - Current fuel load.  Can be set by user code.
# + level-lbs       - OUTPUT ONLY property, do not try to set
# + selected        - boolean indicating tank selection.
# + density-ppg     - Fuel density, in lbs/gallon.
# + capacity-gal_us - Tank capacity
#
# Properties under /engines/engine[n]:
# + fuel-consumed-lbs - Output from the FDM, zeroed by this script
# + out-of-fuel       - boolean, set by this code.


var UPDATE_PERIOD = 0.3;

var enabled = nil;
var fuel_freeze = nil;
var ai_enabled = nil;
var engines = nil;
var tanks = nil;
var refuelingN = nil;
var aimodelsN = nil;



# initialize property if it doesn't exist, and set node type otherwise
init_prop = func(node, prop, val, type = "double") {
	var n = node.getNode(prop);
	if (n != nil) {
		var v = n.getValue();
		if (v != nil) {
			val = v;
		}
	}
	node = node.getNode(prop, 1);
	if (type == "double") {
		node.setDoubleValue(val);
	} elsif (type == "bool") {
		node.setBoolValue(val);
	} elsif (type == "int") {
		node.setIntValue(val);
	}
}



update_loop = func {
	# check for contact with tanker aircraft
	var tankers = [];
	if (ai_enabled) {
		var ac = aimodelsN.getChildren("aircraft");
		foreach (var mp; aimodelsN.getChildren("multiplayer")) {
			append(ac, mp);
		}

		foreach (var a; ac) {
			var contact = a.getNode("refuel/contact", 1).getValue();
			var tanker = a.getNode("tanker", 1).getValue();

			if (tanker != nil and contact != nil and tanker and contact) {
				append(tankers, a);
			}
		}
	}

	var refueling = size(tankers) > 0;
	refuelingN.setBoolValue(refueling);

	if (fuel_freeze) {
		return settimer(update_loop, UPDATE_PERIOD);
	}


	# sum up consumed fuel
	var consumed = 0;
	foreach (var e; engines) {
		var fuel = e.getNode("fuel-consumed-lbs");
		consumed += fuel.getValue();
		fuel.setDoubleValue(0);
	}



	# calculate fuel received
	if (refueling) {
		# assume max flow rate is 6000 lbs/min (for KC135)
		var received = 100 * UPDATE_PERIOD;
		consumed -= received;
	}


	# make list of selected tanks
	var selected_tanks = [];
	foreach (var t; tanks) {
		var cap = t.getNode("capacity-gal_us", 1).getValue();
		if (cap != nil and cap > 0.01 and t.getNode("selected", 1).getBoolValue()) {
			append(selected_tanks, t);
		}
	}


	var out_of_fuel = 0;
	if (size(selected_tanks) == 0 or !consumed) {
		out_of_fuel = 1;

	} elsif (consumed > 0) {
		var fuel_per_tank = consumed / size(selected_tanks);
		foreach (var t; selected_tanks) {
			var ppg = t.getNode("density-ppg").getValue();
			var lbs = t.getNode("level-gal_us").getValue() * ppg;
			lbs -= fuel_per_tank;

			if (lbs < 0) {
				lbs = 0;
				# Kill the engines if we're told to, otherwise simply
				# deselect the tank.
				if (t.getNode("kill-when-empty", 1).getBoolValue()) {
					out_of_fuel = 1;
				} else {
					t.getNode("selected", 1).setBoolValue(0);
				}
			}

			var gals = lbs / ppg;
			t.getNode("level-gal_us").setDoubleValue(gals);
			t.getNode("level-lbs").setDoubleValue(lbs);
		}

	} elsif (consumed < 0) {
		#find the number of tanks which can accept fuel
		var available = 0;

		foreach (var t; selected_tanks) {
			var ppg = t.getNode("density-ppg").getValue();
			var capacity = t.getNode("capacity-gal_us").getValue() * ppg;
			var lbs = t.getNode("level-gal_us").getValue() * ppg;

			if (lbs < capacity) {
				available += 1;
			}
		}

		if (available > 0) {
			var fuel_per_tank = consumed / available;

			# add fuel to each available tank
			foreach (var t; selected_tanks) {
				var ppg = t.getNode("density-ppg").getValue();
				var capacity = t.getNode("capacity-gal_us").getValue() * ppg;
				var lbs = t.getNode("level-gal_us").getValue() * ppg;

				if (capacity - lbs >= fuel_per_tank) {
					lbs -= fuel_per_tank;
				} elsif (capacity - lbs < fuel_per_tank) {
					lbs = capacity;
				}

				t.getNode("level-gal_us").setDoubleValue(lbs / ppg);
				t.getNode("level-lbs").setDoubleValue(lbs);
			}

			# print ("available ", available , " fuel_per_tank " , fuel_per_tank);
		}
	}


	var gals = 0;
	var lbs = 0;
	var cap = 0;
	foreach (var t; tanks) {
		gals += t.getNode("level-gal_us", 1).getValue();
		lbs += t.getNode("level-lbs", 1).getValue();
		cap += t.getNode("capacity-gal_us", 1).getValue();
	}

	setprop("/consumables/fuel/total-fuel-gals", gals);
	setprop("/consumables/fuel/total-fuel-lbs", lbs);
	setprop("/consumables/fuel/total-fuel-norm", gals / cap);

	foreach (var e; engines) {
		e.getNode("out-of-fuel", 1).setBoolValue(out_of_fuel);
	}
	settimer(update_loop, UPDATE_PERIOD);
}



setlistener("/sim/signals/fdm-initialized", func {
	if (contains(globals, "fuel") and typeof(fuel) == "hash") {
		fuel.loop = func {}	# kill $FG_ROOT/Nasal/fuel.nas' loop
	}

	refuelingN = props.globals.getNode("/systems/refuel/contact", 1);
	refuelingN.setBoolValue(0);

	aimodelsN = props.globals.getNode("ai/models", 1);
	engines = props.globals.getNode("engines", 1).getChildren("engine");
	tanks = props.globals.getNode("consumables/fuel", 1).getChildren("tank");

	foreach (var e; engines) {
		e.getNode("fuel-consumed-lbs", 1).setDoubleValue(0);
		e.getNode("out-of-fuel", 1).setBoolValue(0);
	}

	foreach (var t; tanks) {
		init_prop(t, "level-gal_us", 0);
		init_prop(t, "level-lbs", 0);
		init_prop(t, "capacity-gal_us", 0.01); # Not zero (div/zero issue)
		init_prop(t, "density-ppg", 6.0);      # gasoline
		init_prop(t, "selected", 1, "bool");
	}

	setlistener("sim/freeze/fuel", func { fuel_freeze = cmdarg().getBoolValue() }, 1);
	setlistener("sim/ai/enabled", func { ai_enabled = cmdarg().getBoolValue() }, 1);
	update_loop();
});


