package de.c3ma.ollo;

import org.luaj.vm2.LuaValue;

/**
 * created at 29.12.2017 - 18:48:27<br />
 * creator: ollo<br />
 * project: WS2812Emulation<br />
 * $Id: $<br />
 * @author ollo<br />
 */
public class LuaThreadTmr extends Thread {
    
    
    private boolean running = true;
    
    private boolean stopped = false;

    private LuaValue code;

    private int delay;

    private final int timerNumber;
    
    public LuaThreadTmr(int timerNumber, LuaValue code, boolean endlessloop, int delay) {
        this.code = code;
        this.running = endlessloop;
        this.delay = delay;
        this.timerNumber = timerNumber;
    }
    
    @Override
    public void run() {
        try {
            do {
                Thread.sleep(delay);
                if (code != null) {
                    code.call();
                }
            } while(running);
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
