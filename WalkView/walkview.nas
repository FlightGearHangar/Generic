###############################################################################
##
##  Walk view module for FlightGear.
##
##  Inspired by the work of Stewart Andreason.
##
##  Copyright (C) 2010  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license v2 or later.
##
###############################################################################

# Global API. Automatically selects the right walker for the current view.

# NOTE: Coordinates are always 3 component lists: [x, y, z] in meters.
# The coordinate system is the same as the main 3d model one.
# X - back, Y - right and Z - up.

# Set the forward speed of the active walker.
#   speed - walker speed in m/sec
#   Returns 1 of there is an active walker and 0 otherwise.
var forward = func (speed) {
    var cv = view.current.getPath();
    if (contains(walkers, cv)) {
        walkers[cv].forward(speed);
        return 1;
    } else {
        return 0;
    }
}

# Set the side step speed of the active walker.
#   speed - walker speed in m/sec
#   Returns 1 of there is an active walker and 0 otherwise.
var side_step = func (speed) {
    var cv = view.current.getPath();
    if (contains(walkers, cv)) {
        walkers[cv].side_step(speed);
        return 1;
    } else {
        return 0;
    }
}

# Get the currently active walker.
#   Returns the active walker object or nil otherwise.
var active_walker = func {
    var cv = view.current.getPath();
    if (contains(walkers, cv)) {
        return walkers[cv];
    } else {
        return nil;
    }
}

###############################################################################
# The walker class.
# ==============================================================================
# Class for a moving view.
#
# CONSTRUCTOR:
#       walker.new(<view name>, <constraints>, <managers>);
#
#         view name    ... The name of the view     : string
#         constraints  ... The movement constraints : constraint hash
#                          Determines where the view can go.
#         managers     ... Optional list of custom managers. A manager is a
#                          a hash that contains an update function of the type
#                          func(walker instance). The update function
#                          of each manager will be called as the last part of
#                          each walker update. Intended for controlling a
#                          a 3d model or similar.
#
# METHODS:
#       active() : bool
#         returns true if this walk view is active.
#
#       forward(speed)
#           Sets the forward speed of this walk view.
#         speed  ... speed in m/sec : double
#
#       side_step(speed)
#           Sets the side step speed of this walk view.
#         speed  ... speed in m/sec : double
#
#       set_pos(pos)
#       get_pos() : position
#
#       set_eye_height(h)
#       get_eye_height() : int (meter)
#
#       set_constraints(constraints)
#       get_constraints() : constraint hash
#
# EXAMPLE:
#       var constraint =
#           walkview.slopingYAlignedPlane.new([19.1, -0.3, -8.85],
#                                             [19.5,  0.3, -8.85]);
#       var walker = walkview.walker.new("Passenger View", constraint);
#
# NOTES:
#       Currently there can only be one view manager per view so the
#       walk view should not have any other view manager.
#       See Aircraft/Nordstern, Aircraft/Short_Empire or Aircraft/ZLT-NT
#       for working examples of walk views.
var walker = {
    new : func (view_name, constraints = nil, managers = nil) {
        var obj = { parents : [walker] };
        obj.view        = view.views[view.indexof(view_name)];
        obj.constraints = constraints;
        obj.managers    = managers;
        obj.position    = [
            obj.view.getNode("config/z-offset-m").getValue(),
            obj.view.getNode("config/x-offset-m").getValue(),
            obj.view.getNode("config/y-offset-m").getValue()
            ];
        obj.heading =
            obj.view.getNode("config/heading-offset-deg").getValue();
        obj.speed_fwd  = 0.0;
        obj.speed_side = 0.0;
        obj.isactive = 0;
        obj.eye_height  = 1.60;
        obj.goal_height = obj.position[2] + obj.eye_height;

        # Register this walker.
        view.manager.register(view_name, obj);
        walkers[obj.view.getPath()] = obj;

        #debug.dump(obj);
        return obj;
    },
    active : func {
        return me.isactive;
    },
    forward : func (speed) {
        me.speed_fwd = speed;
    },
    side_step : func (speed) {
        me.speed_side = speed;
    },
    set_pos : func (pos) {
        me.position[0] = pos[0];
        me.position[1] = pos[1];
        me.position[2] = pos[2];
    },
    get_pos : func {
        return [me.position[0], me.position[1], me.position[2]];
    },
    set_eye_height : func (h) {
        me.eye_height = h;
    },
    get_eye_height : func {
        return me.eye_height;
    },
    set_constraints : func (constraints) {
        me.constraints = constraints;
    },
    get_constraints : func {
        return me.constraints;
    },
    # View handler implementation.
    init : func {
    },
    start  : func {
        me.isactive = 1;
        me.last_time = getprop("/sim/time/elapsed-sec") - 0.0001;
        me.update();
        me.position[2] = me.goal_height;
    },
    stop   : func {
        me.isactive = 0;
    },
    # The update function is called by the view manager when the view is active.
    update : func {
        var t  = getprop("/sim/time/elapsed-sec");
        var dt = t - me.last_time;
        if (dt == 0.0) return;

        var cur = props.globals.getNode("/sim/current-view");
        me.heading = cur.getNode("heading-offset-deg").getValue();

        me.position[0] -=
            me.speed_fwd  * dt * math.cos(me.heading * TO_RAD) +
            me.speed_side * dt * math.sin(me.heading * TO_RAD);
        me.position[1] -=
            me.speed_fwd  * dt * math.sin(me.heading * TO_RAD) -
            me.speed_side * dt * math.cos(me.heading * TO_RAD);

        var cur_height = me.position[2];
        if (me.constraints != nil) {
            me.position     = me.constraints.constrain(me.position);
            me.goal_height  = me.position[2] + me.eye_height;
        }
        # Change the view height smoothly
        if (math.abs(me.goal_height - cur_height) > 2.0 * dt) {
            me.position[2] =
                cur_height +
                2.0 * dt *
                ((me.goal_height > cur_height) ? 1 : -1);
        } else {
            me.position[2] = me.goal_height;
        }

        cur.getNode("z-offset-m").setValue(me.position[0]);
        cur.getNode("x-offset-m").setValue(me.position[1]);
        cur.getNode("y-offset-m").setValue(me.position[2]);

        if (me.managers != nil) {
            foreach(var m; me.managers) {
                m.update(me);
            }
        }

        me.last_time = t;
        return 0.0;
    },
};

###############################################################################
# Constraint classes. Determines where the view can walk.
#


# The union of two constraints.
#   c1, c2 - the constraints : constraint
# NOTE: Assumes that the constraints are convex.
var unionConstraint = {
    new : func (c1, c2) {
        var obj = { parents : [unionConstraint] };
        obj.c1 = c1;
        obj.c2 = c2;
        return obj;
    },
    constrain : func (pos) {
        var p1 = me.c1.constrain(pos);
        var p2 = me.c2.constrain(pos);
        if (p1[0] == pos[0] and p1[1] == pos[1]) {
            return p1;
        } elsif (p2[0] == pos[0] and p2[1] == pos[1]) {
            return p2;
        } else {
            if (closerXY(pos, p1, p2) <= 0) {
                return p1;
            } else {
                return p2;
            }
        }
    }
};

# Build a unionConstraint hierarchy from a list of constraints.
#   cs - list of constraints : [constraint]
var makeUnionConstraint = func (cs) {
    if (size(cs) < 2) return cs[0];
    
    var ret = cs[0];
    for (var i = 1; i < size(cs); i += 1) {
        ret = unionConstraint.new(ret, cs[i]);
    }
    return ret;
}

# Mostly aligned plane sloping along the X axis.
#   minp - the X,Y minimum point : position (meter)
#   maxp - the X,Y maximum point : position (meter)
var slopingYAlignedPlane = {
    new : func (minp, maxp) {
        var obj = { parents : [slopingYAlignedPlane] };
        obj.minp = minp;
        obj.maxp = maxp;
        obj.kxz  = (maxp[2] - minp[2])/(maxp[0] - minp[0]);
        return obj;
    },
    constrain : func (pos) {
        var p = [pos[0], pos[1], pos[2]];
        if (pos[0] < me.minp[0]) p[0] = me.minp[0];
        if (pos[0] > me.maxp[0]) p[0] = me.maxp[0];
        if (pos[1] < me.minp[1]) p[1] = me.minp[1];
        if (pos[1] > me.maxp[1]) p[1] = me.maxp[1];
        p[2] = me.minp[2] + me.kxz * (pos[0] - me.minp[0]);
        return p;
    },
};

# Action constraint
#   Triggers an action when entering or exiting the constraint.
#   constraint      - the area in question : constraint
#   on_enter()      - function that is called when the walker enters the area.
#   on_exit(x, y)   - function that is called when the walker leaves the area.
#                     x and y are <0, 0 or >0 depending on in which direction(s)
#                     the walker left the constraint.
var actionConstraint = {
    new : func (constraint, on_enter = nil, on_exit = nil) {
        var obj = { parents : [actionConstraint] };
        obj.constraint = constraint;
        obj.on_enter   = on_enter;
        obj.on_exit    = on_exit;
        obj.inside     = 0;
        return obj;
    },
    constrain : func (pos) {
        var p = me.constraint.constrain(pos);
        if (p[0] == pos[0] and p[1] == pos[1]) {
            if (!me.inside) {
                me.inside = 1;
                if (me.on_enter != nil) {
                    me.on_enter();
                }
            }
        } else {
            if (me.inside) {
                me.inside -= 1;
                if (!me.inside and me.on_exit != nil) {
                    me.on_exit(pos[0] - p[0], pos[1] - p[1]);
                }
            }
        }
        return p;
    }
};

###############################################################################
# Manager classes.

# JSBSim pointmass manager.
#   Moves a pointmass representing the crew member together with the view.
# CONSTRUCTOR:
#       JSBSimPointmass.new(<pointmass index>);
#
#         pointmass index ... The index of the pointmass : int
#         offsets         ... [x, y ,z] position in meter of the origin of the
#                             JSBSim structural frame in the 3d model frame. 
#
# NOTE: Only supports aligned frames (yet).
#
var JSBSimPointmass = {
    new : func (index, offsets = nil) {
        var base = props.globals.getNode("fdm/jsbsim/inertia");
        var prefix  = "pointmass-location-";
        var postfix = "-inches[" ~ index ~"]";
        var obj = { parents : [JSBSimPointmass] };
        obj.pos_ft =
            [
             base.getNode(prefix ~ "X" ~ postfix),
             base.getNode(prefix ~ "Y" ~ postfix),
             base.getNode(prefix ~ "Z" ~ postfix)
            ];
        obj.offset = (offsets == nil) ? [0.0, 0.0, 0.0] : offsets;
        return obj;
    },
    update : func (walker) {
        var pos = walker.get_pos();
        pos[2] += walker.get_eye_height()/2;
        forindex (var i; pos) {
            me.pos_ft[i].setValue((pos[i] - me.offset[i])*M2FT*12);
        }
    }
};

###############################################################################
# Module implementation below

var TO_RAD = math.pi/180;
var TO_DEG = 180/math.pi;

var walkers = {};

var closerXY = func (pos, p1, p2) {
    var l1 = [p1[0] - pos[0], p1[1] - pos[1]];
    var l2 = [p2[0] - pos[0], p2[1] - pos[1]];
    return (l1[0]*l1[0] + l1[1]*l1[1]) - (l2[0]*l2[0] + l2[1]*l2[1]);
}
