package de.c3ma.ollo.mockup;

import org.luaj.vm2.LuaFunction;
import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.ThreeArgFunction;
import org.luaj.vm2.lib.TwoArgFunction;
import org.luaj.vm2.lib.ZeroArgFunction;

/**
 * created at 29.12.2017 - 00:07:22<br />
 * creator: ollo<br />
 * project: Time Emulation<br />
 * 
 * Simulating the following modules:
 * Sntp
 * rtctime
 * 
 * $Id: $<br />
 * @author ollo<br />
 */
public class ESP8266Time extends TwoArgFunction {
    
    private static long gSimulationStartTime = 0;
    
    private static long gOverwrittenTime = 0;
    
    @Override
    public LuaValue call(LuaValue modname, LuaValue env) {
        env.checkglobals();
        final LuaTable sntp = new LuaTable();
        sntp.set("sync", new SyncFunction());
        env.set("sntp", sntp);
        final LuaTable rtctime = new LuaTable();
        rtctime.set("get", new GetFunction());
        env.set("rtctime", rtctime);
        env.get("package").get("loaded").set("sntp", sntp);
        env.get("package").get("loaded").set("rtctime", rtctime);
                
        return sntp;
    }

    /**
     * Generate a time. If there is no speedup, it is simply the current system time.
     * Otherwise the time is speedup by the given factor
     * @return
     */
    private long generateCurrenttime() {
        if (gSimulationStartTime == 0) {
            gSimulationStartTime = System.currentTimeMillis();
        }
        
        if (gOverwrittenTime == 0) {
            /* Time simulation is disabled -> calculate something according to the speedup factor */
            long time = System.currentTimeMillis();
            if (ESP8266Tmr.gTimingFactor > 1) {
                time = gSimulationStartTime + ((time - gSimulationStartTime) * ESP8266Tmr.gTimingFactor);
            }
            return time;
        } else {
            return gOverwrittenTime;
        }
    }

    private class SyncFunction extends ThreeArgFunction {

        @Override
        public LuaValue call(LuaValue server, LuaValue callbackSuccess, LuaValue callbackFailure) {
            String serverName = server.checkjstring();
            LuaFunction cb = callbackSuccess.checkfunction();
            System.out.println("[SNTP] sync " + serverName);
            /*FIXME also make it possible to simulate the time */
            long time = generateCurrenttime();
            int seconds = (int) (time / 1000);
            int useconds = (int) (time % 1000);
            cb.call(LuaValue.valueOf(seconds), LuaValue.valueOf(useconds), LuaValue.valueOf(serverName));
            return LuaValue.valueOf(true);
        }
        
    }
    
    private class GetFunction extends ZeroArgFunction {

        @Override
        public LuaValue call() {
            LuaValue[] v = new LuaValue[2];            
            /*FIXME also make it possible to simulate the time */
            long time = generateCurrenttime();
            int seconds = (int) (time / 1000);
            int useconds = (int) (time % 1000);
            v[0] = LuaValue.valueOf(seconds);
            v[1] = LuaValue.valueOf(useconds);
            return LuaValue.varargsOf(v).arg1();
        }
        
    }

    public static void setOverwrittenTime(long timeInMillis) {
        gOverwrittenTime = timeInMillis;
    }
    
}
