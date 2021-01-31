package de.c3ma.ollo.mockup;

import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.Varargs;
import org.luaj.vm2.lib.OneArgFunction;
import org.luaj.vm2.lib.TwoArgFunction;
import org.luaj.vm2.lib.VarArgFunction;

import de.c3ma.ollo.LuaThreadTmr;

/**
 * created at 29.12.2017 - 00:07:22<br />
 * creator: ollo<br />
 * project: WS2812Emulation<br />
 * $Id: $<br />
 * @author ollo<br />
 */
public class ESP8266Tmr extends TwoArgFunction {

    private static final int MAXTHREADS = 7;
    
    private static LuaThreadTmr[] allThreads = new LuaThreadTmr[MAXTHREADS];

    public static int gTimingFactor = 1;
    
    @Override
    public LuaValue call(LuaValue modname, LuaValue env) {
        env.checkglobals();
        final LuaTable tmr = new LuaTable();
        tmr.set("stop", new stop());
        tmr.set("alarm", new alarm());
        env.set("tmr", tmr);
        env.get("package").get("loaded").set("tmr", tmr);
        
        /* initialize the Threads */
        for (Thread t : allThreads) {
            t = null;
        }
        
        return tmr;
    }

    private boolean stopTmr(int i) {
        if (allThreads[i] != null) {
            allThreads[i].stopThread();
            allThreads[i] = null;
            return true;
        } else {
            return false;
        }
    }
    
    private class stop extends OneArgFunction {

        @Override
        public LuaValue call(LuaValue arg) {
            final int timerNumer = arg.toint();
            System.out.println("[TMR] Timer" + timerNumer + " stopped");
            return LuaValue.valueOf(stopTmr(timerNumer));
        }
        
    }
    
    private class alarm extends VarArgFunction {
        public Varargs invoke(Varargs varargs) {
            if (varargs.narg()== 4) {
                final int timerNumer = varargs.arg(1).toint();
                final byte endlessloop = varargs.arg(3).tobyte();
                final int delay = varargs.arg(2).toint();
                final LuaValue code = varargs.arg(4);
                System.out.println("[TMR] Timer" + timerNumer );
                
                if ((timerNumer < 0) || (timerNumer > timerNumer)) {
                    return LuaValue.error("[TMR] Timer" + timerNumer + " is not available, choose 0 to 6");
                }
                
                if (stopTmr(timerNumer)) {
                    System.err.println("[TMR] Timer" + timerNumer + " stopped");
                }
                
                /* The cycletime is at least 1 ms */
                allThreads[timerNumer] = new LuaThreadTmr(timerNumer, code, (endlessloop == 1), Math.max(delay / gTimingFactor, 1));
                allThreads[timerNumer].start();
            }
            return LuaValue.valueOf(true);
        }
    }
    
    public void stopAllTimer() {
        for (int i = 0; i < allThreads.length; i++) {
            stopTmr(i);
        }
    }
}
