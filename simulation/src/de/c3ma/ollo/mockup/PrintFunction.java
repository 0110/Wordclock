package de.c3ma.ollo.mockup;

import java.io.File;

import org.luaj.vm2.Globals;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.OneArgFunction;

/**
 * 
 * @author ollo
 *
 */
public class PrintFunction extends OneArgFunction {
    
    private Printable mPrinter;

    public void setPrinter(Printable printer) {
        this.mPrinter = printer;
    }
    
    @Override
    public LuaValue call(LuaValue message) {
        String msg = message.checkjstring();
        if (mPrinter != null) {
        	mPrinter.printConsole(msg);
        	return LuaValue.valueOf(true);
        } else {
        	return LuaValue.valueOf(false);
        }
    }
}
