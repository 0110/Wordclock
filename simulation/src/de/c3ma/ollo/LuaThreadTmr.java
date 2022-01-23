package de.c3ma.ollo;

import org.luaj.vm2.LuaError;
import org.luaj.vm2.LuaValue;

/**
 * created at 29.12.2017 - 18:48:27<br />
 * creator: ollo<br />
 * project: WS2812Emulation<br />
 * $Id: $<br />
 * @author ollo<br />
 */
public class LuaThreadTmr extends Thread {
    
	private final int NO_TIMER = -2342;
    
    private boolean running = true;
    
    private boolean stopped = false;

    private LuaValue code;

    private int delay;

    private final int timerNumber;
    
    private LuaValue[] arguments;
    
    public LuaThreadTmr(int timerNumber, LuaValue code, boolean endlessloop, int delay) {
        this.code = code;
        this.running = endlessloop;
        this.delay = delay;
        this.timerNumber = timerNumber;
    }
    
    public LuaThreadTmr(LuaValue code, LuaValue arg1, LuaValue arg2, LuaValue arg3) {
    	this.code = code;
        this.running = false;
        this.delay = 1;
        this.timerNumber = NO_TIMER;
        arguments = new LuaValue[3];
        arguments[0] = arg1;
        arguments[1] = arg2;
        arguments[2] = arg3;
    }
    
    @Override
    public void run() {
        try {
            do {
                Thread.sleep(delay);
                if (code != null) {
                	if (arguments == null) {
                		code.call();
                	} else {
                		switch (arguments.length) {
                		case 1:
                			code.call(arguments[0]);
                			break;
                		case 2:
                			code.call(arguments[0], arguments[1]);
                			break;
                		case 3:
                    		code.call(arguments[0], arguments[1], arguments[2]);
                			break;
                		}
                	}
                }
            } while(running);
        } catch (LuaError le) {
        	System.err.println("[TMR] Timer" + timerNumber + " interrupted, due:" + le.getMessage());
        } catch(InterruptedException ie) {
            System.err.println("[TMR] Timer" + timerNumber + " interrupted");
        }
        stopped = true;
    }
    
    public boolean isStopped() { return stopped; }
    
    public void stopThread() {
        running = false;
        code = null;
    }

}
