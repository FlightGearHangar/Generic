### Radar Visibility Calculator

# Jettoo (glazmax) and xiii (Alexis)

# my_maxrange(myaircraft): finds our own aircraft max radar range in a table.
# Returns my_radarcorr in kilometers, should be called from your own aircraft
# radar stuff.

# radis(i, my_radarcorr): find multiplayer[i], its Radar Cross Section (RCS),
# applies factor upon our altitude, shorter radar detection distance (due to air
# turbulence), then factor upon its altitude above ground, and finaly computes if
# it is detectable given our radar range.
# Returns 1 if detectable, 0 if not. Should be called from your own aircraft
# radar stuff too.


var data_path   = getprop("/sim/fg-root") ~ "/Aircraft/Generic/radardist.xml";
var aircraftData = {};
var radarData    = [];

var FT2M = 0.3048;
var NM2KM = 1.852;


var my_maxrange = func(myaircraft) {
	var myacname = aircraftData[myaircraft] or 0;
	var my_radar_area = radarData[myacname][7];
	var my_radar_range = radarData[myacname][5];
	#print ("aircraft = " ~ radarData[myacname][1]);
	#print ("range = " ~ radarData[myacname][5]);
	#print ("aera = " ~ radarData[myacname][7]);
	return( my_radar_range / my_radar_area);
}



var radis = func(t, my_radarcorr) {
	# Get the multiplayer aircraft name.
	var mpnode_string = t;
	var mpnode =  props.globals.getNode(mpnode_string);
	if ( find("tanker", mpnode_string) > 0 ) {
		#print("tanker");
		var cutname = "KC135";
	} else {
		var mpname_node_string = mpnode_string ~ "/sim/model/path";
		var mpname_node = props.globals.getNode(mpname_node_string);
		#print(mpname_node_string);
		if (mpname_node == nil) { return(0) }

		var mpname = mpname_node.getValue();
		if (mpname == nil) { return(0) }

		var splitname = split("/", mpname);
		var cutname = splitname[1];
	}
	# Calculate the rcs detection range,
	# if aircraft is not found in list, 0 (generic) will be used.
	var acname = aircraftData[cutname];
	if ( acname == nil ) { acname = 0 }
	var rcs_4r = radarData[acname][3];
	var radartype = radarData[acname][1];

	# Add a correction factor for altitude, as lower alt means
	# shorter radar distance (due to air turbulence).
	var alt_corr = 1;
	var alt_ac = mpnode.getNode("position/altitude-ft").getValue();
	if (alt_ac <= 1000) {
		alt_corr = 0.6;
	} elsif ((alt_ac > 1000) and (alt_ac <= 5000)) {
		alt_corr = 0.8;
	}

	# Add a correction factor for altitude AGL.
	var agl_corr = 1;
	var mp_lon = mpnode.getNode("position/longitude-deg").getValue();
	var mp_lat = mpnode.getNode("position/latitude-deg").getValue();
	var mp_pos = geo.Coord.new().set_latlon(mp_lat, mp_lon);
	var pos_elev = geo.elevation(mp_pos.lat(), mp_pos.lon());
	if (pos_elev != nil) {
		#print("pos_elev: " ~ pos_elev);
		var mp_agl = alt_ac - ( pos_elev / FT2M );
		if (mp_agl <= 20) {
			agl_corr = 0.03;
		} elsif ((mp_agl > 20) and (mp_agl <= 50)) {
			agl_corr = 0.08;
		} elsif ((mp_agl > 50) and (mp_agl <= 120)) {
			agl_corr = 0.25;
		} elsif ((mp_agl > 120) and (mp_agl <= 300)) {
			agl_corr = 0.4;
		} elsif ((mp_agl > 300) and (mp_agl <= 600)) {
			agl_corr = 0.7;
		} elsif ((mp_agl > 600) and (mp_agl <= 1000)) {
			agl_corr = 0.85;
		}
	}

	# Calculate the detection distance for this multiplayer.
	var det_range = my_radarcorr * rcs_4r * alt_corr * agl_corr / NM2KM;
	#print (radartype);
	#print (rcs_4r);

	### Compare if aircraft is in detection range and return.
	var act_range = mpnode.getNode("radar/range-nm").getValue() or 500;
	#print (det_range ~ " " ~ act_range);
	if (det_range >= act_range) {
		#print("paint it");
		return(1);
	}
	return(0);
}


var load_data = func {
	# a) converts aircraft model name to lookup (index) number in aircraftData{}.
	# b) appends ordered list of data into radarData[],
	# data is:
	# - acname (the index number)
	# - the first (if several) aircraft model name corresponding to this type,
	# - RCS(m2),
	# - 4th root of RCS,
	# - radar type,
	# - max. radar range(km),
	# - max. radar range target seize(RCS)m2,
	# - 4th root of radar RCS.
	var data_node = props.globals.getNode("instrumentation/radar-performance/data");
	var aircraft_types = data_node.getChildren();
	foreach( var t; aircraft_types ) {
		var index = t.getIndex();
		var aircraft_names = t.getChildren();
		foreach( var n; aircraft_names) {
			if ( n.getName() == "name") {
				aircraftData[n.getValue()] = index;
				#print(n.getValue() ~ " : " ~ index);
			}
		}
		var t_list = [
			index,
			t.getNode("name[0]").getValue(),
			t.getNode("rcs-sq-meter").getValue(),
			t.getNode("rcs-4th-root").getValue(),
			t.getNode("radar-type").getValue(),
			t.getNode("max-radar-rng-km").getValue(),
			t.getNode("max-target-sq-meter").getValue(),
			t.getNode("max-target-4th-root").getValue()
		];
		append(radarData, t_list);
	}
}


var init = func {
	print("Initializing Radar Data");
	io.read_properties(data_path, props.globals);
	load_data();
}




