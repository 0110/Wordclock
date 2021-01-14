package de.c3ma.ollo.mockup;

import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.Varargs;
import org.luaj.vm2.lib.TwoArgFunction;
import org.luaj.vm2.lib.VarArgFunction;

/**
 * created at 24.04.2019 - 21:12:03<br />
 * creator: ollo<br />
 * project: WS2812Emulation<br />
 * $Id: $<br />
 * @author ollo<br />
 */
public class ESP8266Adc extends TwoArgFunction {

    private int mAdc = 0;

	@Override
    public LuaValue call(LuaValue modname, LuaValue env) {
        env.checkglobals();
        final LuaTable adc = new LuaTable();
        adc.set("read", new Read(this));
        env.set("adc", adc);
        env.get("package").get("loaded").set("adc", adc);
        return adc;
    }

    private class Read extends VarArgFunction {
    	
    	private ESP8266Adc adc;

		public Read(ESP8266Adc a) {
    		this.adc = a;
    	}
    	
        public Varargs invoke(Varargs varargs) {
            return LuaValue.valueOf(this.adc.mAdc);
        }
    }
    
    public void setADC(int newValue) {
    	this.mAdc = newValue;
    	System.out.println("[ADC] updated to " + this.mAdc); 
    }
}
