package de.c3ma.ollo.mockup;

import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.Varargs;
import org.luaj.vm2.lib.TwoArgFunction;
import org.luaj.vm2.lib.VarArgFunction;

/**
 * 
 * @author ollo
 *
 */
public class ESP8266Mqtt extends TwoArgFunction {

	@Override
	public LuaValue call(LuaValue modname, LuaValue env) {
        env.checkglobals();
        final LuaTable mqtt = new LuaTable();
        mqtt.set("Client", new MqttClient());
        env.set("mqtt", mqtt);
        env.get("package").get("loaded").set("tmr", mqtt);
               
        return mqtt;
    }

	private class MqttClient extends VarArgFunction {
        public LuaValue invoke(Varargs varargs) {
            final LuaTable dynMqtt = new LuaTable();
        	if (varargs.narg() == 2) {
                final String client = varargs.arg(2).toString().toString();
                final int timeout = varargs.arg(3).toint();
	            dynMqtt.set("on", new OnMqtt(client, timeout));
	            dynMqtt.set("publish", new PublishMqtt());
	            dynMqtt.set("subscribe", new SubscribeMqtt());
	            System.out.println("[MQTT] New " + client + " client");
        	}
            return dynMqtt;
        }
    }
	
	private class OnMqtt extends VarArgFunction {
		
		private String client=null;
		private int timeout = 0;
		
		private OnMqtt(String client, int timeout) {
			this.client = client;
			this.timeout = timeout;
		}
		
        public LuaValue invoke(Varargs varargs) {
            final LuaTable onMqtt = new LuaTable();
        	if (varargs.narg() == 2) {
        		System.out.println("[MQTT] On " + this.client);
        	} else {
        		for(int i=0; i <= varargs.narg(); i++) {
					System.err.println("[MQTT] On ["+(i) + "] (" + varargs.arg(i).typename() + ") " + varargs.arg(i).toString() );
				}
        		return LuaValue.NIL;
        	}
        	return onMqtt;
        }
	}
	
	private class PublishMqtt extends VarArgFunction {
				
        public LuaValue invoke(Varargs varargs) {
            final LuaTable onMqtt = new LuaTable();
        	if (varargs.narg() == 2) {
        		System.out.println("[MQTT] publish ");
        	} else {
        		for(int i=0; i <= varargs.narg(); i++) {
					System.err.println("[MQTT] publish ["+(i) + "] (" + varargs.arg(i).typename() + ") " + varargs.arg(i).toString() );
				}
        		return LuaValue.NIL;
        	}
        	return onMqtt;
        }
	}
	
	private class SubscribeMqtt extends VarArgFunction {
		
        public LuaValue invoke(Varargs varargs) {
            final LuaTable onMqtt = new LuaTable();
        	if (varargs.narg() == 2) {
        		System.out.println("[MQTT] subscribe ");
        	} else {
        		for(int i=0; i <= varargs.narg(); i++) {
					System.err.println("[MQTT] subscribe ["+(i) + "] (" + varargs.arg(i).typename() + ") " + varargs.arg(i).toString() );
				}
        		return LuaValue.NIL;
        	}
        	return onMqtt;
        }
	}
}
