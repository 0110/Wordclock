package de.c3ma.ollo.mockup;

import java.util.UUID;

import org.eclipse.paho.client.mqttv3.IMqttClient;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;
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
	
	private IMqttClient mMqttClient = null;

	@Override
	public LuaValue call(LuaValue modname, LuaValue env) {
        env.checkglobals();
        final LuaTable mqtt = new LuaTable();
        mqtt.set("Client", new LuaMqttClient());
        env.set("mqtt", mqtt);
        env.get("package").get("loaded").set("tmr", mqtt);
        System.out.println("[MQTT] Modlue loaded");
        return mqtt;
    }

	private class LuaMqttClient extends VarArgFunction {
        public LuaValue invoke(Varargs varargs) {
            final LuaTable dynMqtt = new LuaTable();
        	if (varargs.narg() == 2) {
                final String client = varargs.arg(1).toString().toString();
                final int timeout = varargs.arg(2).toint();
	            dynMqtt.set("on", new OnMqtt(client, timeout));
	            dynMqtt.set("publish", new PublishMqtt());
	            dynMqtt.set("subscribe", new SubscribeMqtt());
	            dynMqtt.set("connect", new ConnectMqtt());
	            System.out.println("[MQTT] New client: " + client + "(" + timeout+ "s)");
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
            
        	if (varargs.narg() == 3) {
        		final LuaTable table = varargs.arg(1).checktable();
        		final String callback = varargs.arg(2).toString().toString();
        		final LuaValue code = varargs.arg(3);
        		System.out.println("[MQTT] On " + this.client + " " + callback);        		
        		onMqtt.set("function", code);
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
	
private class ConnectMqtt extends VarArgFunction {
		
        public LuaValue invoke(Varargs varargs) {
            final LuaTable onMqtt = new LuaTable();
        	if ((varargs.narg() == 6) && (mMqttClient == null)) {
        		final LuaTable table = varargs.arg(1).checktable();
        		final String targetIP = varargs.arg(2).toString().toString();
        		final int portnumber = varargs.arg(3).toint();
        		final boolean secureTLS = varargs.arg(4).toboolean();
        		final LuaValue codeOnConnected = varargs.arg(5);
        		final LuaValue codeOnFailed = varargs.arg(6);
        		String publisherId = "LuaSim" + UUID.randomUUID().toString();
        		try {
					mMqttClient = new MqttClient("tcp://" + targetIP + ":" + portnumber,publisherId);
	        		MqttConnectOptions options = new MqttConnectOptions();
	        		options.setAutomaticReconnect(false);
	        		options.setCleanSession(true);
	        		options.setConnectionTimeout(10);
	        		mMqttClient.connect(options);
	        		System.out.println("[MQTT] connected to " + targetIP + ":" + portnumber);
	        		codeOnConnected.call();
				} catch (MqttException e) {
					System.err.println("[MQTT] connect failed : " + e.getMessage());
					codeOnFailed.call();
				}
        	} else if (mMqttClient != null) {
        		System.err.println("[MQTT] client already exists : " + mMqttClient);
        		return LuaValue.NIL;
        	} else {
        		for(int i=0; i <= varargs.narg(); i++) {
					System.err.println("[MQTT] connect ["+(i) + "] (" + varargs.arg(i).typename() + ") " + varargs.arg(i).toString() );
				}
        		return LuaValue.NIL;
        	}
        	return onMqtt;
        }
	}
}
