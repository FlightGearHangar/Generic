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

# NOTE: Coordinates are always 3 component lists: [x, y, z].

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

###############################################################################
# The walker class.
var walker = {
    new : func (view_name, constraints = nil) {
        var obj = { parents : [walker] };
        obj.view        = view.views[view.indexof(view_name)];
        obj.constraints = constraints;
        obj.position    = [
            obj.view.getNode("config/z-offset-m").getValue(),
            obj.view.getNode("config/x-offset-m").getValue(),
            obj.view.getNode("config/y-offset-m").getValue()
            ];
        obj.heading =
            obj.view.getNode("config/heading-offset-deg").getValue();
        obj.speed    = 0.0;
        obj.id       = 0;
        obj.isactive = 0;
        obj.eye_height = 1.60;

        # Register this walker.
        view.manager.register(view_name, obj);
        walkers[obj.view.getPath()] = obj;

        debug.dump(obj);
        return obj;
    },
    active : func {
        return me.isactive;
    },
    forward : func (speed) {
        me.speed = speed;
    },
    set_pos : func (pos) {
        me.position[0] = pos[0];
        me.position[1] = pos[1];
        me.position[2] = pos[2];
    },
    get_pos : func {
        return me.position;
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
        me.last_time = getprop("/sim/time/elapsed-sec");
        me.update();
        settimer(func { me._loop_(me.id); }, 0.0);
    },
    stop   : func {
        me.isactive = 0;
        me.id += 1;
    },
    # Internals.
    update : func {
        var t  = getprop("/sim/time/elapsed-sec");
        var dt = t - me.last_time;
        if (dt == 0.0) return;

        var cur = props.globals.getNode("/sim/current-view");
        me.heading = cur.getNode("heading-offset-deg").getValue();

        me.position[0] -= me.speed * dt * math.cos(me.heading * RAD);
        me.position[1] -= me.speed * dt * math.sin(me.heading * RAD);

        if (me.constraints != nil) {
            me.position     = me.constraints.constrain(me.position);
            me.position[2] += me.eye_height;
            cur.getNode("y-offset-m").setValue(me.position[2]);
        }

        cur.getNode("z-offset-m").setValue(me.position[0]);
        cur.getNode("x-offset-m").setValue(me.position[1]);
        #cur.getNode("y-offset-m").setValue(me.position[2]);

        me.last_time = t;
    },
    _loop_ : func (id) {
        if (me.id != id) return;
        me.update();
        settimer(func { me._loop_(id); }, 0.0);
    }
};

###############################################################################
# Constraint classes.

# Assumes that the constraints are convex.
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
var makeUnionConstraint = func (cs) {
    if (size(cs) < 2) return cs[0];
    
    var ret = cs[0];
    for (var i = 1; i < size(cs); i += 1) {
        ret = unionConstraint.new(ret, cs[i]);
    }
    return ret;
}

# Mostly aligned plane sloping along the X axis.
#   minp - the X,Y minimum point
#   maxp - the X,Y maximum point
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

###############################################################################
# Module implementation below

var RAD = math.pi/180;
var DEG = 180/math.pi;

var walkers = {};

var closerXY = func (pos, p1, p2) {
    l1 = [p1[0] - pos[0], p1[1] - pos[1]];
    l2 = [p2[0] - pos[0], p2[1] - pos[1]];
    return (l1[0]*l1[0] + l1[1]*l1[1]) - (l2[0]*l2[0] + l2[1]*l2[1]);
}
