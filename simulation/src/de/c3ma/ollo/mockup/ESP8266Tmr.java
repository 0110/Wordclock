package de.c3ma.ollo.mockup;

import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.Varargs;
import org.luaj.vm2.lib.OneArgFunction;
import org.luaj.vm2.lib.TwoArgFunction;
import org.luaj.vm2.lib.VarArgFunction;
import org.luaj.vm2.lib.ZeroArgFunction;

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
    private static LuaThreadTmr[] dynamicThreads = new LuaThreadTmr[MAXTHREADS];
    private static int dynamicThreadCounter=0;

    public static int gTimingFactor = 1;
    
    @Override
    public LuaValue call(LuaValue modname, LuaValue env) {
        env.checkglobals();
        final LuaTable tmr = new LuaTable();
        tmr.set("stop", new stop());
        tmr.set("alarm", new alarm());
        tmr.set("create", new create());
        tmr.set("wdclr", new watchDog());
        tmr.set("ALARM_AUTO", "ALARM_AUTO");
        tmr.set("ALARM_SINGLE", "ALARM_SINGLE");
        env.set("tmr", tmr);
        env.get("package").get("loaded").set("tmr", tmr);
        
        /* initialize the Threads */
        for (Thread t : allThreads) {
            t = null;
        }
        for (Thread t : dynamicThreads) {
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
    
    private class dynRegister extends VarArgFunction {
    	private final int dynIndex;
    	public dynRegister(int index) {
    		this.dynIndex = index;
    	}
        public Varargs invoke(Varargs varargs) {
            if (varargs.narg() == 4) {
                final String endlessloop = varargs.arg(3).toString().toString();
                final int delay = varargs.arg(2).toint();
                final LuaValue code = varargs.arg(4);
                dynamicThreads[dynIndex] = new LuaThreadTmr(dynIndex, code, (endlessloop.contains("AUTO")), Math.max(delay / gTimingFactor, 1));
                System.out.println("[TMR] DynTimer" + dynIndex + " registered");
            }
            return LuaValue.valueOf(true);
        }
    }
    
    private class dynStart extends ZeroArgFunction {
    	private final int dynIndex;
    	public dynStart(int index) {
    		this.dynIndex = index;
    	}
        public LuaValue call() {
            if (dynamicThreads[dynIndex] != null) {
                dynamicThreads[dynIndex].start();
                System.out.println("[TMR] DynTimer" + dynIndex + " started");
                return LuaValue.valueOf(true);   
            } else {
            	return LuaValue.valueOf(false);
            }
        }
    }
    
    private class watchDog extends ZeroArgFunction {
    	
        public LuaValue call() {
            System.out.println("[TMR] Watchdog fed");
            return LuaValue.valueOf(true);   
            
        }
    }
    
    private class dynStop extends ZeroArgFunction {
    	private final int dynIndex;
    	public dynStop(int index) {
    		this.dynIndex = index;
    	}
        public LuaValue call() {
        	boolean status = false;
            if (dynamicThreads[dynIndex] != null) {
            	dynamicThreads[dynIndex].stopThread();
            	dynamicThreads[dynIndex] = null;
            	System.out.println("[TMR] DynTimer" + dynIndex + " stopped");
            	status = true;
            }
			return LuaValue.valueOf(status);
        }
    }
    
    private class create extends ZeroArgFunction {
        public LuaValue call() {                
            if (dynamicThreadCounter >= MAXTHREADS) {
                return LuaValue.error("[TMR] DynTimer" + dynamicThreadCounter + " exeeded maximum");
            }
            final LuaTable dynTimer = new LuaTable();
            dynTimer.set("register", new dynRegister(dynamicThreadCounter));
            dynTimer.set("start", new dynStart(dynamicThreadCounter));
            dynTimer.set("unregister", new dynStop(dynamicThreadCounter));
            dynamicThreadCounter++;
            return dynTimer;
        }
    }
    
    public void stopAllTimer() {
        for (int i = 0; i < allThreads.length; i++) {
            stopTmr(i);
        }
    }
}
