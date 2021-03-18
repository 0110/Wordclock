package de.c3ma.ollo.mockup;

import java.util.HashMap;

import javax.swing.SwingUtilities;

import org.luaj.vm2.LuaString;
import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.Varargs;
import org.luaj.vm2.lib.OneArgFunction;
import org.luaj.vm2.lib.TwoArgFunction;
import org.luaj.vm2.lib.VarArgFunction;

/**
 * created at 18.03.2021 - 21:09:03<br />
 * creator: ollo<br />
 * project: Esp8266 GPIO Emulation<br />
 * $Id: $<br />
 * @author ollo<br />
 */
public class ESP8266Gpio extends TwoArgFunction {

    private static final String DIRECTION_INPUT = "input";
	private HashMap<Integer, Integer> mInputs = new HashMap<Integer, Integer>();

	@Override
    public LuaValue call(LuaValue modname, LuaValue env) {
        env.checkglobals();
        final LuaTable gpio = new LuaTable();
        gpio.set("mode", new Mode(this));
        gpio.set("read", new Read(this));
        gpio.set("INPUT", DIRECTION_INPUT);
        env.set("gpio", gpio);
        env.get("package").get("loaded").set("gpio", gpio);
        return gpio;
    }

    private class Mode extends VarArgFunction {
    	
    	private ESP8266Gpio gpio;

		public Mode(ESP8266Gpio a) {
    		this.gpio = a;
    	}
    	
        public Varargs invoke(Varargs varargs) {
        	if (varargs.narg() == 2) {
        		final int pin = varargs.arg(1).toint();
        		final LuaString lsDirection = varargs.arg(2).checkstring();
        		String direction = lsDirection.toString();
        		if (direction.equals(DIRECTION_INPUT)) {
        			gpio.mInputs.put(pin, -1);
        		}
        		System.out.println("[GPIO] PIN" + pin +" as " + direction);
        		return LuaValue.valueOf(true);
        	} else {
        		return LuaValue.NIL;
        	}
        }
    }
    
    private class Read extends OneArgFunction {
    	
    	private ESP8266Gpio gpio;
    	
    	public Read(ESP8266Gpio a) {
    		this.gpio = a;
    	}

		@Override
		public LuaValue call(LuaValue arg) {
			int pin = arg.toint();
			if (mInputs.containsKey(pin)) {
				return LuaValue.valueOf(mInputs.get(pin));
			} else {
				System.out.println("[GPIO] pin" + pin + " not defined (gpio.mode missing)");
				return LuaValue.NIL;
			}
		}
	}
    
    public void setPin(int pin, int newValue) {
    	if (mInputs.containsKey(pin)) {
    		mInputs.put(pin, newValue);
    	} else {
    		System.out.println("[GPIO] PIN" + pin +" not defined (missing gpio.mode)");
    	}
    }
}
