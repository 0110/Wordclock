package de.c3ma.ollo.mockup;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.OneArgFunction;
import org.luaj.vm2.lib.TwoArgFunction;
import org.luaj.vm2.lib.ZeroArgFunction;

import de.c3ma.ollo.LuaSimulation;

/**
 * created at 29.12.2017 - 01:29:40<br />
 * creator: ollo<br />
 * project: WifiEmulation<br />
 * $Id: $<br />
 * @author ollo<br />
 */
public class ESP8266Wifi extends TwoArgFunction {

    @Override
    public LuaValue call(LuaValue modname, LuaValue env) {
        env.checkglobals();
        final LuaTable wifi = new LuaTable();
        wifi.set("setmode", new SetModeFunction());
        final LuaTable ap = new LuaTable();
        ap.set("config", new ConfigFunction());
        wifi.set("ap", ap);
        final LuaTable sta = new LuaTable();
        sta.set("status", new StatusFunction());
        sta.set("getip", new GetIpFunction());
        wifi.set("sta", sta);
        wifi.set("SOFTAP", "SOFTAP");
        wifi.set("STATION", "STATION");
        env.set("wifi", wifi);
        env.get("package").get("loaded").set("wifi", wifi);        
        return wifi;
    }

    private class SetModeFunction extends OneArgFunction {

        @Override
        public LuaValue call(LuaValue apmode) {
            final String APmodeString = apmode.checkjstring();
            System.out.println("[Wifi] set mode " + APmodeString);
            return LuaValue.valueOf(true);
        }
        
    }
    
    private class ConfigFunction extends OneArgFunction {

        @Override
        public LuaValue call(LuaValue arg) {
            System.out.println("[Wifi] config");
            return LuaValue.valueOf(true);
        }
        
    }
    
    private class StatusFunction extends ZeroArgFunction {

        @Override
        public LuaValue call() {
            return LuaValue.valueOf(5);
        }
        
    }
    
    private class GetIpFunction extends ZeroArgFunction {

        @Override
        public LuaValue call() {
            return LuaValue.valueOf("127.0.0.1");
        }
        
    }
}
