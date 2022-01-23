package de.c3ma.ollo.mockup;

import java.util.UUID;

import org.eclipse.paho.client.mqttv3.IMqttClient;
import org.eclipse.paho.client.mqttv3.IMqttMessageListener;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.MqttPersistenceException;
import org.eclipse.paho.client.mqttv3.MqttSecurityException;
import org.luaj.vm2.LuaString;
import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.Varargs;
import org.luaj.vm2.lib.TwoArgFunction;
import org.luaj.vm2.lib.VarArgFunction;

import de.c3ma.ollo.LuaThreadTmr;

/**
 * 
 * @author ollo
 *
 */
public class ESP8266Mqtt extends TwoArgFunction implements IMqttMessageListener {
	
	private static final String ON_PREFIX = "on_";
	private static final String MESSAGE = "message";
	private IMqttClient mMqttClient = null;
    final LuaTable onMqtt = new LuaTable();

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
            
        	if (varargs.narg() == 3) {
        		final LuaTable table = varargs.arg(1).checktable();
        		final String callback = varargs.arg(2).toString().toString();
        		final LuaValue code = varargs.arg(3);
        		System.out.println("[MQTT] on_" + callback + " " + this.client);        		
        		onMqtt.set(ON_PREFIX + callback, code);
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
        	if (varargs.narg() == 5) {
        		final String topic = varargs.arg(2).toString().toString();
        		final String message = varargs.arg(3).toString().toString();
        		final String qos = varargs.arg(4).toString().toString();
        		final String retain = varargs.arg(4).toString().toString();
        		if ( !mMqttClient.isConnected()) {
        			return LuaValue.NIL;
                }           
                MqttMessage msg = new MqttMessage(message.getBytes());
                if (qos.equals("0")) {
                	msg.setQos(0);
                }
                
                msg.setRetained(!retain.contentEquals("0"));
                try {
					mMqttClient.publish(topic,msg);
	        		System.out.println("[MQTT] publish " + topic);
				} catch (MqttPersistenceException e) {
					System.err.println("[MQTT] publish " + topic + " failed : " + e.getMessage());
				} catch (MqttException e) {
					System.err.println("[MQTT] publish " + topic + " failed : " + e.getMessage());
				}      
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
            final LuaTable subMqtt = new LuaTable();
            final int numberArg = varargs.narg();
        	if (numberArg  == 3) {
        		final String topic = varargs.arg(2).toString().toString();
        		final int qos = varargs.arg(3).tonumber().toint();

    			try {
    				if (mMqttClient != null) {
						mMqttClient.subscribe(topic, ESP8266Mqtt.this);
	            		System.out.println("[MQTT] subscribe " + topic + " (QoS " + qos + ")");
            		} else {
            			throw new Exception("Client not instantiated");
            		}
				} catch (MqttSecurityException e) {
					System.err.println("[MQTT] subscribe " + topic + " (QoS " + qos + ") failed: " + e.getMessage());
					e.printStackTrace();
				} catch (MqttException e) {
					System.err.println("[MQTT] subscribe " + topic + " (QoS " + qos + ") failed: " + e.getMessage());
					e.printStackTrace();
				} catch (Exception e) {
        			System.err.println("[MQTT] subscribe " + topic + " (QoS " + qos + ") failed: " + e.getMessage());
				}
        	} else {
        		for(int i=0; i <= numberArg; i++) {
					System.err.println("[MQTT] subscribe ["+(i) + "/" + numberArg  + "] (" + varargs.arg(i).typename() + ") " + varargs.arg(i).toString() );
				}
        		return LuaValue.NIL;
        	}
        	return subMqtt;
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

	@Override
	public void messageArrived(String topic, MqttMessage message) throws Exception {
		LuaValue messageCallback = onMqtt.get(ON_PREFIX + MESSAGE);
		if (messageCallback != null) {
			LuaThreadTmr exec = new LuaThreadTmr(messageCallback, LuaValue.NIL, LuaValue.valueOf(topic), LuaValue.valueOf(message.getPayload()));
			exec.start();
			System.out.println("[MQTT] message "+ topic + " : " + message + " received");
			//FIXME call the LUA code
		} else {
			System.err.println("[MQTT] message "+ topic + " : " + message + " without callback");
		}
	}
}
