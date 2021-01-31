package de.c3ma.ollo.mockup;

import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.Varargs;
import org.luaj.vm2.lib.TwoArgFunction;
import org.luaj.vm2.lib.VarArgFunction;

/**
 * created at 28.12.2017 - 23:05:05<br />
 * creator: ollo<br />
 * project: WS2812Emulation<br />
 * $Id: $<br />
 * @author ollo<br />
 */
public class ESP8266Uart extends TwoArgFunction {

    @Override
    public LuaValue call(LuaValue modname, LuaValue env) {
        env.checkglobals();
        final LuaTable uart = new LuaTable();
        uart.set("setup", new setup());
        env.set("uart", uart);
        env.get("package").get("loaded").set("uart", uart);
        return uart;
    }

    private class setup extends VarArgFunction {
        public Varargs invoke(Varargs varargs) {
            if (varargs.narg()== 6) {
                System.out.println("[UART] " + varargs.arg(2) + " " + varargs.arg(3) 
                + ((varargs.arg(4).checkint() > 0) ? "Y" : "N") 
                + varargs.arg(5));
            }
            return LuaValue.valueOf(true);
        }
    }
}
